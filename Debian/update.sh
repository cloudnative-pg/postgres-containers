#!/usr/bin/env bash
#
# Copyright The CloudNativePG Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=("$@")
if [ ${#versions[@]} -eq 0 ]; then
	for version in */; do
		[[ $version = src/ ]] && continue
		versions+=("$version")
	done
fi
versions=("${versions[@]%/}")

# Get the last postgres base image tag and update time
fetch_postgres_image_version() {
	local suite="$1";
	local item="$2";
	curl -SsL "https://registry.hub.docker.com/v2/repositories/library/postgres/tags/?name=bookworm&ordering=last_updated&page_size=20" | \
	  jq -c ".results[] | select( .name | match(\"^${suite}.[a-z0-9]+-bookworm\"))" | \
	  jq -r ".${item}" | \
	  head -n1
}


# Get the latest Barman version
latest_barman_version=
_raw_get_latest_barman_version() {
	curl -s https://pypi.org/pypi/barman/json | jq -r '.releases | keys[]' | sort -Vr | head -n1
}
get_latest_barman_version() {
	if [ -z "$latest_barman_version" ]; then
		latest_barman_version=$(_raw_get_latest_barman_version)
	fi
	echo "$latest_barman_version"
}

# record_version(versionFile, component, componentVersion)
# Parameters:
#   versionFile: the file containing the version of each component
#   component: the component to be updated
#   componentVersion: the new component version to be set
record_version() {
	local versionFile="$1"; shift
	local component="$1"; shift
	local componentVersion="$1"; shift

	jq -S --arg component "${component}" \
		--arg componentVersion "${componentVersion}" \
		'.[$component] = $componentVersion' <"${versionFile}" >>"${versionFile}.new"

	mv "${versionFile}.new" "${versionFile}"
}

generate_postgres() {
	local version="$1"; shift
	versionFile="${version}/.versions.json"
	imageReleaseVersion=1

	postgresImageVersion=$(fetch_postgres_image_version "${version}" "name")
	if [ -z "$postgresImageVersion" ]; then
		echo "Unable to retrieve latest postgres ${version} image version"
		exit 1
	fi
	postgresImageLastUpdate=$(fetch_postgres_image_version "${version}" "last_updated")
	if [ -z "$postgresImageLastUpdate" ]; then
		echo "Unable to retrieve latest  postgres ${version} image version last update time"
		exit 1
	fi


	barmanVersion=$(get_latest_barman_version)
	if [ -z "$barmanVersion" ]; then
		echo "Unable to retrieve latest barman-cli-cloud version"
		exit 1
	fi

	if [ -f "${versionFile}" ]; then
		oldImageReleaseVersion=$(jq -r '.IMAGE_RELEASE_VERSION' "${versionFile}")
		oldBarmanVersion=$(jq -r '.BARMAN_VERSION' "${versionFile}")
		oldPostgresImageLastUpdate=$(jq -r '.POSTGRES_IMAGE_LAST_UPDATED' "${versionFile}")
		oldPostgresImageVersion=$(jq -r '.POSTGRES_IMAGE_VERSION' "${versionFile}")
		imageReleaseVersion=$oldImageReleaseVersion
	else
		imageReleaseVersion=1
		echo "{}" > "${versionFile}"
		record_version "${versionFile}" "IMAGE_RELEASE_VERSION" "${imageReleaseVersion}"
		record_version "${versionFile}" "BARMAN_VERSION" "${barmanVersion}"
		record_version "${versionFile}" "POSTGRES_IMAGE_LAST_UPDATED" "${postgresImageLastUpdate}"
		record_version "${versionFile}" "POSTGRES_IMAGE_VERSION" "${postgresImageVersion}"
		return
	fi

	newRelease="false"

	# Detect if postgres image updated
	if [ "$oldPostgresImageLastUpdate" != "$postgresImageLastUpdate" ]; then
		echo "Debian Image changed from $oldPostgresImageLastUpdate to $postgresImageLastUpdate"
		newRelease="true"
		record_version "${versionFile}" "POSTGRES_IMAGE_LAST_UPDATED" "${postgresImageLastUpdate}"
	fi

	# Detect an update of Barman
	if [ "$oldBarmanVersion" != "$barmanVersion" ]; then
		echo "Barman changed from $oldBarmanVersion to $barmanVersion"
		newRelease="true"
		record_version "${versionFile}" "BARMAN_VERSION" "${barmanVersion}"
	fi

	if [ "$oldPostgresImageVersion" != "$postgresImageVersion" ]; then
		echo "PostgreSQL base image changed from $oldPostgresImageVersion to $postgresImageVersion"
		record_version "${versionFile}" "IMAGE_RELEASE_VERSION" 1
		record_version "${versionFile}" "POSTGRES_IMAGE_VERSION" "${postgresImageVersion}"
		imageReleaseVersion=1
	elif [ "$newRelease" = "true" ]; then
		imageReleaseVersion=$((oldImageReleaseVersion + 1))
		record_version "${versionFile}" "IMAGE_RELEASE_VERSION" $imageReleaseVersion
	fi

	dockerTemplate="Dockerfile.template"
	if [ "${version}" -gt '16' ]; then
		dockerTemplate="Dockerfile-beta.template"
	fi

	cp -r src/* "$version/"
	sed -e 's/%%POSTGRES_IMAGE_VERSION%%/'"$postgresImageVersion"'/g' \
		-e 's/%%IMAGE_RELEASE_VERSION%%/'"$imageReleaseVersion"'/g' \
		${dockerTemplate} \
		> "$version/Dockerfile"
}

update_requirements() {
	barmanVersion=$(get_latest_barman_version)
	# If there's a new version we need to recreate the requirements files
	echo "barman[cloud,azure,snappy,google] == $barmanVersion" > requirements.in

	# This will take the requirements.in file and generate a file
	# requirements.txt with the hashes for the required packages
	pip-compile --generate-hashes 2> /dev/null

	# Removes psycopg from the list of packages to install
	sed -i '/psycopg/{:a;N;/barman/!ba};/via barman/d' requirements.txt

	# Then the file needs to be moved into the src/root/ that will
	# be added to every container later
	mv requirements.txt src/
}

update_requirements
for version in "${versions[@]}"; do
	generate_postgres "${version}"
done
