#!/usr/bin/env bash
# Knowledgebase Framework Hooks: the pipeline every knowledgebase runs.
#
#   knowledgebase.sh pre-commit            the pipeline on every knowledgebase, staging what it rewrites
#   knowledgebase.sh check                 the pipeline on every knowledgebase, without staging (kb-check)
#   knowledgebase.sh diagrams              format, validate and export every LikeC4 add-on (kb-diagrams)
#   knowledgebase.sh notices               announce Shell updates the Hooks can't make (never fails)
#   knowledgebase.sh regenerate <kb>       rewrite one knowledgebase's managed text (the Shell's Copier task)
#   knowledgebase.sh step <step> <kb>      run one pipeline step on one knowledgebase (the framework's tests)
#
# Sourcing it instead defines the helpers and tool pins without running anything.
#
# A knowledgebase is any folder holding .copier-answers.knowledgebase.yml (ADR-0008). Every step
# takes the knowledgebase's folder, never assumes the repository root, and stops the pipeline when
# it fails. Runs from the repository root, on bash 3.2. Every tool is pinned below and reached
# through `mise x`, so knowledgebases carry no mise.toml (ADR-0001).
set -euo pipefail

FRAMEWORK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
ANSWERS_FILE=.copier-answers.knowledgebase.yml
# The managed block's markers, the same two lines the Shell writes into AGENTS.md and README.md.
BEGIN_MARKER="$(sed -n 1p "$FRAMEWORK/managed/markers.txt")"
END_MARKER="$(sed -n 2p "$FRAMEWORK/managed/markers.txt")"

