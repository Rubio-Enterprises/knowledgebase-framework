#!/usr/bin/env bash
# The Shell's Copier task. Copier runs it in the knowledgebase's folder after every `copier copy`
# and `copier update`:
#
#   setup.sh <copy|update> <scope>
#
# It fills the managed text, seeds docs/log.md, then, on copy only, puts the knowledgebase to work:
# a root knowledgebase gets git, its lefthook.yml, the Hooks, a first check run and a first
# commit; an embedded one gets the wiring printed for its parent repository (ADR-0008).
set -euo pipefail

operation=$1
scope=$2
# shellcheck source=hooks/knowledgebase.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)/hooks/knowledgebase.sh"
kb="$(pwd -P)"

# Managed text: the managed blocks and .knowledgebase/, from this release.
step_managed .

# docs/log.md is seeded once and belongs to the knowledgebase from then on.
if [ ! -f docs/log.md ]; then
  mkdir -p docs
  printf '# Log\n\n## %s\n* **Added**: Created this knowledgebase.\n' "$(date +%Y-%m-%d)" >docs/log.md
fi

# A root knowledgebase is the whole repository, or will be once `git init` runs.
top="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$top" ] || [ "$(cd "$top" && pwd -P)" = "$kb" ]; then
  repo="$kb" path=""
else
  repo="$(cd "$top" && pwd -P)"
  path="${kb#"$repo"/}/"
fi

# VS Code reads settings only from the folder it opens, usually the repository root, so the preview
# entries go there; other settings stay as they are (ADR-0003).
add_vscode_entry() { # file key value
  local file=$1 key=$2 value=$3 merged
  mkdir -p "$(dirname "$file")"
  [ -s "$file" ] || echo '{}' >"$file"
  if ! merged="$(jq --indent 2 --arg k "$key" --arg v "$value" \
    '(.[$k] // []) as $list | if ($list | index($v)) then empty else .[$k] = $list + [$v] end' \
    "$file" 2>/dev/null)"; then
    echo "Couldn't merge into $file (comments, or not plain JSON). Add \"$value\" to \"$key\" by hand." >&2
    return 0
  fi
  [ -z "$merged" ] || printf '%s\n' "$merged" >"$file"
}
add_vscode_entry "$repo/.vscode/settings.json" markdown.styles "${path}.knowledgebase/markdown-preview.css"
add_vscode_entry "$repo/.vscode/extensions.json" recommendations bierner.markdown-footnotes

[ "$operation" = copy ] || exit 0

if [ -z "$path" ]; then
  [ -d .git ] || git init -q
  [ -f lefthook.yml ] || cp "$FRAMEWORK/shell/lefthook.yml" lefthook.yml
  lefthook install
  # The first run fetches every pinned tool, so the first commit doesn't.
  lefthook run kb-check
  if git rev-parse -q --verify HEAD >/dev/null; then
    echo "The repository already has commits: review the new files and commit them yourself."
  else
    git add -A
    git commit -q -m "chore: create knowledgebase"
    echo "Created and committed the knowledgebase."
  fi
  pointer="$(basename "$kb")/"
else
  cat <<EOF

This knowledgebase is inside the repository at $repo. Wire it into that repository once:

1. Add these lines to $repo/lefthook.yml, merging them with any remotes: and pre-commit: keys
   already there, then run \`lefthook install\`. (A repository rendered by Rubio-Enterprises
   standards declares has_knowledgebase instead.)

$(sed 's/^/    /' "$FRAMEWORK/shell/lefthook.yml")
EOF
  pointer="$path"
fi

cat <<EOF

Agents load AGENTS.md only from their working folder and its parents. Add this line to the
AGENTS.md of the repository or workspace that contains the knowledgebase:

- Knowledgebase \`$pointer\`: $scope Read \`${pointer}AGENTS.md\` before reading or filing anything in it.
EOF
