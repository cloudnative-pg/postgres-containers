#!/usr/bin/env bash
#
# Given a list of PostgreSQL versions (defined as directories in the root
# folder of the project), this script generates a JSON object that will be used
# inside the Github workflows as a strategy to create a matrix of jobs to run.
# The JSON object contains, for each PostgreSQL version, the tags of the
# container image to be built.
#
set -eu

# Define an optional aliases for some major versions
declare -A aliases=(
	[16]='latest'
)

# Define the current default distribution
DEFAULT_DISTRO="bullseye"

GITHUB_ACTIONS=${GITHUB_ACTIONS:-false}

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}/..")")"
BASE_DIRECTORY="$(pwd)"


# Retrieve the PostgreSQL versions for Debian
cd ${BASE_DIRECTORY}/Debian
for version in */; do
	[[ $version == src/ ]] && continue
	debian_versions+=("$version")
done
debian_versions=("${debian_versions[@]%/}")

# Sort the version numbers with highest first
mapfile -t debian_versions < <(IFS=$'\n'; sort -rV <<< "${debian_versions[*]}")

# prints "$2$1$3$1...$N"
join() {
	local sep="$1"
	shift
	local out
	printf -v out "${sep//%/%%}%s" "$@"
	echo "${out#$sep}"
}

generator() {
	local os="$1"; shift
	local distro="$1"; shift

	cd "${BASE_DIRECTORY}"/"${os}"/
	for version in "${debian_versions[@]}"; do

		# Read versions from the definition file
		versionDir="${version}/${distro}"
		versionFile="${versionDir}/.versions.json"
		postgresImageVersion=$(jq -r '.POSTGRES_IMAGE_VERSION | split("-") | .[0]' "${versionFile}")
		releaseVersion=$(jq -r '.IMAGE_RELEASE_VERSION' "${versionFile}")

		# Setting distribution tags: "major version", "full version", "full version with release"
		# i.e. "14-bullseye", "14.2-bullseye", "14.2-1-bullseye"
		fullTag="${postgresImageVersion}-${releaseVersion}-${distro}"
		versionAliases=(
				"${version}-${distro}"
				"${postgresImageVersion}-${distro}"
				"${fullTag}"
			)

		# Additional aliases in case we are running in the default distro
		# i.e. "14", "14.2", "14.2-1", "latest"
		if [ "${distro}" == "${DEFAULT_DISTRO}" ]; then
			versionAliases+=(
				"$version"
				"${postgresImageVersion}"
				"${postgresImageVersion}-${releaseVersion}"
				${aliases[$version]:+"${aliases[$version]}"}
			)
		fi

		# Supported platforms for container images
		platforms="linux/amd64,linux/arm64"

		# Build the json entry
		entries+=(
			"{\"name\": \"Debian ${version} - ${distro}\", \"platforms\": \"$platforms\", \"dir\": \"$os/$versionDir\", \"file\": \"$os/$versionDir/Dockerfile\", \"distro\": \"$distro\", \"version\": \"$version\", \"tags\": [\"$(join "\", \"" "${versionAliases[@]}")\"], \"fullTag\": \"${fullTag}\"}"
		)
	done
}

entries=()

# Debian
generator "Debian" "bullseye"
generator "Debian" "bookworm"

# Build the strategy as a JSON object
strategy="{\"fail-fast\": false, \"matrix\": {\"include\": [$(join ', ' "${entries[@]}")]}}"
jq -C . <<<"$strategy" # sanity check / debugging aid

if [[ "$GITHUB_ACTIONS" == "true" ]]; then
	echo "strategy=$(jq -c . <<<"$strategy")" >> $GITHUB_OUTPUT
fi
