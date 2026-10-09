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
# A knowledgebase is any folder holding .copier-answers.knowledgebase.yml (ADR-0008). Every step
# takes the knowledgebase's folder, never assumes the repository root, and stops the pipeline when
# it fails. Runs from the repository root, on bash 3.2. Every tool is pinned below and reached
# through `mise x`, so knowledgebases carry no mise.toml (ADR-0001).
set -euo pipefail

FRAMEWORK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
ANSWERS_FILE=.copier-answers.knowledgebase.yml
BEGIN_MARKER='<!-- BEGIN knowledgebase-framework managed block: edits here are replaced at the next commit -->'
END_MARKER='<!-- END knowledgebase-framework managed block -->'

# --- Pinned tools -------------------------------------------------------------------------------
# okf is built validator-only: its default `studio` feature doesn't compile on current rustc.
okf() { mise x 'cargo:okf[default-features=false,features=validator]@0.2.7' -- okf "$@"; }
yq() { mise x aqua:mikefarah/yq@4.53.6 -- yq "$@"; }
jq() { mise x aqua:jqlang/jq@1.8.2 -- jq "$@"; }
check_jsonschema() { mise x pipx:check-jsonschema@0.37.4 -- check-jsonschema "$@"; }
likec4() { mise x npm:likec4@1.59.4 -- likec4 "$@"; }
# Keep in step with the Playwright that likec4 bundles (1.60.0 for likec4 1.59.4): it installs the
# Chromium revision likec4's PNG export looks for, which likec4 never downloads itself.
playwright() { mise x npm:playwright@1.60.0 -- playwright "$@"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
STAGE="$WORK/stage" # paths the pipeline rewrote, staged at the end of a pre-commit run
: >"$STAGE"

# --- Helpers ------------------------------------------------------------------------------------
# Path of $2 inside knowledgebase $1, written the way git prints paths ("docs/x", not "./docs/x").
at() { if [ "$1" = . ]; then printf '%s' "$2"; else printf '%s/%s' "$1" "$2"; fi; }
say() { printf 'knowledgebase %s: %s\n' "$([ "$1" = . ] && echo '(repository root)' || echo "$1")" "$2" >&2; }

# Move $1 over $2 when their contents differ, and remember $2 for staging.
replace_if_changed() {
  if [ -f "$2" ] && cmp -s "$1" "$2"; then
    rm -f "$1"
  else
    cat "$1" >"$2" && rm -f "$1" && printf '%s\n' "$2" >>"$STAGE"
  fi
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
  replace_if_changed "$WORK/block" "$file"
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
    replace_if_changed "$WORK/managed-file" "$dir/$(basename "$f")"
  done
  for f in "$dir"/* "$dir"/.[!.]*; do
    [ -e "$f" ] || continue
    if [ ! -e "$FRAMEWORK/managed/knowledgebase/$(basename "$f")" ]; then
      rm -rf "$f"
      printf '%s\n' "$f" >>"$STAGE"
    fi
  done
  return "$status"
}

# --- Steps 2-4: okf -------------------------------------------------------------------------------
step_fmt() {
  local kb=$1 mode=$2 docs f before
  docs="$(at "$kb" docs)"
  [ -d "$docs" ] || return 0
  if [ "$mode" = commit ]; then
    staged_under "$docs" >"$WORK/fmt"
  else
    find "$docs" -type f -name '*.md' >"$WORK/fmt"
  fi
  while IFS= read -r f; do
    case "$f" in *.md) ;; *) continue ;; esac
    [ "$(basename "$f")" != index.md ] && [ -f "$f" ] || continue
    before="$(cksum <"$f")"
    quiet okf fmt -w "$f" || return 1
    [ "$before" = "$(cksum <"$f")" ] || printf '%s\n' "$f" >>"$STAGE"
  done <"$WORK/fmt"
}

step_index() {
  local kb=$1 docs
  docs="$(at "$kb" docs)"
  quiet okf index "$docs" || return 1
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
  quiet check_jsonschema --schemafile "$FRAMEWORK/frontmatter.schema.json" "$out"/*.json
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
    while IFS= read -r x; do [ -n "$x" ] && echo "$doc: footnote [^$x] is referenced but never defined" >&2 && status=1; done < <(comm -23 <(printf '%s\n' "$refs") <(printf '%s\n' "$defs"))
    while IFS= read -r x; do [ -n "$x" ] && echo "$doc: footnote [^$x] is defined but never referenced" >&2 && status=1; done < <(comm -13 <(printf '%s\n' "$refs") <(printf '%s\n' "$defs"))
    while IFS= read -r x; do [ -n "$x" ] && echo "$doc: footnote [^$x] matches no sources[].id" >&2 && status=1; done < <(comm -23 <(printf '%s\n' "$refs") <(printf '%s\n' "$ids"))
    while IFS= read -r x; do [ -n "$x" ] && echo "$doc: source $x is never cited with [^$x]" >&2 && status=1; done < <(comm -13 <(printf '%s\n' "$refs") <(printf '%s\n' "$ids"))
  done < <(concept_documents "$kb")
  return "$status"
}

# --- Step 7: the LikeC4 add-on --------------------------------------------------------------------
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

step_likec4() {
  local kb=$1 mode=$2 dir
  dir="$(at "$kb" assets/likec4)"
  [ -d "$dir" ] || return 0
  likec4_changed "$dir" "$mode" || return 0
  quiet likec4 format "$dir" || return 1
  quiet likec4 validate "$dir" || return 1
  quiet playwright install chromium-headless-shell || return 1
  export_pngs "$dir" || return 1
  find "$dir" -type f \( -name '*.c4' -o -name '*.png' \) >>"$STAGE"
}

# --- Pipeline ---------------------------------------------------------------------------------------
STEPS="managed fmt index validate lint schema citations likec4"

run_step() { # step kb mode
  case "$1" in
  managed | index | validate | lint | schema | citations) "step_$1" "$2" ;;
  fmt | likec4) "step_$1" "$2" "$3" ;;
  *)
    echo "unknown step: $1 (one of: $STEPS)" >&2
    return 2
    ;;
  esac
}

pipeline() { # kb mode
  local step
  for step in $STEPS; do
    if ! run_step "$step" "$1" "$2"; then
      say "$1" "the $step check failed; fix what it reports above, then commit again"
      return 1
    fi
  done
}

for_each_knowledgebase() { # mode
  local kb status=0
  while IFS= read -r kb; do
    pipeline "$kb" "$1" || status=1
  done < <(knowledgebases)
  if [ "$1" = commit ] && [ -s "$STAGE" ]; then
    sort -u "$STAGE" | while IFS= read -r f; do git add -A -- "$f"; done
  fi
  return "$status"
}

diagrams() {
  local kb status=0
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
  set -- $a $b
  [ "$1" -lt "$4" ] || { [ "$1" -eq "$4" ] && { [ "$2" -lt "$5" ] || { [ "$2" -eq "$5" ] && [ "$3" -lt "$6" ]; }; }; }
}

notices() {
  local kb shell wanted
  wanted="$(tr -d '[:space:]' <"$FRAMEWORK/hooks/shell-version")"
  while IFS= read -r kb; do
    shell="$(sed -nE "s/^_commit:[[:space:]]*['\"]?([^'\"]*)['\"]?[[:space:]]*$/\1/p" "$(at "$kb" "$ANSWERS_FILE")")"
    if older_than "$shell" "$wanted"; then
      say "$kb" "its Shell ($shell) predates v$wanted. Run \`copier update --trust\` in it, then complete any MIGRATION-*.md it leaves before committing."
    fi
  done < <(knowledgebases)
  return 0
}

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
