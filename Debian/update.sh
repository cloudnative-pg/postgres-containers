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

error_trap() {
  local exit_code=$?
  local line_number=$LINENO
  local script_name=$(basename "$0")
  local func_name=${FUNCNAME[1]:-MAIN}

  echo "❌ ERROR in $script_name at line $line_number"
  echo "   Function: $func_name"
  echo "   Command: '$BASH_COMMAND'"
  echo "   Exit code: $exit_code"
  exit $exit_code
}

trap error_trap ERR

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

LIBDIR="$(pwd)/../lib"
source "$LIBDIR/repo_funcs.sh"

# Defaults
DISTRO=""

usage(){
	echo "Fetch new updates of the CNPG container images."
	echo "Usage: $(basename "$0") [options]"
	echo "Options"
	echo "  -d, --distro the distro to update"
	echo "  -h, --help  display this message end exit"
}

OPTS=$(getopt \
	--long help,distro: \
	-n "$(basename "$0")" \
	-o hd: \
	-- "$@")
eval set -- "$OPTS"

while [[ $# -gt 0 ]]; do
	case "$1" in
	-h|--help)
		usage
		exit 0
		;;
	-d|--distro)
		DISTRO=$2
		if ! [[ "$DISTRO" =~ (bullseye|bookworm) ]]; then
			echo "The supported distributions are: bullseye, bookworm"
			exit 1
		fi
		shift 2
		;;
	--)
		shift
		break
		;;
	*)
		echo "Unrecognized parameter $1"
		usage
		exit 1
		;;
	esac
done

versions=("$@")
if [ ${#versions[@]} -eq 0 ]; then
	for version in */; do
		versions+=("$version")
	done
fi
versions=("${versions[@]%/}")

requirements=$(update_requirements)

case "$DISTRO" in
	bullseye|bookworm)
		for version in "${versions[@]}"; do
			generate_postgres "${version}" "${DISTRO}" "${requirements}"
		done
		;;
	*)
		for version in "${versions[@]}"; do
			generate_postgres "${version}" "bullseye" "${requirements}"
			generate_postgres "${version}" "bookworm" "${requirements}"
		done
		;;
esac
