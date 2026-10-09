---
status: accepted
---

# Hooks keep framework-owned text current at commit time

The Hooks regenerate all framework-owned text in a knowledgebase on every commit, the same way they
already regenerate `index.md`. That covers the managed blocks in `README.md` and `AGENTS.md`, and
the managed files under `.knowledgebase/` (see ADR-0007). Without this, the rules a knowledgebase
enforces (refreshed by the Hooks) and the rules it documents (refreshed only by `copier update`)
would drift apart. Managed text is therefore identical in every knowledgebase. Anything that
depends on Copier answers lives in the knowledgebase's local sections.

## Consequences

- After a framework release, a commit can change control documents its author didn't touch.
- The VS Code preview support is present in every knowledgebase. Its stylesheet,
  `.knowledgebase/markdown-preview.css`, is a managed file kept current by the Hooks. The two
  settings entries that point VS Code at it (`markdown.styles`, and the footnotes extension in
  `extensions.json`) never change. Copier therefore writes them once, at creation and on
  `copier update`, into the repository root's `.vscode/`, leaving other settings alone. Nothing
  outside a knowledgebase changes at commit time.
- Generated images follow the same rule. In a knowledgebase with the LikeC4 add-on, any commit
  that changes `.c4` files validates and formats the model and re-exports its PNGs, so images
  never fall behind the model. That needs a headless Chromium on every machine that commits.
- PNGs are exported next to their sources, LikeC4's default. The export runs in two passes,
  because likec4 1.59.4's PNG export ignores a dynamic view's declared `variant sequence`. It
  first exports every view, then re-exports the views that LikeC4's JSON export reports as
  sequences with `--seq`. Drop the second pass once a LikeC4 release honours the variant.
- The layout changes only through a framework release. A knowledgebase's own history goes in its
  `log.md`.

## Considered Options

- **Copier writes the text and `copier update` refreshes it**: manual, per knowledgebase.
- **The Hooks detect drift and block the commit until a sync command runs**: explicit, but adds a
  step after every framework release.
