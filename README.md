# Knowledgebase Framework

The conventions, checks and agent guidance that every knowledgebase is built on. A knowledgebase is
a folder of settled knowledge, kept as an [OKF v0.2](https://github.com/GoogleCloudPlatform/open-knowledge-format)
bundle and typed by [Diátaxis](https://diataxis.fr) mode and genre. It can be a whole git
repository or a folder inside one.

The framework reaches a knowledgebase in two parts (ADR-0001):

- **The Shell**: the files Copier writes when the knowledgebase is created and refreshes on
  `copier update`.
- **The Hooks**: the commit-time checks, schema and managed text, which every knowledgebase fetches
  through lefthook from this repository's `v1` branch.

Vocabulary: [`CONTEXT-MAP.md`](CONTEXT-MAP.md). Decisions: [`docs/adr/`](docs/adr/). Why the
layout is what it is: [`docs/layout-rationale.md`](docs/layout-rationale.md).

## Requirements

- `git`, `mise`, `lefthook` and `copier` (9.15 or later) on your PATH. Nothing else: the Hooks
  fetch every tool they use through `mise x`, including the node that likec4 and Playwright run
  on.
- Read access to `Rubio-Enterprises/knowledgebase-framework` through your git credentials: lefthook
  fetches the Hooks over HTTPS.
- A network connection the first time. The Hooks download their pinned tools through `mise x` on
  first use (okf is compiled from source, which took 13 seconds on an M-series Mac), and the LikeC4 add-on
  downloads Playwright's headless Chromium.

## Create a knowledgebase

```sh
copier copy --trust gh:Rubio-Enterprises/knowledgebase-framework <folder>
```

Copier asks four questions: the name, the scope in one sentence, any related knowledgebases (one
per line as `<path>: <scope>`), and whether to add the LikeC4 add-on (default yes). `--trust` lets
its setup task run.

When `<folder>` isn't inside a git repository, the knowledgebase is a repository of its own. The
setup task runs `git init`, writes `lefthook.yml` (the Hooks remote plus a check that blocks
commits until the Hooks are fetched), installs the hooks, runs every check once to fetch the
tools, and makes the first commit. It also adds the preview stylesheet and the Markdown Footnotes
extension to `.vscode/`, and prints a line for the `AGENTS.md` of any workspace above the folder.

## Embed a knowledgebase in a repository

Run the same command with a `<folder>` inside an existing repository. The knowledgebase gets its
own control documents, but no `lefthook.yml` and no commit, because those belong to the
repository. Copier prints two things to add to the repository once:

1. The lefthook lines: the Hooks remote and the fail-closed check. A repository rendered by
   Rubio-Enterprises standards declares the `has_knowledgebase` facet instead.
2. A pointer line for the repository's `AGENTS.md`, because agents load `AGENTS.md` only from their
   working folder and its parents.

The VS Code entries go to the repository root's `.vscode/`, merged with what is there. One
repository can hold several knowledgebases; the Hooks find each by its
`.copier-answers.knowledgebase.yml` and check each on its own (ADR-0008).

A knowledgebase opts itself out of markdownlint with its own `.markdownlint.jsonc`, so a repository
that lints Markdown keeps linting everything else (ADR-0006).

## Work in a knowledgebase

- Agents read the knowledgebase's `AGENTS.md`, which points them at `.knowledgebase/blueprints.md`
  and `.knowledgebase/reference.md` when they need them (ADR-0007).
- `lefthook run kb-check` runs every check a commit runs.
- `lefthook run kb-diagrams` re-exports every LikeC4 view.

## Versions

- release-please tags each release `vX.Y.Z`; Copier creates and updates from those tags.
- The `v1` branch moves forward with every v1.x release. The Hooks follow it, so fixes reach every
  knowledgebase within 24 hours without anyone visiting it (ADR-0004).
- A change the Hooks can't make themselves needs `copier update`. Raise `hooks/shell-version` to
  the release that carries it, and every knowledgebase created from an older Shell prints a notice
  on its next commit. To update one, run this in its folder:

  ```sh
  copier update --trust -a .copier-answers.knowledgebase.yml
  ```

- A change that would make existing documents fail (a renamed or removed vocabulary value, a new
  required field, a stricter check with no auto-fix) is a new major. It ships as a `v2` branch and
  a Copier release whose version-gated `_migrations` switch the `lefthook.yml` ref and, where
  content needs converting, leave a `MIGRATION-<version>.md` for an agent (ADR-0010). Raising
  `hooks/shell-version` on the `v1` branch announces it.

## Develop the framework

| Path | What it is |
| --- | --- |
| `copier.yml`, `template/` | The Shell |
| `shell/` | The Shell's setup task and the `lefthook.yml` it writes or prints |
| `hooks/knowledgebase.yml`, `.lefthook/` | The Hooks' lefthook config and the scripts it runs |
| `hooks/knowledgebase.sh` | The pipeline, with every tool pinned |
| `hooks/shell-version` | The oldest Shell the Hooks are content with |
| `frontmatter.schema.json` | The frontmatter contract |
| `managed/` | The only source of all managed text |
| `tests/` | Fixtures and the end-to-end suite |

Run the tests with:

```sh
bash tests/run.sh
```

They take about two minutes, run offline once the pinned tools are cached, and run every script
on `/bin/bash`, so they also prove bash 3.2 compatibility. They copy the working tree into a
scratch folder as release `v1.99.0` on top of the last release (`v1.0.0`), serve the Hooks from a
local bare clone that git's `insteadOf` substitutes for the GitHub URL, and then create, commit,
break and update knowledgebases there. Pass group names to run a subset (`bash tests/run.sh
fixtures likec4`); `KB_TEST_VERBOSE=1` prints the evidence behind each result and
`KB_TEST_KEEP=1` keeps the scratch folder.
