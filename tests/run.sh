#!/usr/bin/env bash
# The framework's tests: `bash tests/run.sh [group...]`. Offline once the pinned tools are cached.
# Groups: syntax reference creation embedded fixtures update fail-closed managed unstaged markdownlint
# likec4 notices
# KB_TEST_VERBOSE=1 shows evidence lines; KB_TEST_KEEP=1 keeps the scratch folder.
set -uo pipefail
# shellcheck source=tests/lib.sh
# shellcheck disable=SC1091 # lib.sh is linted on its own
. "$(dirname "$0")/lib.sh"

group_syntax() {
  local f
  for f in hooks/knowledgebase.sh shell/setup.sh .lefthook/*/*.sh tests/lib.sh tests/run.sh; do
    check "bash 3.2 parses $f" /bin/bash -n "$FW/$f"
  done
}

ROOT_FILES='.copier-answers.knowledgebase.yml
.gitignore
.knowledgebase/blueprints.md
.knowledgebase/markdown-preview.css
.knowledgebase/reference.md
.markdownlint.jsonc
.vscode/extensions.json
.vscode/settings.json
AGENTS.md
CLAUDE.md
README.md
assets/.gitkeep
docs/log.md
lefthook.yml'
LIKEC4_FILES='assets/likec4/index.png
assets/likec4/likec4.config.json
assets/likec4/model.c4
assets/likec4/saas.png
assets/likec4/spec.c4
assets/likec4/views.c4'

group_creation() {
  local likec4 kb expected
  for likec4 in true false; do
    kb="$T/root-likec4-$likec4"
    if ! create "$kb" -d likec4="$likec4" -d related_knowledgebases="../Team: The team's own subjects."; then
      fail "root creation, likec4=$likec4" "$(cat "$T/last-copy.log")"
      continue
    fi
    note "$(strip_colors <"$T/last-copy.log" | grep -E 'hook: |✔️|Created|Knowledgebase `')"
    expected="$ROOT_FILES"
    [ "$likec4" = false ] || expected="$(printf '%s\n%s\n' "$ROOT_FILES" "$LIKEC4_FILES" | LC_ALL=C sort)"
    check "root creation, likec4=$likec4: exactly the planned tree" \
      diff <(printf '%s\n' "$expected" | LC_ALL=C sort) <(tree_of "$kb")
    check "root creation, likec4=$likec4: no scratch folder (ADR-0011)" \
      test ! -e "$kb/.scratch"
    check "root creation, likec4=$likec4: CLAUDE.md links to AGENTS.md" \
      test "$(readlink "$kb/CLAUDE.md")" = AGENTS.md
    check "root creation, likec4=$likec4: first commit made through the Hooks" \
      bash -c "grep -q 'hook: *pre-commit' '$T/last-copy.log' && grep -q 'knowledgebase-hooks-fetched' '$T/last-copy.log' &&
        [ \"\$(git -C '$kb' log --format=%s)\" = 'chore: create knowledgebase' ] && [ -z \"\$(git -C '$kb' status --porcelain)\" ]"
    check "root creation, likec4=$likec4: lefthook run kb-check passes and changes nothing" \
      bash -c "cd '$kb' && lefthook run kb-check && [ -z \"\$(git status --porcelain)\" ]"
    check "root creation, likec4=$likec4: AGENTS.md lists the related knowledgebase" \
      grep -qF -- "- \`../Team\`: The team's own subjects. Its rules are in \`../Team/AGENTS.md\`." "$kb/AGENTS.md"
    check "root creation, likec4=$likec4: managed block filled from the release" \
      bash -c "awk 'f&&/^<!-- END/{exit} f; /^<!-- BEGIN/{f=1}' '$kb/AGENTS.md' | sed '1d;\$d' | diff - '$FW/managed/agents-block.md'"
  done
}

# The printed lefthook lines: the indented block after "1. Add these lines".
printed_wiring() { strip_colors <"$1" | awk '/^1\. Add these lines/{f=1; next} f && /^Agents load/{exit} f && /^    /{sub(/^    /, ""); print}'; }

group_embedded() {
  local parent="$T/parent" out
  mkdir -p "$parent/docs" "$parent/.vscode"
  (cd "$parent" && git init -q &&
    printf '# Parent\n\nThe parent repository.\n' >README.md &&
    printf 'No frontmatter and no H1: not a knowledgebase document.\n' >docs/notes.md &&
    printf '{\n  "editor.tabSize": 2\n}\n' >.vscode/settings.json &&
    git add -A && git commit -q -m "chore: parent")
  for kb in knowledge:true notes:false; do
    if ! create "$parent/${kb%%:*}" -d likec4="${kb#*:}"; then
      fail "embedded creation, ${kb%%:*} (likec4=${kb#*:})" "$(cat "$T/last-copy.log")"
      return
    fi
    cp "$T/last-copy.log" "$T/copy-${kb%%:*}.log"
    note "$(strip_colors <"$T/last-copy.log" | sed -n '/^This knowledgebase is inside/,$p')"
    check "embedded creation, ${kb%%:*}: prints the pointer line for the parent's AGENTS.md" \
      grep -qF "Knowledgebase \`${kb%%:*}/\`: Fixture subjects. Read \`${kb%%:*}/AGENTS.md\`" "$T/last-copy.log"
    check "embedded creation, ${kb%%:*}: writes no lefthook.yml and makes no commit" \
      bash -c "[ ! -e '$parent/${kb%%:*}/lefthook.yml' ] && [ \"\$(git -C '$parent' rev-list --count HEAD)\" = 1 ]"
  done
  check "embedded creation: prints lefthook lines identical to a root knowledgebase's" \
    diff <(printed_wiring "$T/copy-knowledge.log") "$FW/shell/lefthook.yml"
  check "embedded creation: the parent's .vscode/ gains both entries and keeps its own" \
    bash -c "jq -e '.\"editor.tabSize\" == 2 and .\"markdown.styles\" == [\"knowledge/.knowledgebase/markdown-preview.css\", \"notes/.knowledgebase/markdown-preview.css\"]' '$parent/.vscode/settings.json' &&
      jq -e '.recommendations == [\"bierner.markdown-footnotes\"]' '$parent/.vscode/extensions.json'"

  # Apply the printed wiring, then commit in the parent.
  printed_wiring "$T/copy-knowledge.log" >"$parent/lefthook.yml"
  (cd "$parent" && lefthook install >/dev/null 2>&1)
  out="$(cd "$parent" && git add -A && git commit -m "docs: add two knowledgebases" 2>&1)"
  note "$(printf '%s\n' "$out" | strip_colors | grep -E 'hook: |✔️|✘|knowledgebase ')"
  check "embedded wiring: a parent commit runs the Hooks and passes" bash -c "printf '%s' \"\$1\" | grep -q 'knowledgebase-notices'" _ "$out"
  check "embedded wiring: the Hooks exported and committed the knowledgebase's diagrams" \
    git -C "$parent" cat-file -e HEAD:knowledge/assets/likec4/index.png
  check "embedded wiring: the parent's own Markdown is outside the Hooks' reach" \
    git -C "$parent" cat-file -e HEAD:docs/notes.md

  # A broken document in one knowledgebase blocks the parent's commit and names that knowledgebase.
  cp "$FW/tests/fixtures/fail/schema-genre/docs/broken-example.md" "$parent/notes/docs/"
  out="$(cd "$parent" && git add -A && git commit -m "docs: broken" 2>&1)"
  check "embedded wiring: a broken document blocks the parent's commit, naming its knowledgebase" \
    bash -c "! git -C '$parent' cat-file -e HEAD:notes/docs/broken-example.md 2>/dev/null && printf '%s' \"\$1\" | grep -q 'knowledgebase notes: the schema check failed'" _ "$out"
  note "$(printf '%s\n' "$out" | strip_colors | grep -E 'knowledgebase notes|broken-example' | head -3)"
  git -C "$parent" reset -q

  # The broken document stays on disk, unstaged: a commit that changes only knowledge/ skips notes/.
  printf 'note\n' >"$parent/knowledge/assets/note.txt"
  out="$(cd "$parent" && git add knowledge/assets/note.txt && git commit -m "docs: a note" 2>&1)"
  check "pre-commit scope: a commit checks only the knowledgebases it changes" \
    bash -c "[ \"\$(git -C '$parent' log -1 --format=%s)\" = 'docs: a note' ]" || note "$out"
  out="$(cd "$parent" && lefthook run kb-check 2>&1)"
  check "pre-commit scope: kb-check still covers every knowledgebase" \
    bash -c "printf '%s' \"\$1\" | grep -q 'knowledgebase notes: the schema check failed'" _ "$out"
  rm "$parent/notes/docs/broken-example.md"
}

# A root knowledgebase holding the must-pass fixture, committed.
PASS_KB=""
pass_kb() {
  [ -z "$PASS_KB" ] || return 0
  PASS_KB="$T/pass"
  create "$PASS_KB" -d likec4=false || {
    fail "must-pass fixture: create its knowledgebase" "$(cat "$T/last-copy.log")"
    return 1
  }
  overlay "$FW/tests/fixtures/pass" "$PASS_KB"
}

STEPS="managed validate lint schema citations links likec4"

group_fixtures() {
  local step out d name expected message kb failed
  pass_kb || return
  for step in index $STEPS; do
    check "must-pass fixture: the $step step passes" bash "$(hooks_of "$PASS_KB")" step "$step" "$PASS_KB"
  done
  out="$(cd "$PASS_KB" && git add -A && git commit -m "docs: add the must-pass fixture" 2>&1)"
  check "must-pass fixture: commits, with six documents in the generated index" \
    bash -c "[ \"\$(git -C '$PASS_KB' log -1 --format=%s)\" = 'docs: add the must-pass fixture' ] &&
      [ \"\$(git -C '$PASS_KB' show HEAD:docs/index.md | grep -c '^\* \[')\" = 6 ] && [ -z \"\$(git -C '$PASS_KB' status --porcelain)\" ]" ||
    note "$out"
  # A user's locked mise whose config pins one of the Hooks' tools with no lock entry, on a bare
  # PATH: the Hooks carry no lockfile and bring every tool they run.
  printf '[tools]\n"aqua:mikefarah/yq" = "4.53.6"\n' >"$T/locked-mise.toml"
  check "must-pass fixture: kb-check passes under a locked mise, with only git, mise and lefthook on PATH" \
    bare env MISE_LOCKED=1 MISE_GLOBAL_CONFIG_FILE="$T/locked-mise.toml" \
    bash -c "cd '$PASS_KB' && lefthook run kb-check && [ -z \"\$(git status --porcelain)\" ]"

  # Each must-fail fixture names, in tests/fixtures/fail/<name>/expect, the steps that enforce its
  # rule (usually one; the commit stops at the first) and a message one of them reports.
  for d in "$FW"/tests/fixtures/fail/*/; do
    name="$(basename "$d")"
    expected="$(sed -n 's/^steps: //p' "$d/expect")"
    message="$(sed -n 's/^message: //p' "$d/expect")"
    kb="$T/fail-$name"
    cp -R "$PASS_KB" "$kb"
    overlay "$d" "$kb"
    failed=""
    : >"$T/fail-$name.out"
    # The pipeline regenerates the index before any check runs; so do the tests.
    (cd "$kb" && bash "$(hooks_of "$kb")" step index . >/dev/null 2>&1)
    for step in $STEPS; do
      if ! out="$(cd "$kb" && bash "$(hooks_of "$kb")" step "$step" . 2>&1)"; then
        failed="$failed $step"
        printf '%s\n' "$out" >>"$T/fail-$name.out"
      fi
    done
    check "must-fail fixture $name: fails at $expected and nowhere else" \
      bash -c "[ '$failed' = ' $expected' ] || { echo 'failed steps:$failed'; exit 1; }"
    check "must-fail fixture $name: reports \"$message\"" grep -qF -- "$message" "$T/fail-$name.out"
    note "$(grep -v '^Schema validation errors' "$T/fail-$name.out" | head -2 | sed "s#/[^ ]*/schema/##")"
    out="$(cd "$kb" && git add -A && git commit -m "docs: broken" 2>&1)"
    check "must-fail fixture $name: blocks the commit at the ${expected%% *} check" \
      bash -c "printf '%s' \"\$1\" | grep -q 'the ${expected%% *} check failed' && [ \"\$(git -C '$kb' log -1 --format=%s)\" != 'docs: broken' ]" _ "$out"
  done
}