# --- Pinned tools -------------------------------------------------------------------------------
# Pins run with mise's lockfiles off, neither required nor written. The Hooks carry no lockfile,
# mise holds every tool named on the command line to a user's `locked` setting whatever its
# `locked_scopes`, and an unlocked install rewrites every lockfile in scope, the global one too.
pinned() { MISE_LOCKED=0 MISE_LOCKFILE=0 mise x "$@"; }
# okf is built validator-only: its default `studio` feature doesn't compile on current rustc. It
# has no release binaries, so its request brings the Rust toolchain that compiles it.
RUST='rust[profile=minimal]@1.99.1'
okf() { pinned "$RUST" 'cargo:okf[default-features=false,features=validator]@0.2.7' -- okf "$@"; }
yq() { pinned aqua:mikefarah/yq@4.53.6 -- yq "$@"; }
jq() { pinned aqua:jqlang/jq@1.8.2 -- jq "$@"; }
check_jsonschema() { pinned pipx:check-jsonschema@0.37.4 -- check-jsonschema "$@"; }
# The npm tools carry their own node, so no global node is needed.
NODE=node@24.21.0
likec4() { pinned "$NODE" npm:likec4@1.59.4 -- likec4 "$@"; }
# Keep in step with the Playwright that likec4 bundles (1.60.0 for likec4 1.59.4): it installs the
# Chromium revision likec4's PNG export looks for, which likec4 never downloads itself.
playwright() { pinned "$NODE" npm:playwright@1.60.0 -- playwright "$@"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
STAGE="$WORK/stage" # paths the pipeline rewrote, staged at the end of a pre-commit run
: >"$STAGE"
MODE=check # commit, check or diagrams: set per knowledgebase by the pipeline

# --- Helpers ------------------------------------------------------------------------------------
# Path of $2 inside knowledgebase $1, written the way git prints paths ("docs/x", not "./docs/x").
at() { if [ "$1" = . ]; then printf '%s' "$2"; else printf '%s/%s' "$1" "$2"; fi; }
say() { printf 'knowledgebase %s: %s\n' "$([ "$1" = . ] && echo '(repository root)' || echo "$1")" "$2" >&2; }

# --- Unstaged changes --------------------------------------------------------------------------
# A commit takes what is staged, so in a pre-commit run the Hooks stage only their own output and
# never touch a file that holds unstaged changes. Before any step writes, each run records the files
# under the knowledgebase that differ from the index: modified, deleted or untracked.
#
# Partly staged files never show up here: before pre-commit jobs run, lefthook hides their unstaged
# hunks, and puts them back after the jobs. The Hooks may rewrite such a file, because the pre-commit
# job sets `stage_fixed`: lefthook stages the files that were staged when the run began before it
# puts the hunks back, and if a rewrite overlaps a hunk it stages nothing, restores every file and
# fails the commit. That only works while the index is what it was when lefthook saved the hunks,
# so the Hooks never stage those files themselves (see for_each_knowledgebase).
record_unstaged() {
  { git diff --name-only -- "$1" && git ls-files --others --exclude-standard -- "$1"; } | sort -u >"$WORK/unstaged"
}

# Does path $1, or anything under it, hold unstaged changes? Only a pre-commit run asks.
unstaged() {
  [ "$MODE" = commit ] || return 1
  awk -v p="$1" '$0 == p || index($0, p "/") == 1 { found = 1 } END { exit !found }' "$WORK/unstaged"
}

unstaged_error() {
  echo "$1 has unstaged changes that the Hooks would overwrite or stage. Stage or stash them, then commit again." >&2
}

# Move $1 over $2 when their contents differ, and remember $2 for staging. Refuses, leaving $2 as it
# is, when $2 holds unstaged changes.
replace_if_changed() {
  if [ -f "$2" ] && cmp -s "$1" "$2"; then
    rm -f "$1"
  elif unstaged "$2"; then
    rm -f "$1"
    unstaged_error "$2"
    return 1
  else
    cat "$1" >"$2" && rm -f "$1" && printf '%s\n' "$2" >>"$STAGE"
  fi
}

# Tools such as okf index and likec4 export rewrite files in place. Keep a copy of every file in
# list $1 that holds unstaged changes, run the tool, then put back each copy the tool changed and
# report it. Files the tool changed and that had no unstaged changes are remembered for staging.
guarded() { # list command...
  local list=$1 f n=0 status=0
  shift
  : >"$WORK/kept"
  while IFS= read -r f; do
    if unstaged "$f"; then
      n=$((n + 1))
      cp "$f" "$WORK/kept.$n" && printf '%s\t%s\n' "$n" "$f" >>"$WORK/kept"
    fi
  done <"$list"
  "$@" || status=1
  while IFS="$(printf '\t')" read -r n f; do
    if ! cmp -s "$WORK/kept.$n" "$f"; then
      cp "$WORK/kept.$n" "$f"
      unstaged_error "$f"
      status=1
    fi
  done <"$WORK/kept"
  return "$status"
}

# Every knowledgebase in the repository, one folder per line.
knowledgebases() {
  git ls-files --cached --others --exclude-standard | while IFS= read -r f; do
    case "$f" in
    "$ANSWERS_FILE") [ -f "$f" ] && echo . ;;
    */"$ANSWERS_FILE") [ -f "$f" ] && dirname "$f" ;;
    esac
  done | sort -u
}

# Staged files under folder $1 (repository-relative paths), one per line.
staged_under() {
  local prefix
  if [ "$1" = . ]; then prefix=""; else prefix="$1/"; fi
  git diff --cached --name-only --diff-filter=ACMR | while IFS= read -r f; do
    case "$f" in "$prefix"*) echo "$f" ;; esac
  done
}

# Print a command's output only when it fails, without okf's [info] chatter.
quiet() {
  local out="$WORK/out" status=0
  "$@" >"$out" 2>&1 || status=$?
  if [ "$status" -ne 0 ]; then grep -v '^\[info\]' "$out" >&2 || true; fi
  return "$status"
}

# --- Step 1: managed text (ADR-0003, ADR-0007) ----------------------------------------------------
markers_error() {
  cat >&2 <<EOF
$1: the managed block's markers are missing or broken, so the Hooks can't tell framework text
from this knowledgebase's own. Put these two lines back, each exactly once and on its own line,
where the framework text belongs; the Hooks fill in the text between them:

$BEGIN_MARKER
$END_MARKER
EOF
}

