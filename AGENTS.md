# Agent context

## Commands

Run every project command through `just`, which runs it in this repository's dev image; the host carries no project toolchain.

In a fresh checkout: `just build`, then `just setup`. `just --list` shows the recipes.

Run a test subset with `just test fixtures likec4`; reports go to `reports/test/`.

## Project shape

This repository packages the Knowledgebase Framework: the Shell that Copier renders into each
knowledgebase, and the Hooks that each knowledgebase fetches from the major branch (`v2`) at commit
time.
`README.md` maps the files; `CONTEXT-MAP.md` holds the vocabulary, used exactly; `docs/adr/` holds
the decisions.

## Invariants

- **Managed text has one source**: `managed/`. The Shell's setup task and the Hooks both copy from
  it, and the template includes `managed/markers.txt`. Text that depends on Copier answers belongs
  in the template's local sections, never in `managed/`.
- **Scripts run on bash 3.2** (macOS `/bin/bash`): no associative arrays, `mapfile`, `${var,,}`, or
  empty-array expansion under `set -u`. Steps return failures explicitly, because `set -e` is off
  inside functions called from `if` or `||`.
- **Tools are pinned in `hooks/knowledgebase.sh`** and reached through `mise x`. Knowledgebases
  carry no `image/mise.toml`.
- **The Hooks reach a repository two ways.** Commits fetch them through `remotes` in its own
  `lefthook.yml`: lefthook ignores `remotes` in an extended file. `standards check` (`just check`
  and CI) runs the copy baked into the standards base image, which takes a release only when
  standards merges Renovate's bump. The standards package's `knowledgebase hooks` Check and its
  initializer name the `v2` ref, so a new major also needs a standards release.
- **The Shell names the real Hooks URL.** Tests redirect it with git's `insteadOf`, never with a
  template answer.
- **Keep the template's local-section text stable.** `copier update` merges template changes into
  text the knowledgebase owns, and a change next to a local edit conflicts.
- **Anything that would fail an existing document is a new major** (ADR-0004), shipped with a
  Migration file where content needs converting.
- **Never move a major branch by hand.** `.github/workflows/release.yml` fast-forwards it on
  each release; a merged fix reaches every knowledgebase's commits within 24 hours. Only a new
  major's branch is created by hand (README, Versions).
- **Agent-facing text** (`managed/agents-block.md`, `managed/knowledgebase/*.md`) must earn every
  line. Apply the writing-for-agents skill when editing it.
- **Architecture decisions**: an ADR records why a rule exists. Before changing a decision, check
  `docs/adr/` for an accepted ADR; reversing one needs a superseding ADR. Write one only if a
  person approved it: in the session, or in an approved plan or `spec:agent` issue that
  names the ADR. Otherwise the PR description is the record. Follow
  [the format](docs/adr/0001-record-architecture-decisions.md), which states the ADR test.

## Checking a change

Run `just check` (the standards Checks) and `just test` (the suite in `tests/run.sh` plus its
JUnit report); a change is done when both pass. A new rule gets a must-fail
fixture in `tests/fixtures/fail/<name>/` with an `expect` file naming the steps that enforce it and
a message they report.