group_update() {
  local kb="$T/update" out
  if ! create "$kb" --vcs-ref "$BASELINE_TAG"; then
    fail "update: create at $BASELINE_TAG" "$(cat "$T/last-copy.log")"
    return
  fi
  (cd "$kb" && awk '{print} /^Fixture subjects\.$/ {print ""; print "Local rule: keep every runbook under one page."}' AGENTS.md >AGENTS.tmp &&
    mv AGENTS.tmp AGENTS.md &&
    awk '{print} /^Fixture subjects\.$/ {print ""; print "Maintained by the fixture team."}' README.md >README.tmp &&
    mv README.tmp README.md &&
    git commit -qam "docs: local sections" >/dev/null 2>&1)
  # A deprecated document and a link to it, valid under v1, for the v2 migration to retire.
  sed 's/^status: stable$/status: deprecated/' "$FW/tests/fixtures/pass/docs/about-tracing-tools.md" >"$kb/docs/about-tracing-tools.md"
  sed 's#^Use the tracing your platform already ships.$#See [About tracing tools](about-tracing-tools.md).#; s/^title: About tracing tools$/title: About tracing/; s/^\# About tracing tools$/\# About tracing/' \
    "$FW/tests/fixtures/pass/docs/about-tracing-tools.md" >"$kb/docs/about-tracing.md"
  out="$(cd "$kb" && git add -A && git commit -m "docs: a deprecated document" 2>&1)"
  check "update: before v2, a deprecated document commits" test "$(git -C "$kb" log -1 --format=%s)" = "docs: a deprecated document" || note "$out"
  out="$(cd "$kb" && copier update --trust --defaults -a .copier-answers.knowledgebase.yml --vcs-ref "$NEW_TAG" 2>&1)"
  note "$(printf '%s\n' "$out" | strip_colors | grep -iE 'updating|version|MIGRATION|conflict' | head -5)"
  check "update: $BASELINE_TAG → $NEW_TAG records the new release" grep -q "^_commit: $NEW_TAG" "$kb/.copier-answers.knowledgebase.yml"
  check "update: local sections kept" bash -c "grep -q 'Local rule: keep every runbook under one page.' '$kb/AGENTS.md' && grep -q 'Maintained by the fixture team.' '$kb/README.md'"
  check "update: no merge conflicts" bash -c "! grep -rqE '^(<<<<<<<|>>>>>>>)' '$kb' --exclude-dir=.git && ! find '$kb' -name '*.rej' | grep . >/dev/null"
  check "update: crossing v2 leaves MIGRATION-2.0.0.md" test -f "$kb/MIGRATION-2.0.0.md"
  check "update: crossing v2 points lefthook.yml at the v2 Hooks" \
    bash -c "grep -q '^    ref: v2$' '$kb/lefthook.yml' && grep -q 'knowledgebase-framework-v2\";' '$kb/lefthook.yml' && ! grep -q 'v1' '$kb/lefthook.yml'"
  out="$(cd "$kb" && git add -A && git commit -m "chore: update the knowledgebase" 2>&1)"
  check "update: the v2 Hooks block the deprecated document and name the way out" \
    bash -c "printf '%s' \"\$1\" | grep -q 'docs/about-tracing-tools.md: status deprecated was removed in v2' && [ \"\$(git -C '$kb' log -1 --format=%s)\" != 'chore: update the knowledgebase' ]" _ "$out"
  # Complete the migration the way MIGRATION-2.0.0.md says: retire the document, then delete the file.
  rm "$kb/docs/about-tracing-tools.md"
  out="$(cd "$kb" && git add -A && git commit -m "chore: update the knowledgebase" 2>&1)"
  check "update: the v2 Hooks block a link to the retired document" \
    bash -c "printf '%s' \"\$1\" | grep -q 'links to about-tracing-tools.md, which doesn.t exist' && [ \"\$(git -C '$kb' log -1 --format=%s)\" != 'chore: update the knowledgebase' ]" _ "$out"
  sed -i.bak 's#^See \[About tracing tools\](about-tracing-tools.md).$#Use the tracing your platform already ships.#' "$kb/docs/about-tracing.md" && rm "$kb/docs/about-tracing.md.bak"
  printf '* **Retired**: about-tracing-tools.md, replaced by [About tracing](about-tracing.md).\n' >>"$kb/docs/log.md"
  rm "$kb/MIGRATION-2.0.0.md"
  out="$(cd "$kb" && git add -A && git commit -m "chore: update the knowledgebase" 2>&1)"
  check "update: the updated knowledgebase commits through the Hooks" test "$(git -C "$kb" log -1 --format=%s)" = "chore: update the knowledgebase" || note "$out"
  check "update: kb-check passes afterwards" bash -c "cd '$kb' && lefthook run kb-check >/dev/null"
}