# Replace everything between the markers of control document $1 with the source text $2.
fill_block() {
  local file=$1 source=$2 begins ends first last
  if [ ! -f "$file" ]; then
    markers_error "$file"
    return 1
  fi
  begins="$(grep -cxF -- "$BEGIN_MARKER" "$file" || true)"
  ends="$(grep -cxF -- "$END_MARKER" "$file" || true)"
  first="$(grep -nxF -- "$BEGIN_MARKER" "$file" | head -1 | cut -d: -f1 || true)"
  last="$(grep -nxF -- "$END_MARKER" "$file" | head -1 | cut -d: -f1 || true)"
  if [ "$begins" != 1 ] || [ "$ends" != 1 ] || [ "$first" -gt "$last" ]; then
    markers_error "$file"
    return 1
  fi
  awk -v b="$BEGIN_MARKER" -v e="$END_MARKER" -v src="$source" '
    $0 == b { print; print ""; while ((getline line < src) > 0) print line; print ""; skip = 1; next }
    $0 == e { skip = 0 }
    !skip { print }
  ' "$file" >"$WORK/block"
  replace_if_changed "$WORK/block" "$file" || return 1
}

step_managed() {
  local kb=$1 dir f status=0
  fill_block "$(at "$kb" AGENTS.md)" "$FRAMEWORK/managed/agents-block.md" || status=1
  fill_block "$(at "$kb" README.md)" "$FRAMEWORK/managed/readme-block.md" || status=1
  # .knowledgebase/ belongs to the framework outright: same files, same contents, nothing else.
  dir="$(at "$kb" .knowledgebase)"
  mkdir -p "$dir"
  for f in "$FRAMEWORK"/managed/knowledgebase/*; do
    cp "$f" "$WORK/managed-file"
    replace_if_changed "$WORK/managed-file" "$dir/$(basename "$f")" || status=1
  done
  for f in "$dir"/* "$dir"/.[!.]*; do
    [ -e "$f" ] || continue
    if [ ! -e "$FRAMEWORK/managed/knowledgebase/$(basename "$f")" ]; then
      if unstaged "$f"; then
        unstaged_error "$f"
        status=1
        continue
      fi
      rm -rf "$f"
      printf '%s\n' "$f" >>"$STAGE"
    fi
  done
  return "$status"
}

# --- Steps 2-4: okf -------------------------------------------------------------------------------
step_fmt() {
  local kb=$1 mode=$2 docs f status=0
  docs="$(at "$kb" docs)"
  [ -d "$docs" ] || return 0
  if [ "$mode" = commit ]; then
    staged_under "$docs" >"$WORK/fmt"
  else
    find "$docs" -type f -name '*.md' >"$WORK/fmt"
  fi
  mkdir -p "$WORK/fmt.d"
  while IFS= read -r f; do
    case "$f" in *.md) ;; *) continue ;; esac
    [ "$(basename "$f")" != index.md ] && [ -f "$f" ] || continue
    # Format a copy, so a file with unstaged changes is left as it is.
    cp "$f" "$WORK/fmt.d/$(basename "$f")"
    quiet okf fmt -w "$WORK/fmt.d/$(basename "$f")" || return 1
    replace_if_changed "$WORK/fmt.d/$(basename "$f")" "$f" || status=1
  done <"$WORK/fmt"
  return "$status"
}

step_index() {
  local kb=$1 docs
  docs="$(at "$kb" docs)"
  find "$docs" -type f -name index.md >"$WORK/indexes"
  guarded "$WORK/indexes" quiet okf index "$docs" || return 1
  find "$docs" -type f -name index.md >>"$STAGE"
}

step_validate() { quiet okf validate "$(at "$1" docs)"; }
step_lint() { quiet okf lint "$(at "$1" docs)"; }

# Concept documents of knowledgebase $1: every .md in the bundle except OKF's reserved files.
concept_documents() {
  find "$(at "$1" docs)" -type f -name '*.md' ! -name index.md ! -name log.md | sort
}

# --- Step 5: frontmatter schema (what okf validate ignores: vocabularies, required fields) ------------
step_schema() {
  local kb=$1 doc out="$WORK/schema" n=0
  rm -rf "$out" && mkdir -p "$out"
  while IFS= read -r doc; do
    # One JSON instance per document, named after its path so errors point at the source file.
    yq --front-matter=extract -o=json '.' "$doc" >"$out/$(printf '%s' "${doc#./}" | sed 's#/#__#g').json" || return 1
    n=$((n + 1))
  done < <(concept_documents "$kb")
  [ "$n" -gt 0 ] || return 0
  if ! quiet check_jsonschema --schemafile "$FRAMEWORK/frontmatter.schema.json" "$out"/*.json; then
    # v2 removed `status: deprecated` (ADR-0012): name the way out, and the Migration file.
    while IFS= read -r doc; do
      [ "$(yq --front-matter=extract '.status // ""' "$doc")" != deprecated ] ||
        echo "$doc: status deprecated was removed in v2; retire the document as .knowledgebase/reference.md describes (see MIGRATION-2.0.0.md if this knowledgebase has one)" >&2
    done < <(concept_documents "$kb")
    return 1
  fi
}

# --- Step 6: citations -----------------------------------------------------------------------------
# okf reports these only as warnings, or not at all:
#   - a footnote reference with no definition, or a definition nothing references;
#   - a footnote label that matches no `sources[].id`;
#   - a `sources[].id` that no footnote cites.
# Inline code spans and fenced code blocks are ignored, so documents can show the syntax.
step_citations() {
  local kb=$1 doc ids body defs refs x status=0
  while IFS= read -r doc; do
    ids="$(yq --front-matter=extract '.sources[].id // ""' "$doc" | sed '/^$/d' | sort -u)"
    body="$(awk 'NR==1 && /^---$/ {fm=1; next} fm && /^---$/ {fm=0; next} fm {next}
                 /^[[:space:]]*(```|~~~)/ {fence=!fence; next} fence {next}
                 {gsub(/`[^`]*`/, ""); print}' "$doc")"
    defs="$(printf '%s\n' "$body" | sed -nE 's/^\[\^([^]]+)\]:.*/\1/p' | sort -u)"
    refs="$(printf '%s\n' "$body" | sed -E 's/^\[\^[^]]+\]://' | grep -oE '\[\^[^]]+\]' | sed -E 's/^\[\^(.*)\]$/\1/' | sort -u || true)"
    # Synchronous files avoid Bash 3.2's repeated process-substitution lockup
    printf '%s\n' "$refs" >"$WORK/citation-refs" || return 1
    printf '%s\n' "$defs" >"$WORK/citation-defs" || return 1
    printf '%s\n' "$ids" >"$WORK/citation-ids" || return 1
    comm -23 "$WORK/citation-refs" "$WORK/citation-defs" >"$WORK/citation-diff" || return 1
    while IFS= read -r x; do [ -n "$x" ] && echo "$doc: footnote [^$x] is referenced but never defined" >&2 && status=1; done <"$WORK/citation-diff"
    comm -13 "$WORK/citation-refs" "$WORK/citation-defs" >"$WORK/citation-diff" || return 1
    while IFS= read -r x; do [ -n "$x" ] && echo "$doc: footnote [^$x] is defined but never referenced" >&2 && status=1; done <"$WORK/citation-diff"
    comm -23 "$WORK/citation-refs" "$WORK/citation-ids" >"$WORK/citation-diff" || return 1
    while IFS= read -r x; do [ -n "$x" ] && echo "$doc: footnote [^$x] matches no sources[].id" >&2 && status=1; done <"$WORK/citation-diff"
    comm -13 "$WORK/citation-refs" "$WORK/citation-ids" >"$WORK/citation-diff" || return 1
    while IFS= read -r x; do [ -n "$x" ] && echo "$doc: source $x is never cited with [^$x]" >&2 && status=1; done <"$WORK/citation-diff"
  done < <(concept_documents "$kb")
  return "$status"
}

