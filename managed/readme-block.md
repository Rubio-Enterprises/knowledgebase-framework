## How this knowledgebase works

It is built on the Knowledgebase Framework: settled knowledge kept as an
[OKF v0.2](https://github.com/GoogleCloudPlatform/open-knowledge-format) bundle, each document
typed by its [Diátaxis](https://diataxis.fr) mode and its genre. Agents follow `AGENTS.md`.

### Layout

- `docs/`: the bundle. Every document sits here, flat, with any source snapshot next to it. Start
  at the generated `docs/index.md`; `docs/log.md` records changes, newest first. A document
  still being shaped is here too, with `status: draft`; working files that aren't knowledge live
  outside the knowledgebase.
- `assets/`: files the documents embed or link. With the LikeC4 add-on, `assets/likec4/` holds
  the model and the PNGs exported from it.
- `.knowledgebase/`: the framework's Blueprints, reference rules and preview stylesheet.
- `AGENTS.md` and `README.md`: control documents. A managed block like this one belongs to the
  framework; the rest belongs to this knowledgebase.

### Checks

Every commit runs the framework's Hooks. They refresh the framework's text, normalize frontmatter,
regenerate `docs/index.md`, validate and lint the bundle, check frontmatter and citations, and
re-export any LikeC4 diagrams that changed. Run the same checks any time with
`lefthook run kb-check`, and re-export every diagram with `lefthook run kb-diagrams`. You need
`git`, `lefthook` and `mise` on your PATH; the Hooks fetch their own pinned tools.

### Updates

The Hooks follow the framework's `v1` branch and pick up its changes within a day. When a commit
prints a notice that this knowledgebase needs `copier update`, run
`copier update --trust -a .copier-answers.knowledgebase.yml` in this folder, have an agent complete
any `MIGRATION-*.md` file it leaves, and commit once.

### Previewing in VS Code

Install the recommended Markdown Footnotes extension. The preview then uses
`.knowledgebase/markdown-preview.css`, which hides the raw `sources` row of the frontmatter table
and the footnote rule under a `Sources` heading.
