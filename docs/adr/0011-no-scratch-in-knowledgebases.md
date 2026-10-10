---
status: accepted
---

# Knowledgebases hold no scratch; unfinished knowledge is a draft

A knowledgebase holds only documents and assets. The Shell no longer creates a hidden `.scratch/`
folder, and the managed text no longer sends "anything not meant to last" into one. Knowledge that
is still being shaped is a concept document with `status: draft`: it sits in `docs/`, is checked
by the Hooks like any other, and becomes `stable` once it settles (Plans already worked this way).
Working files that aren't knowledge (data dumps, prototypes, notes on the way to a document) live
outside the knowledgebase, wherever the author keeps scratch. For an embedded knowledgebase that is
the host repository's own convention; for a workspace, its shared scratch folder.

The per-knowledgebase `.scratch/` duplicated the scratch space that already sits beside every
knowledgebase, so there were two folders with the same name and no rule for choosing between them.
It also hid unfinished knowledge from the index, from search and from the Hooks.

## Consequences

- An existing knowledgebase keeps its `.scratch/` folder and its `.gitignore` line until
  `copier update` removes them, or until someone deletes them by hand. Nothing in the Hooks reads
  the folder, so a leftover one is harmless. `hooks/shell-version` stays where it was, because no
  knowledgebase needs `copier update` for this.
- Drafts appear in the generated `docs/index.md`, with their status in their frontmatter.

## Considered Options

- **Keep `.scratch/` and add a rule for when to use it**: two folders with the same name stay, and
  agents still have to choose.
- **Link the knowledgebase's `.scratch/` to the workspace's**: one folder in practice, but a
  symlink inside a repository that git ignores only by name, and code spikes would appear to live
  in the knowledgebase.