group_fail_closed() {
  local kb="$T/fail-closed" out
  [ -d "$T/root-likec4-false" ] || create "$T/root-likec4-false" -d likec4=false
  cp -R "$T/root-likec4-false" "$kb"
  sed "s#file://$T/remote/#file://$T/offline/#" "$T/gitconfig" >"$T/gitconfig-offline"
  rm -rf "$(git -C "$kb" rev-parse --path-format=absolute --git-common-dir)/info/lefthook-remotes"
  printf 'note\n' >"$kb/assets/note.txt"
  out="$(cd "$kb" && GIT_CONFIG_GLOBAL="$T/gitconfig-offline" lefthook install 2>&1 && git add -A &&
    GIT_CONFIG_GLOBAL="$T/gitconfig-offline" git commit -m "docs: offline" 2>&1)"
  note "$(printf '%s\n' "$out" | strip_colors | grep -iE "sync|fetched|✘" | head -4)"
  check "fail-closed: offline with no cached Hooks, the commit is blocked" \
    bash -c "printf '%s' \"\$1\" | grep -q \"Knowledgebase Hooks not fetched yet: go online and run 'lefthook install'\" && [ \"\$(git -C '$kb' log -1 --format=%s)\" != 'docs: offline' ]" _ "$out"
  out="$(cd "$kb" && lefthook install >/dev/null 2>&1 && git commit -m "docs: online" 2>&1)"
  check "fail-closed: once the Hooks are fetched, the commit goes through them" \
    bash -c "[ \"\$(git -C '$kb' log -1 --format=%s)\" = 'docs: online' ] && printf '%s' \"\$1\" | grep -q knowledgebase-notices" _ "$out"
}

