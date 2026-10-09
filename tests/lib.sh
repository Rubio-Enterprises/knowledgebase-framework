#!/usr/bin/env bash
# Test harness for tests/run.sh. Bash 3.2-compatible, like the Hooks it tests.
#
# Everything runs offline in a scratch folder ($T):
#   $T/framework                      a throwaway copy of the framework: its baseline release tagged
#                                     v1.0.0, then the working tree under test tagged v1.99.0, with
#                                     a v1 branch at the working tree
#   $T/remote/knowledgebase-framework.git
#                                     a bare clone that lefthook fetches the Hooks from
#   $T/gitconfig                      the only git config the tests see; its `insteadOf` sends the
#                                     Shell's real Hooks URL to the bare clone. This is the tests'
#                                     only override: the Shell itself always names the real URL.

FW="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
HOOKS_URL=https://github.com/Rubio-Enterprises/knowledgebase-framework.git
# shellcheck disable=SC2034 # used by tests/run.sh
NODE=node@24.21.0 # the node the Hooks pin, for running npm tools in tests
BASELINE_TAG=v1.0.0
NEW_TAG=v1.99.0
FAILED=0
PASSED=0

pass() {
  PASSED=$((PASSED + 1))
  printf 'ok - %s\n' "$1"
}
fail() {
  FAILED=$((FAILED + 1))
  printf 'not ok - %s\n' "$1"
  [ -z "${2:-}" ] || printf '%s\n' "$2" | sed 's/^/    # /'
}
check() { # description command... : passes when the command succeeds
  local name=$1 out
  shift
  if out="$("$@" 2>&1)"; then pass "$name"; else
    fail "$name" "$out"
    return 1
  fi
}
note() { [ -z "${KB_TEST_VERBOSE:-}" ] || printf '%s\n' "$1" | sed 's/^/    | /'; }
strip_colors() { sed $'s/\x1b\\[[0-9;]*m//g'; }

# Write a frozen copy of tree-ish $1 (or the working tree, for "WORKTREE") into folder $2.
export_tree() {
  mkdir -p "$2"
  if [ "$1" = WORKTREE ]; then
    (cd "$FW" && git ls-files -co --exclude-standard -z | xargs -0 -I{} rsync -aR {} "$2/")
  else
    git -C "$FW" archive "$1" | tar -x -C "$2"
  fi
}

# The baseline release: the newest v* tag, or before the first release, the commit that created
# the Shell.
baseline_ref() {
  git -C "$FW" describe --tags --abbrev=0 --match 'v*' 2>/dev/null ||
    git -C "$FW" log --diff-filter=A --format=%H -- copier.yml | tail -1
}

setup_world() {
  T="$(mktemp -d "${TMPDIR:-/tmp}/kb-tests.XXXXXX")"
  T="$(cd "$T" && pwd -P)"
  [ -n "${KB_TEST_KEEP:-}" ] || trap 'rm -rf "$T"' EXIT

  # Bash 3.2 first on PATH, so every script under test runs on macOS's /bin/bash.
  mkdir -p "$T/bin"
  if [ -x /bin/bash ]; then ln -s /bin/bash "$T/bin/bash"; fi
  PATH="$T/bin:$PATH"

  cat >"$T/gitconfig" <<EOF
[user]
  name = Knowledgebase Tests
  email = tests@example.com
[init]
  defaultBranch = main
[commit]
  gpgsign = false
[url "file://$T/remote/knowledgebase-framework.git"]
  insteadOf = $HOOKS_URL
EOF
  export GIT_CONFIG_GLOBAL="$T/gitconfig" GIT_CONFIG_NOSYSTEM=1
  export LEFTHOOK_COLORS=false NO_COLOR=1

  local fwrepo="$T/framework"
  export_tree "$(baseline_ref)" "$fwrepo"
  (cd "$fwrepo" && git init -q && git add -A && git commit -q -m "baseline release" && git tag "$BASELINE_TAG")
  (cd "$fwrepo" && git rm -rq . && git clean -fdxq)
  export_tree WORKTREE "$fwrepo"
  (cd "$fwrepo" && git add -A && git commit -q --allow-empty -m "release under test" && git tag "$NEW_TAG" && git branch v1)
  mkdir -p "$T/remote"
  git clone -q --bare "$fwrepo" "$T/remote/knowledgebase-framework.git"
  FRAMEWORK_REPO="$fwrepo"
}

# create <destination> [--vcs-ref <tag>] [copier --data/-d arguments...]: copier copy, its output
# without colours in $T/last-copy.log.
create() {
  local dest=$1 ref=$NEW_TAG
  shift
  if [ "${1:-}" = --vcs-ref ]; then
    ref=$2
    shift 2
  fi
  copier copy --trust --defaults --quiet --vcs-ref "$ref" \
    -d name="Fixture knowledgebase" -d scope="Fixture subjects." "$@" \
    "$FRAMEWORK_REPO" "$dest" >"$T/last-copy.log" 2>&1
  local status=$?
  strip_colors <"$T/last-copy.log" >"$T/last-copy.txt"
  cp "$T/last-copy.txt" "$T/last-copy.log"
  return "$status"
}

# The knowledgebase's own fetched copy of the Hooks script.
hooks_of() { printf '%s' "$(git -C "$1" rev-parse --path-format=absolute --git-common-dir)/info/lefthook-remotes/knowledgebase-framework-v1/hooks/knowledgebase.sh"; }

# Copy the files of fixture overlay $1 over knowledgebase $2.
overlay() { (cd "$1" && find . -type f ! -name expect | while IFS= read -r f; do
  mkdir -p "$2/$(dirname "$f")"
  cp "$f" "$2/$f"
done); }

# Every file in repository $1 that git tracks or would track, sorted.
tree_of() { git -C "$1" ls-files -co --exclude-standard | LC_ALL=C sort; }
