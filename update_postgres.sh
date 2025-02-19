set -Eeuo pipefail

VERSIONS=$(curl -Ss -q https://www.postgresql.org/versions.json | jq -c  '[.[] | select(.supported == true) | .major + "."+.latestMinor]')

sed -i -e 's/\(.*pgVersion = .*\)\(\[.*\]\)/\1'$VERSIONS'/' docker-bake.hcl