group_managed() {
  local kb="$T/managed" out
  [ -d "$T/root-likec4-false" ] || create "$T/root-likec4-false" -d likec4=false
  cp -R "$T/root-likec4-false" "$kb"
  # shellcheck disable=SC2016 # the backticks are Markdown
  sed -i.bak 's/^Run `lefthook run kb-check`: it runs every check a commit runs\./Skip the checks./' "$kb/AGENTS.md" && rm "$kb/AGENTS.md.bak"
  out="$(cd "$kb" && git commit -am "docs: edit the managed block" 2>&1)"
  check "managed text: an edit inside the managed block is reverted at the next commit" \
    bash -c "git -C '$kb' show HEAD:AGENTS.md | grep -q '^Run \`lefthook run kb-check\`' && ! git -C '$kb' show HEAD:AGENTS.md | grep -q 'Skip the checks' && [ -z \"\$(git -C '$kb' status --porcelain)\" ]"
  grep -v 'knowledgebase-framework managed block' "$kb/README.md" >"$kb/README.tmp" && mv "$kb/README.tmp" "$kb/README.md"
  out="$(cd "$kb" && git commit -am "docs: drop the markers" 2>&1)"
  note "$(printf '%s\n' "$out" | strip_colors | grep -A7 'markers are missing' | head -8)"
  check "managed text: missing markers block the commit with a fix-it message" \
    bash -c "printf '%s' \"\$1\" | grep -q 'README.md: the managed block.s markers are missing or broken' &&
      printf '%s' \"\$1\" | grep -qF '<!-- BEGIN knowledgebase-framework managed block' && [ \"\$(git -C '$kb' log -1 --format=%s)\" != 'docs: drop the markers' ]" _ "$out"
}

