---
status: accepted
---

# One always-loaded AGENTS.md, two on-demand files, nothing else for agents

Agents in a knowledgebase read three framework files, no more:

- `AGENTS.md`, with a `CLAUDE.md` symlink, is the only file loaded every session. The
  knowledgebase's local section states its scope and related knowledgebases. The managed block
  holds what every kind of work needs: where things go, the frontmatter contract, files never
  edited by hand, the check command, log entries, and pointers to the two files below.
- `.knowledgebase/blueprints.md` gives one example structure per genre. Agents read it only when
  creating a document.
- `.knowledgebase/reference.md` covers rarer work: citing sources, source snapshots, splitting,
  settling and retiring documents, and LikeC4.

The source skeleton's `docs/knowledge-layout.md` and `CONTEXT.md` are not carried into
knowledgebases:

- The layout doc's rationale and history serve framework maintainers, so they live in the
  framework repository. Its rules move into the files above.
- `AGENTS.md` defines each term where it uses it. A knowledgebase that needs a glossary of its
  subject keeps one as a Reference document in `docs/`.

## Why

- A study of repository context files (arXiv 2602.11988, 2026) found they don't raise task
  success and add more than 20% to cost. Agents follow their instructions, but repository
  overviews don't help.
- Anthropic's guidance keeps always-loaded instruction files short, leaves out history and long
  explanations, and puts knowledge that is only sometimes needed in files loaded on demand.
- Our writing-for-agents rule: inline what every branch of the work needs, and put the rest behind
  a pointer.

## Considered Options

- **Keep `CONTEXT.md`** (the domain-modeling convention): it would repeat the definitions that
  `AGENTS.md` already gives where the terms are used.
- **Keep the layout doc as a concept document**: puts framework rationale into every bundle and
  in front of agents that don't need it.
- **Everything in `AGENTS.md`**: blueprints and rare-branch rules would load every session.
- **A skill for creating and finding knowledgebases**: a pointer line in the workspace's
  `AGENTS.md` does the same job without a plugin, a marketplace, or an always-loaded
  description. Creating a knowledgebase is one Copier command, documented in the framework's
  README.
