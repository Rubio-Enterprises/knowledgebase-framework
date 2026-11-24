#!/usr/bin/env bash
# The Shell's Copier task. Copier runs it in the knowledgebase's folder after every `copier copy`
# and `copier update`:
#
#   setup.sh <copy|update> <scope>
#
# It fills the managed text, seeds docs/log.md, then, on copy only, puts the knowledgebase to work
# in a standards repository (ADR-0014): a root knowledgebase gets git and the standards Starter
# Files, wired for the Hooks; an embedded one gets the wiring printed for its parent repository.
set -euo pipefail

operation=$1
scope=$2
# shellcheck source=hooks/knowledgebase.sh
# shellcheck disable=SC1091 # knowledgebase.sh is linted on its own
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

# The managed text names docs/index.md, which okf writes only once a document exists.
[ -f docs/index.md ] || printf '# Index\n\nNo documents yet.\n' >docs/index.md

# Add text to a Starter File once; the marker is what a second run looks for.
append_once() { # marker file text
  grep -qF -- "$1" "$2" 2>/dev/null || printf '\n%s\n' "$3" >>"$2"
}

# The okf pin compiles from source, so the dev image needs a C toolchain before its pins install.
add_compiler() {
  if grep -q build-essential Dockerfile; then return 0; fi
  awk -v line="$(cat "$FRAMEWORK/shell/dockerfile-compiler")" \
    '{print} !done && /^USER root$/ {print line; done = 1}' Dockerfile >Dockerfile.new
  mv Dockerfile.new Dockerfile
  grep -q build-essential Dockerfile ||
    echo "Dockerfile has no 'USER root' line: install build-essential in it before the mise install." >&2
}

# The agent context contract opens AGENTS.md with a fixed title and Commands section; the
# knowledgebase's own title moves under it.
contract_agents() {
  if grep -q '^# Agent context$' AGENTS.md; then return 0; fi
  {
    cat "$FRAMEWORK/shell/agents-commands.md"
    printf '\n'
    awk '!done && /^# / {sub(/^# /, "## "); done = 1} {print}' AGENTS.md
    printf '\n'
    cat "$FRAMEWORK/shell/agents-adr.md"
  } >AGENTS.md.new
  mv AGENTS.md.new AGENTS.md
}

if [ -z "$path" ]; then
  [ -d .git ] || git init -q
  mkdir -p image
  if [ ! -f image/mise.toml ]; then
    cp "$FRAMEWORK/shell/image-pins.toml" image/mise.toml
    [ ! -d assets/likec4 ] || cat "$FRAMEWORK/shell/image-pins-likec4.toml" >>image/mise.toml
  fi
  token="${NODE_AUTH_TOKEN:-$(gh auth token 2>/dev/null || true)}"
  # The Initializer keeps files that exist, so it locks the pins above instead of replacing them.
  if ! env NODE_AUTH_TOKEN="$token" \
    "npm_config_@rubio-enterprises:registry=${STANDARDS_REGISTRY:-https://npm.pkg.github.com}" \
    "npm_config_//npm.pkg.github.com/:_authToken=$token" \
    npm init -y @rubio-enterprises/standards@latest; then
    echo "The standards Initializer failed. Fix the cause above, delete $kb and create it again." >&2
    exit 1
  fi
  append_once knowledgebase-framework.git lefthook.yml "$(cat "$FRAMEWORK/shell/lefthook.yml")"
  append_once .copier-answers.knowledgebase.yml lefthook.override.yml "$(cat "$FRAMEWORK/shell/lefthook.override.yml")"
  add_compiler
  # `just setup` installs the container hooks; this fetches the Hooks remote first.
  append_once 'lefthook install' bin/setup.sh "$(cat "$FRAMEWORK/shell/setup-hooks")"
  contract_agents
  # standard-readme wants the repository's folder name in the title.
  awk -v dir="$(basename "$kb")" 'NR == 1 && /^# / && $0 !~ dir {$0 = $0 " _(" dir ")_"} {print}' README.md >README.md.new
  mv README.md.new README.md
  grep -q '^## License$' README.md || cat "$FRAMEWORK/shell/readme-sections.md" >>README.md
  [ -f LICENSE ] || [ -f LICENSE.md ] || [ -f LICENSE.txt ] || printf 'UNLICENSED\n' >LICENSE
  if git rev-parse -q --verify HEAD >/dev/null; then
    echo "The repository already has commits: review the new files and commit them yourself."
  else
    git add -A
  fi
  cat <<EOF

The knowledgebase is a standards repository. Finish it in $kb:

    just build-dev && just setup && just check
    git add -A && git commit -m "chore: create knowledgebase"

LICENSE says UNLICENSED: replace it, and README.md's License section, if the repository is licensed.
EOF
  if [ -d assets/likec4 ]; then
    cat <<EOF
The LikeC4 add-on exports PNGs with Playwright's headless Chromium, whose system libraries the dev
image lacks. Install them in the Dockerfile, as Rubio-Enterprises/knowledge does.
EOF
  fi
  pointer="$(basename "$kb")/"
else
  cat <<EOF

This knowledgebase is inside the repository at $repo, a standards repository. Wire it in once:

1. Add these lines to $repo/lefthook.yml, merging them with any remotes: key already there, then
   run \`just setup\`.

$(sed 's/^/    /' "$FRAMEWORK/shell/lefthook.yml")

2. Add these pins to $repo/image/mise.toml and lock them:

$({
    sed -n '/^\[tools\]/,$p' "$FRAMEWORK/shell/image-pins.toml" | sed 1d
    [ ! -d assets/likec4 ] || cat "$FRAMEWORK/shell/image-pins-likec4.toml"
  } | sed 's/^/    /')

3. Add this line to its Dockerfile after \`USER root\`, then run \`just build-dev\`:

$(sed 's/^/    /' "$FRAMEWORK/shell/dockerfile-compiler")

4. Add these Exclusions to its lefthook.override.yml, writing \`$path\` before the answers file
   and \`assets/**\`:

$(sed 's/^/    /' "$FRAMEWORK/shell/lefthook.override.yml")
EOF
  pointer="$path"
fi

cat <<EOF

Agents load AGENTS.md only from their working folder and its parents. Add this line to the
AGENTS.md of the repository or workspace that contains the knowledgebase:

- Knowledgebase \`$pointer\`: $scope Read \`${pointer}AGENTS.md\` before reading or filing anything in it.
EOF
