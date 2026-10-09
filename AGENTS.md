# Knowledgebase Framework

This repository packages the Knowledgebase Framework: the Shell that Copier renders into each
knowledgebase, and the Hooks that each knowledgebase fetches from the `v1` branch at commit time.
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
  carry no `mise.toml`.
- **The Shell names the real Hooks URL.** Tests redirect it with git's `insteadOf`, never with a
  template answer.
- **Keep the template's local-section text stable.** `copier update` merges template changes into
  text the knowledgebase owns, and a change next to a local edit conflicts.
- **Anything that would fail an existing document is a new major** (ADR-0004), shipped with a
  Migration file where content needs converting (ADR-0010).
- **Never move `v1` by hand.** `.github/workflows/major-branch.yml` fast-forwards it on each
  release; a merged fix ships to every knowledgebase within 24 hours.
- **Agent-facing text** (`managed/agents-block.md`, `managed/knowledgebase/*.md`) must earn every
  line (ADR-0007). Apply the writing-for-agents skill when editing it.

## Checking a change

Run `bash tests/run.sh`; a change is done when every test passes. A new rule gets a must-fail
fixture in `tests/fixtures/fail/<name>/` with an `expect` file naming the steps that enforce it and
a message they report.
