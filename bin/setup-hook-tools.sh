#!/bin/sh
set -eu
bash -c 'set -euo pipefail
. hooks/knowledgebase.sh
okf --version
yq --version
jq --version
check_jsonschema --version
likec4 --version
playwright install chromium-headless-shell' -- "$@"