# --- Step 7: links (ADR-0012) -------------------------------------------------------------------
# okf reports a link to a missing document only as information, and also lists links to files that
# exist but aren't concept documents, such as source snapshots. Fail only when the file is missing.
step_links() {
  local kb=$1 docs id raw target status=0
  docs="$(at "$kb" docs)"
  okf links --json "$docs" >"$WORK/links.json" || return 1
  while IFS="$(printf '\t')" read -r id raw; do
    target="${raw%%#*}"
    target="${target%%\?*}"
    [ -n "$target" ] || continue
    case "$target" in /*) ;; *) target="$docs/$(dirname "$id")/$target" ;; esac
    if [ ! -e "$target" ]; then
      echo "$docs/$id.md: links to $raw, which doesn't exist; point it at the document that replaced it, or remove it" >&2
      status=1
    fi
  done < <(jq -r '.concepts[] | .id as $id | .links[] | select(.kind == "internal" and (.exists | not)) | [$id, .raw] | @tsv' "$WORK/links.json")
  return "$status"
}

# --- Step 8: the LikeC4 add-on --------------------------------------------------------------------
# Does the LikeC4 project in $1 have .c4 changes to act on in this mode?
likec4_changed() {
  local dir=$1 mode=$2
  # grep reads everything (no -q): under pipefail, an early exit would fail the writer with SIGPIPE.
  case "$mode" in
  diagrams) return 0 ;;
  commit) staged_under "$dir" | grep '\.c4$' >/dev/null ;;
  check) git status --porcelain --untracked-files=all -- "$dir" | grep '\.c4$' >/dev/null ;;
  esac
}

# Export every view to PNG next to its sources, the way each view declares it. likec4's PNG export
# ignores a dynamic view's `variant sequence` and only has a global --seq flag, so export everything,
# then re-export the views LikeC4's JSON export reports as sequences with --seq (ADR-0003). Drop the
# second pass once a likec4 release honours the variant.
export_pngs() {
  local dir=$1 seq_views v
  set -- # the --seq filters are collected in "$@": bash 3.2 has no safe empty arrays under set -u
  quiet likec4 export json --skip-layout -o "$WORK/model.json" "$dir" || return 1
  seq_views="$(jq -r '[.[].views // {} | to_entries[] | select(.value.variant == "sequence") | .key] | unique[]' "$WORK/model.json")" || return 1
  quiet likec4 export png "$dir" || return 1
  for v in $seq_views; do set -- "$@" -f "$v"; done
  if [ "$#" -gt 0 ]; then quiet likec4 export png --seq "$@" "$dir" || return 1; fi
}

# The PNGs of LikeC4 project $1: every PNG except those in an images/ folder, which LikeC4 projects
# use for the pictures their models embed.
exported_pngs() { find "$1" -name images -prune -o -type f -name '*.png' -print | sort; }

# Delete every exported PNG of project $1 that matches no view in the model export, so a deleted or
# renamed view leaves no picture behind.
remove_orphan_pngs() {
  local dir=$1 png status=0
  jq -r '[.[].views // {} | keys[]] | unique[]' "$WORK/model.json" >"$WORK/views" || return 1
  while IFS= read -r png; do
    grep -Fx -- "$(basename "$png" .png)" "$WORK/views" >/dev/null && continue
    if unstaged "$png"; then
      unstaged_error "$png"
      status=1
      continue
    fi
    rm -f "$png"
    printf '%s\n' "$png" >>"$STAGE"
  done < <(exported_pngs "$dir")
  return "$status"
}

step_likec4() {
  local kb=$1 mode=$2 dir f status=0
  dir="$(at "$kb" assets/likec4)"
  [ -d "$dir" ] || return 0
  likec4_changed "$dir" "$mode" || return 0
  # The exports follow the whole model on disk, so every source must match what the commit takes.
  if [ "$mode" = commit ]; then
    while IFS= read -r f; do
      case "$f" in "$dir"/*) ;; *) continue ;; esac
      case "$f" in */images/*) ;; *.png) continue ;; esac
      unstaged_error "$f"
      status=1
    done <"$WORK/unstaged"
    [ "$status" -eq 0 ] || return 1
  fi
  quiet likec4 format "$dir" || return 1
  quiet likec4 validate "$dir" || return 1
  quiet playwright install chromium-headless-shell || return 1
  exported_pngs "$dir" >"$WORK/pngs"
  guarded "$WORK/pngs" export_pngs "$dir" || return 1
  remove_orphan_pngs "$dir" || return 1
  find "$dir" -name images -prune -o -type f \( -name '*.c4' -o -name '*.png' \) -print >>"$STAGE"
}

# --- Pipeline ---------------------------------------------------------------------------------------
STEPS="managed fmt index validate lint schema citations links likec4"

run_step() { # step kb mode
  case "$1" in
  managed | index | validate | lint | schema | citations | links) "step_$1" "$2" ;;
  fmt | likec4) "step_$1" "$2" "$3" ;;
  *)
    echo "unknown step: $1 (one of: $STEPS)" >&2
    return 2
    ;;
  esac
}

pipeline() { # kb mode
  local step
  MODE=$2
  [ "$MODE" != commit ] || record_unstaged "$1"
  for step in $STEPS; do
    if ! run_step "$step" "$1" "$2"; then
      say "$1" "the $step check failed; fix what it reports above, then commit again"
      return 1
    fi
  done
}

for_each_knowledgebase() { # mode
  local kb status=0
  # The files lefthook's stage_fixed stages after this job: the same list, taken before any step
  # writes. (Lefthook lists them again after the job, which only adds files this run staged.)
  [ "$1" != commit ] || git diff --name-only --cached --diff-filter=ACMR >"$WORK/staged-at-start"
  while IFS= read -r kb; do
    # A commit checks only the knowledgebases it changes; kb-check covers them all.
    if [ "$1" = commit ] && git diff --cached --quiet -- "$kb"; then continue; fi
    pipeline "$kb" "$1" || status=1
  done < <(knowledgebases)
  if [ "$1" = commit ] && [ -s "$STAGE" ]; then
    # Stage what the run wrote, except the files lefthook stages: touching their index entries would
    # stop lefthook putting back the hunks it hid (see record_unstaged).
    comm -23 <(LC_ALL=C sort -u "$STAGE") <(LC_ALL=C sort -u "$WORK/staged-at-start") |
      while IFS= read -r f; do stage "$f" || exit 1; done || status=1
  fi
  return "$status"
}

# Stage path $1. Lefthook may run other jobs in parallel (a host repository's formatters, say), so
# wait out an index lock they hold instead of failing the commit.
stage() {
  local tries=0
  until git add -A -- "$1" 2>"$WORK/add.err"; do
    tries=$((tries + 1))
    if [ "$tries" -ge 40 ] || ! grep 'index.lock' "$WORK/add.err" >/dev/null; then
      cat "$WORK/add.err" >&2
      return 1
    fi
    sleep 0.25
  done
}

diagrams() {
  local kb status=0
  MODE=diagrams
  while IFS= read -r kb; do
    step_likec4 "$kb" diagrams || {
      say "$kb" "the LikeC4 export failed"
      status=1
    }
  done < <(knowledgebases)
  return "$status"
}

# --- Notices (ADR-0004) -------------------------------------------------------------------------------
# hooks/shell-version names the oldest Shell these Hooks are content with. Raising it (for a new
# major, or a Shell change the Hooks can't make) announces `copier update` to every knowledgebase.
semver() { printf '%s\n' "$1" | sed -nE 's/^v?([0-9]+)\.([0-9]+)\.([0-9]+).*/\1 \2 \3/p'; }
older_than() { # a b: is version a older than version b? Unparsable versions are never older.
  local a b
  a="$(semver "$1")" b="$(semver "$2")"
  [ -n "$a" ] && [ -n "$b" ] || return 1
  # shellcheck disable=SC2086 # split each version into its three numbers
  set -- $a $b
  [ "$1" -lt "$4" ] || { [ "$1" -eq "$4" ] && { [ "$2" -lt "$5" ] || { [ "$2" -eq "$5" ] && [ "$3" -lt "$6" ]; }; }; }
}

notices() {
  local kb shell wanted
  wanted="$(tr -d '[:space:]' <"$FRAMEWORK/hooks/shell-version")"
  while IFS= read -r kb; do
    shell="$(sed -nE "s/^_commit:[[:space:]]*['\"]?([^'\"]*)['\"]?[[:space:]]*$/\1/p" "$(at "$kb" "$ANSWERS_FILE")")"
    if older_than "$shell" "$wanted"; then
      say "$kb" "its Shell ($shell) predates v$wanted. Run \`copier update --trust -a $ANSWERS_FILE\` in it, then complete any MIGRATION-*.md it leaves before committing."
    fi
  done < <(knowledgebases)
  return 0
}

# Sourced (by the Shell's Copier task) for its helpers and pins: stop here.
[ "${BASH_SOURCE[0]}" = "$0" ] || return 0

case "${1:-}" in
pre-commit) for_each_knowledgebase commit ;;
check) for_each_knowledgebase check ;;
diagrams) diagrams ;;
notices) notices ;;
regenerate) step_managed "${2:?knowledgebase folder}" ;;
step) run_step "${2:?step}" "${3:?knowledgebase folder}" check ;;
*)
  sed -n '3,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
  exit 2
  ;;
esac
