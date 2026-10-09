---
status: accepted
---

# Content migrations ship as Migration files with a major version

Some framework changes need a knowledgebase's content converted, such as replacing LikeC4 with
draw.io. Such a change ships only as a new major version, never through the floating Hooks. Its
Copier release carries a version-gated migration step that leaves `MIGRATION-<version>.md` in each
knowledgebase that runs `copier update` across it. The file holds the conversion steps for an agent
to follow. It ends with a checkable done-test and an instruction to delete itself.

Visibility needs nothing new:

- Copier's `_message_after_update` tells whoever ran the update to have an agent complete the file.
- The new major's Hooks name the file whenever they hit content that hasn't been converted yet.

## Consequences

- One file per crossed major, so a knowledgebase that skips versions gets each in order.
- Copier leaves the update uncommitted. The conversion happens in the same working tree and is
  committed once, because the new major's Hooks already apply.
- Deterministic parts, such as renaming a frontmatter key, can run as a script in the same Copier
  step. The file covers what needs judgement.
- `AGENTS.md` carries no pointer to Migration files, which only exist for a short time.

## Considered Options

- **A conditional pointer in `AGENTS.md` to managed migration notes, shown while old content
  remains**: reaches every knowledgebase without `copier update`, but needs a detection check per
  migration and conditional managed text.
- **A deprecation window with commit-time notices**: the Hooks would carry old and new paths at
  once, and the notices arrive late in an agent's task.
