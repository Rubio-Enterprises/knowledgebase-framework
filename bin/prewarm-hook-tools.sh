#!/bin/sh
set -eu
# The entrypoint can remap vscode to the workspace owner (uid 1001 on a hosted runner), who writes
# the image's trees through group 1000 alone. Install like /opt/standards/image/install.sh: as
# vscode, group-writable. likec4 writes its Vite cache inside its own package at run time.
test "$(id -un)" = vscode
umask 0002
config=/etc/mise/config.toml
pin() { yq -p toml -r ".tools.\"$1\"" "$config"; }
legacy() { MISE_LOCKED=0 MISE_LOCKFILE=0 mise x "$@"; }
legacy "aqua:jqlang/jq@$(pin aqua:jqlang/jq)" -- jq --version
legacy "pipx:check-jsonschema@$(pin pipx:check-jsonschema)" -- check-jsonschema --version
legacy "node@$(pin node)" "npm:likec4@$(pin npm:likec4)" -- likec4 --version
legacy "node@$(pin node)" "npm:playwright@$(pin npm:playwright)" -- playwright --version
unwritable="$(find "${MISE_DATA_DIR:?}/installs" -type d ! -perm -g+w)"
if [ -n "$unwritable" ]; then
  printf 'Not group-writable, so a remapped dev user cannot write them:\n%s\n' "$unwritable" >&2
  exit 1
fi
