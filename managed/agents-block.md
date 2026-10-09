## Knowledgebase rules

This folder is a knowledgebase: settled knowledge within the scope above, kept as an OKF v0.2
bundle and checked at every commit by the Knowledgebase Framework's Hooks.

### Where things go

- **Concept document** (one Markdown file doing one job) → `docs/<subject>.md`, flat. The filename
  is the subject alone, in kebab-case.
- **Source snapshot** (the original file a document transcribes, kept because tools can't fetch
  the live copy) → next to its document, as `docs/<document-name>.<ext>`.
- **Asset** (a file documents embed or link that isn't a document: diagram sources and renders,
  images, exports) → `assets/`.
- **Anything not meant to last** → `.scratch/`, which git ignores.
- **A subject a related knowledgebase covers more narrowly** → that knowledgebase, under its own
  `AGENTS.md`. Every document goes to the narrowest knowledgebase whose scope covers it.

### Frontmatter

Every concept document opens with this frontmatter; the Hooks enforce it.

- `type`: the document's Diátaxis mode: `How-to guide`, `Reference`, `Explanation` or `Tutorial`.
  One mode per document.
- `genre`: where the knowledge came from or what it is for: `Research` (external sources),
  `Investigation` (our own systems, code and data), `Runbook` (operating a live environment),
  `Plan` (an open proposal or question), `Decision` (a recorded choice and its reasons) or `Map`
  (architecture written to communicate).
- `title`: identical to the H1.
- `description`: one sentence.
- `tags`: kebab-case subject tags; the mode lives in `type` alone.
- `status`: `draft`, `stable` or `deprecated`.
- `work_item` (optional): one quoted Markdown link to the parent issue or spec the document was
  written for, e.g. `"[owner/repo#123](https://github.com/owner/repo/issues/123)"`.
- `generated`: `{by: <actor>, at: "<ISO-8601 instant>"}`. The actor is whoever produced the text:
  - an AI agent records itself as `<producer>/<version>`, its harness and model, e.g.
    `pi/claude-opus-4-5`;
  - a program that isn't an AI agent records `process:<id>`;
  - a person records `human:<id>`, and only that person writes it.
- `verified`: written only by the person who reviewed the document.
- `sources`: the external sources it cites (see `.knowledgebase/reference.md`).

Dates, status and authorship live in the frontmatter alone; the body starts at the H1.

### Before you start

- **Creating a document** → read `.knowledgebase/blueprints.md` and start from your genre's
  Blueprint.
- **Citing a source, keeping a source snapshot, splitting, merging, settling or retiring a
  document, or touching a diagram** → read the matching section of `.knowledgebase/reference.md`.

### Recording changes

After adding, splitting, merging, settling or retiring a document, add one line to `docs/log.md`
under today's `## YYYY-MM-DD` heading (newest date first), e.g.
`* **Added**: [Title](file.md), what it covers.` Use `Added`, `Updated` or `Retired`.

### Generated files

The Hooks rewrite `docs/index.md`, this managed block, everything in `.knowledgebase/` and the
PNGs exported from `assets/likec4/` at every commit. Change their sources instead.

### Checking your work

Run `lefthook run kb-check`: it runs every check a commit runs. The work is done when it passes.