# commit_fails <kb> <message> <name>: a commit attempt in <kb> is refused with <message>.
commit_fails() {
  local out
  out="$(cd "$1" && git commit -m "docs: should not land" 2>&1)"
  check "$3" bash -c "printf '%s' \"\$1\" | grep -qF -- \"\$2\" && [ \"\$(git -C '$1' log -1 --format=%s)\" != 'docs: should not land' ]" _ "$out" "$2"
}

# The pass fixture's tracing document with its tags in flow style, which okf fmt rewrites.
flow_style_tags() {
  awk '/^tags:$/ {print "tags: [observability, tracing]"; skip = 1; next} skip && /^  - / {next} {skip = 0; print}' \
    "$FW/tests/fixtures/pass/docs/about-tracing-tools.md"
}

# partly_staged_document <dir>: stage the flow-style tracing document, then add an unstaged paragraph.
partly_staged_document() {
  flow_style_tags >"$1/docs/about-tracing-tools.md"
  git -C "$1" add docs/about-tracing-tools.md
  printf '\nAn unstaged paragraph.\n' >>"$1/docs/about-tracing-tools.md"
}

group_unstaged() {
  local kb="$T/unstaged" out msg='has unstaged changes that the Hooks would overwrite or stage. Stage or stash them'
  [ -d "$T/root-likec4-true" ] || create "$T/root-likec4-true" -d likec4=true
  cp -R "$T/root-likec4-true" "$kb"
  printf 'note\n' >"$kb/assets/note.txt"
  git -C "$kb" add assets/note.txt

  # An unstaged edit inside the managed block: the Hooks would rewrite AGENTS.md.
  # shellcheck disable=SC2016 # the backticks are Markdown
  sed -i.bak 's/^Run `lefthook run kb-check`: it runs every check a commit runs\./Skip the checks./' "$kb/AGENTS.md" && rm "$kb/AGENTS.md.bak"
  commit_fails "$kb" "AGENTS.md $msg" "unstaged changes: an unstaged managed-block edit blocks the commit, naming AGENTS.md"
  check "unstaged changes: AGENTS.md is left as it was and stays unstaged" \
    bash -c "grep -q 'Skip the checks' '$kb/AGENTS.md' && ! git -C '$kb' diff --cached --name-only | grep -qx AGENTS.md"
  git -C "$kb" checkout -q AGENTS.md

  # An unstaged edit in a local section, with the managed block current: nothing to rewrite.
  printf '\nLocal rule, not yet staged.\n' >>"$kb/README.md"
  out="$(cd "$kb" && git commit -m "docs: a note" 2>&1)"
  check "unstaged changes: an unrelated unstaged edit lets the commit through and stays unstaged" \
    bash -c "[ \"\$(git -C '$kb' log -1 --format=%s)\" = 'docs: a note' ] && ! git -C '$kb' show HEAD:README.md | grep -q 'not yet staged' &&
      git -C '$kb' diff --name-only | grep -qx README.md" || note "$out"
  git -C "$kb" checkout -q README.md

  # A partly staged document. Lefthook hides its unstaged hunks while the Hooks run: okf fmt
  # normalizes the staged text (flow-style tags), lefthook stages that through stage_fixed, and the
  # unstaged paragraph comes back, still unstaged.
  partly_staged_document "$kb"
  out="$(cd "$kb" && git commit -m "docs: add the tracing tools" 2>&1)"
  check "unstaged changes: a partly staged document commits with okf fmt's rewrite" \
    bash -c "[ \"\$(git -C '$kb' log -1 --format=%s)\" = 'docs: add the tracing tools' ] &&
      git -C '$kb' show HEAD:docs/about-tracing-tools.md | grep -qx '  - tracing' &&
      ! git -C '$kb' show HEAD:docs/about-tracing-tools.md | grep -q 'An unstaged paragraph'" || note "$out"
  check "unstaged changes: its unstaged paragraph comes back, still unstaged" \
    bash -c "git -C '$kb' diff -- docs/about-tracing-tools.md | grep -qx '+An unstaged paragraph.'"
  git -C "$kb" checkout -q docs/about-tracing-tools.md

  # The unstaged edit on the very lines okf fmt rewrites: lefthook can't put it back, so it restores
  # every file and stops the commit. Nothing is lost, and nothing unstaged is staged.
  flow_style_tags >"$kb/docs/about-tracing-tools.md"
  git -C "$kb" add docs/about-tracing-tools.md
  git -C "$kb" show :docs/about-tracing-tools.md >"$T/tracing.staged"
  sed -i.bak 's/^tags: \[observability, tracing\]$/tags: [observability, tracing, apm]/' "$kb/docs/about-tracing-tools.md" &&
    rm "$kb/docs/about-tracing-tools.md.bak"
  cp "$kb/docs/about-tracing-tools.md" "$T/tracing.before"
  commit_fails "$kb" "Unable to restore previously hidden unstaged changes" "unstaged changes: an unstaged edit on the lines okf fmt rewrites stops the commit"
  check "unstaged changes: that edit survives in the working tree" cmp -s "$T/tracing.before" "$kb/docs/about-tracing-tools.md"
  check "unstaged changes: the staged text is left as it was" \
    bash -c "git -C '$kb' show :docs/about-tracing-tools.md | cmp -s - '$T/tracing.staged'"
  git -C "$kb" checkout -q HEAD -- docs/about-tracing-tools.md

  # A staged file the Hooks delete: lefthook stages the deletion with the rest of the fixes.
  printf 'mine\n' >"$kb/.knowledgebase/notes.md"
  printf '\nA staged local note.\n' >>"$kb/README.md"
  git -C "$kb" add .knowledgebase/notes.md README.md
  out="$(cd "$kb" && git commit -m "docs: a staged stray file" 2>&1)"
  check "unstaged changes: a staged file the Hooks delete stays out of the commit and the working tree" \
    bash -c "[ \"\$(git -C '$kb' log -1 --format=%s)\" = 'docs: a staged stray file' ] &&
      ! git -C '$kb' cat-file -e HEAD:.knowledgebase/notes.md 2>/dev/null && [ ! -e '$kb/.knowledgebase/notes.md' ] &&
      [ -z \"\$(git -C '$kb' status --porcelain)\" ]" || note "$out"

  # The partly staged commit again, from a linked worktree of the same repository.
  local wt="$T/unstaged-worktree"
  git -C "$kb" worktree add -q -b unstaged-worktree "$wt"
  # Drop the document on the worktree's branch first, so the commit below adds it again.
  git -C "$wt" rm -q docs/about-tracing-tools.md && git -C "$wt" commit -q --no-verify -m "docs: drop the tracing tools"
  partly_staged_document "$wt"
  out="$(cd "$wt" && git commit -m "docs: add the tracing tools again" 2>&1)"
  check "unstaged changes: from a linked worktree, a partly staged document commits with the rewrite" \
    bash -c "[ \"\$(git -C '$wt' log -1 --format=%s)\" = 'docs: add the tracing tools again' ] &&
      git -C '$wt' show HEAD:docs/about-tracing-tools.md | grep -qx '  - tracing' &&
      git -C '$wt' diff -- docs/about-tracing-tools.md | grep -qx '+An unstaged paragraph.'" || note "$out"
  git -C "$kb" worktree remove --force "$wt"

  # A staged .c4 change with another, unstaged one: the export would not match the commit.
  sed -i.bak "s/title 'Landscape view'/title 'Landscape'/" "$kb/assets/likec4/views.c4" && rm "$kb/assets/likec4/views.c4.bak"
  git -C "$kb" add assets/likec4/views.c4
  printf '\n// an unstaged comment\n' >>"$kb/assets/likec4/model.c4"
  commit_fails "$kb" "assets/likec4/model.c4 $msg" "unstaged changes: an unstaged .c4 edit blocks a LikeC4 commit, naming the file"
  git -C "$kb" checkout -q assets/likec4/model.c4

  # An exported PNG with unstaged changes the export would overwrite.
  printf 'not a picture\n' >"$kb/assets/likec4/index.png"
  commit_fails "$kb" "assets/likec4/index.png $msg" "unstaged changes: an exported PNG with unstaged changes blocks the commit, naming it"
  check "unstaged changes: the export puts that PNG back as it was" grep -q 'not a picture' "$kb/assets/likec4/index.png"
  git -C "$kb" checkout -q assets/likec4/index.png

  # Untracked files the Hooks would delete: a stray PNG, a file in .knowledgebase/.
  printf 'stray\n' >"$kb/assets/likec4/stray.png"
  commit_fails "$kb" "assets/likec4/stray.png $msg" "unstaged changes: an untracked PNG matching no view is refused, not deleted"
  check "unstaged changes: the untracked PNG is still there" test -f "$kb/assets/likec4/stray.png"
  rm "$kb/assets/likec4/stray.png"
  printf 'mine\n' >"$kb/.knowledgebase/notes.md"
  commit_fails "$kb" ".knowledgebase/notes.md $msg" "unstaged changes: an untracked file in .knowledgebase/ is refused, not deleted"
  rm "$kb/.knowledgebase/notes.md"
  out="$(cd "$kb" && git commit -m "docs: retitle the landscape" 2>&1)"
  check "unstaged changes: with everything staged, the same commit goes through" \
    test "$(git -C "$kb" log -1 --format=%s)" = "docs: retitle the landscape" || note "$out"
}

group_markdownlint() {
  local parent="$T/mdlint" out
  mkdir -p "$parent/docs"
  (cd "$parent" && git init -q)
  cp "${KB_TEST_MARKDOWNLINT_CONFIG:-/dev/null}" "$parent/.markdownlint-cli2.jsonc" 2>/dev/null
  [ -s "$parent/.markdownlint-cli2.jsonc" ] || printf '{ "config": { "default": true } }\n' >"$parent/.markdownlint-cli2.jsonc"
  printf '# Parent doc\n\nText.\n\n# Second H1\n- item\n' >"$parent/docs/parent.md"
  create "$parent/knowledge" -d likec4=false || {
    fail "markdownlint: create the knowledgebase" "$(cat "$T/last-copy.log")"
    return
  }
  overlay "$FW/tests/fixtures/pass" "$parent/knowledge"
  # Explicit paths, the way treefmt calls markdownlint-cli2.
  out="$(cd "$parent" && find . -name '*.md' -not -path './.git/*' | sort | xargs mise x "$NODE" npm:markdownlint-cli2@0.23.1 -- markdownlint-cli2 2>&1)"
  note "$(printf '%s\n' "$out" | strip_colors | grep -E 'Linting|Summary|MD[0-9]{3}' | head -8)"
  check "markdownlint: still lints the parent's own Markdown" bash -c "printf '%s' \"\$1\" | grep -q 'docs/parent.md:.*MD025'" _ "$out"
  check "markdownlint: skips everything in the knowledgebase" bash -c "! printf '%s' \"\$1\" | grep -q 'knowledge/.*MD[0-9]'" _ "$out"
  # Control: without the knowledgebase's opt-out, the same run flags its documents.
  rm "$parent/knowledge/.markdownlint.jsonc"
  out="$(cd "$parent" && find . -name '*.md' -not -path './.git/*' | sort | xargs mise x "$NODE" npm:markdownlint-cli2@0.23.1 -- markdownlint-cli2 2>&1)"
  note "$(printf '%s\n' "$out" | strip_colors | grep -E 'Summary|knowledge/.*MD[0-9]{3}' | head -3)"
  check "markdownlint: without the opt-out, the same run flags the knowledgebase's documents" \
    bash -c "printf '%s' \"\$1\" | grep -q 'knowledge/docs/.*MD[0-9]'" _ "$out"
}

group_likec4() {
  local kb="$T/likec4" out tmp
  [ -d "$T/root-likec4-true" ] || create "$T/root-likec4-true" -d likec4=true
  cp -R "$T/root-likec4-true" "$kb"
  # Deliberately unformatted: the commit must format it.
  cat >"$kb/assets/likec4/journeys.c4" <<'EOF'
views {
      dynamic view checkout {
    title 'Checkout, as a sequence'
          variant sequence
    customer -> saas.ui 'opens in browser'
       saas.ui -> saas.backend 'fetches via HTTPS'
  }
  dynamic view checkout-boxes {
    title 'Checkout, as boxes'
    customer -> saas.ui 'opens in browser'
    saas.ui -> saas.backend 'fetches via HTTPS'
  }
}
EOF
  cp "$kb/assets/likec4/journeys.c4" "$T/journeys.unformatted"
  out="$(cd "$kb" && git add -A && git commit -m "docs: add checkout views" 2>&1)"
  note "$(printf '%s\n' "$out" | strip_colors | grep -E '✔️|✘|seconds\)' | head -4)"
  check "likec4: a .c4 change commits through the Hooks" test "$(git -C "$kb" log -1 --format=%s)" = "docs: add checkout views"
  check "likec4: the commit formatted the .c4 file" \
    bash -c "! cmp -s '$T/journeys.unformatted' '$kb/assets/likec4/journeys.c4' && cd '$kb' && mise x '$NODE' npm:likec4@1.59.4 -- likec4 format --check assets/likec4 >/dev/null 2>&1"
  check "likec4: both views exported next to their sources and committed" \
    bash -c "git -C '$kb' cat-file -e HEAD:assets/likec4/checkout.png && git -C '$kb' cat-file -e HEAD:assets/likec4/checkout-boxes.png && [ -z \"\$(git -C '$kb' status --porcelain)\" ]"
  tmp="$T/likec4-reference"
  (cd "$kb" && mise x "$NODE" npm:likec4@1.59.4 -- likec4 export png --flat -o "$tmp/seq" --seq -f checkout -f checkout-boxes assets/likec4 >/dev/null 2>&1 &&
    mise x "$NODE" npm:likec4@1.59.4 -- likec4 export png --flat -o "$tmp/box" -f checkout -f checkout-boxes assets/likec4 >/dev/null 2>&1)
  check "likec4: the view declared variant sequence exported as a sequence diagram" \
    bash -c "cmp -s '$kb/assets/likec4/checkout.png' '$tmp/seq/checkout.png' && ! cmp -s '$kb/assets/likec4/checkout.png' '$tmp/box/checkout.png'"
  check "likec4: the view without a variant exported as a box diagram" \
    bash -c "cmp -s '$kb/assets/likec4/checkout-boxes.png' '$tmp/box/checkout-boxes.png' && ! cmp -s '$kb/assets/likec4/checkout-boxes.png' '$tmp/seq/checkout-boxes.png'"
  check "likec4: lefthook run kb-diagrams re-exports and changes nothing" \
    bash -c "cd '$kb' && lefthook run kb-diagrams >/dev/null 2>&1 && [ -z \"\$(git status --porcelain)\" ]"

  # A deleted view's PNG goes with it; pictures in images/ stay.
  mkdir -p "$kb/assets/likec4/images"
  cp "$kb/assets/likec4/index.png" "$kb/assets/likec4/images/logo.png"
  awk '/dynamic view checkout-boxes/ {skip = 1} !skip {print} skip && /^  }/ {skip = 0}' \
    "$kb/assets/likec4/journeys.c4" >"$T/journeys.c4" && cp "$T/journeys.c4" "$kb/assets/likec4/journeys.c4"
  out="$(cd "$kb" && git add -A && git commit -m "docs: drop the box view" 2>&1)"
  check "likec4: a deleted view's PNG is deleted in the same commit" \
    bash -c "[ \"\$(git -C '$kb' log -1 --format=%s)\" = 'docs: drop the box view' ] && ! git -C '$kb' cat-file -e HEAD:assets/likec4/checkout-boxes.png 2>/dev/null &&
      [ ! -e '$kb/assets/likec4/checkout-boxes.png' ] && [ -z \"\$(git -C '$kb' status --porcelain)\" ]" || note "$out"
  check "likec4: PNGs in images/ are left alone" git -C "$kb" cat-file -e HEAD:assets/likec4/images/logo.png

  # No node on PATH and no global mise config: the Hooks bring their own node.
  rm "$kb/assets/likec4/index.png"
  out="$(cd "$kb" && bare bash -c '! command -v node >/dev/null && lefthook run kb-diagrams' 2>&1)"
  check "likec4: kb-diagrams runs with no node on PATH" \
    bash -c "[ -f '$kb/assets/likec4/index.png' ] && [ -z \"\$(git -C '$kb' status --porcelain)\" ]" || note "$out"
}

group_reference() {
  local headings contents
  headings="$(awk '/^```/ {fence = !fence} !fence && /^## / {sub(/^## /, ""); print}' "$FW/managed/knowledgebase/reference.md")"
  contents="$(sed -n 's/^- \[\(.*\)\](#.*)$/\1/p' "$FW/managed/knowledgebase/reference.md")"
  check "reference.md: its contents list names every section, in order" test "$headings" = "$contents"
  check "reference.md: every contents link points at its section's anchor" \
    bash -c "sed -n 's/^- \\[\\(.*\\)\\](#\\(.*\\))$/\\1|\\2/p' '$FW/managed/knowledgebase/reference.md' |
      while IFS='|' read -r t a; do [ \"\$(printf '%s' \"\$t\" | tr 'A-Z ' 'a-z-')\" = \"\$a\" ] || exit 1; done"
}

group_notices() {
  local kb="$T/notices" out
  [ -d "$T/root-likec4-false" ] || create "$T/root-likec4-false" -d likec4=false
  cp -R "$T/root-likec4-false" "$kb"
  printf '9.0.0\n' >"$(git -C "$kb" rev-parse --path-format=absolute --git-common-dir)/info/lefthook-remotes/knowledgebase-framework-$HOOKS_REF/hooks/shell-version"
  printf 'note\n' >"$kb/assets/note.txt"
  out="$(cd "$kb" && git add -A && git commit -m "docs: a note" 2>&1)"
  note "$(printf '%s\n' "$out" | strip_colors | grep 'predates')"
  check "notices: once the Hooks expect a newer Shell, a commit announces copier update and still goes through" \
    bash -c "printf '%s' \"\$1\" | grep -q 'its Shell ($NEW_TAG) predates v9.0.0. Run .copier update --trust -a .copier-answers.knowledgebase.yml. in it' && [ \"\$(git -C '$kb' log -1 --format=%s)\" = 'docs: a note' ]" _ "$out"
}

ALL_GROUPS="syntax reference creation embedded fixtures update fail-closed managed unstaged markdownlint likec4 notices"
setup_world
# shellcheck disable=SC2048,SC2086 # group names never contain spaces
for g in ${*:-$ALL_GROUPS}; do
  printf '# %s\n' "$g"
  "group_$(printf '%s' "$g" | tr - _)"
done
# shellcheck disable=SC2153 # PASSED and FAILED are set by lib.sh
printf '\n%d passed, %d failed\n' "$PASSED" "$FAILED"
[ "$FAILED" -eq 0 ]
