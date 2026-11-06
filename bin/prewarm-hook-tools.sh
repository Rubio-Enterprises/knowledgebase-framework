#!/bin/sh
set -eu
config=/etc/mise/config.toml
pin() { yq -p toml -r ".tools.\"$1\"" "$config"; }
legacy() { MISE_LOCKED=0 MISE_LOCKFILE=0 mise x "$@"; }
legacy "aqua:jqlang/jq@$(pin aqua:jqlang/jq)" -- jq --version
legacy "pipx:check-jsonschema@$(pin pipx:check-jsonschema)" -- check-jsonschema --version
legacy "node@$(pin node)" "npm:likec4@$(pin npm:likec4)" -- likec4 --version
legacy "node@$(pin node)" "npm:playwright@$(pin npm:playwright)" -- playwright --version
likec4_root="$(MISE_LOCKED=0 MISE_LOCKFILE=0 mise where "npm:likec4@$(pin npm:likec4)")"
for package in "$likec4_root"*/node_modules/.mise/likec4@*/node_modules/likec4; do
  test -d "$package/__app__"
  install -d -o vscode -g vscode "$package/node_modules/.vite"
done
