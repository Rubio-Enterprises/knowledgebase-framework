# Knowledgebase Framework (knowledgebase-framework)

The conventions, checks and agent guidance that every knowledgebase is built on.

A knowledgebase is a folder of settled knowledge, kept as an [OKF v0.2](https://github.com/GoogleCloudPlatform/open-knowledge-format)
bundle and typed by [Diátaxis](https://diataxis.fr) mode and genre. It can be a whole git
repository or a folder inside one.

The framework reaches a knowledgebase in two parts (ADR-0013):

- **The Shell**: the files Copier writes when the knowledgebase is created and refreshes on
  `copier update`.
- **The Hooks**: the commit-time checks, schema and managed text, which every knowledgebase fetches
  through lefthook from this repository's major branch (`v2`).

Vocabulary: [`CONTEXT-MAP.md`](CONTEXT-MAP.md). Decisions: [`docs/adr/`](docs/adr/). Why the
layout is what it is: [`docs/layout-rationale.md`](docs/layout-rationale.md).

## Table of Contents

- [Install](#install)
- [Usage](#usage)
- [Versions](#versions)
- [Develop the framework](#develop-the-framework)
- [Contributing](#contributing)
- [License](#license)

## Install

### Dependencies

Every knowledgebase lives in a repository on `@rubio-enterprises/standards`, and its Hooks run in
that repository's dev image (ADR-0014).

- Docker with Compose, `just`, `git` and `copier` (9.15 or later) on your PATH, and access to the
  organization's base image.
- To create a knowledgebase as its own repository: `npm`, and a GitHub token that can read the
  organization's packages, from `NODE_AUTH_TOKEN` or `gh auth token`. The setup task runs the
  standards Initializer with it.
- No framework credential: Copier and lefthook fetch this public repository over HTTPS.
- A network connection the first time. `just build` compiles okf from source, and the Hooks
  download their other pinned tools through `mise x` on first use.

### Create a knowledgebase

```sh
copier copy --trust gh:Rubio-Enterprises/knowledgebase-framework <folder>
```

Copier asks four questions: the name, the scope in one sentence, any related knowledgebases (one
per line as `<path>: <scope>`), and whether to add the LikeC4 add-on (default yes). `--trust` lets
its setup task run.

When `<folder>` isn't inside a git repository, the knowledgebase is a repository of its own. The
setup task runs `git init`, then makes it a standards repository:

- It writes `image/mise.toml` with the tools the Hooks pin, then runs the standards Initializer,
  which lays down the Starter Files and locks those pins.
- It adds the Hooks remote to `lefthook.yml`, a C compiler to the `Dockerfile` (okf compiles from
  source), Exclusions for the framework's own files to `lefthook.override.yml`, and a line to
  `bin/setup.sh` that fetches the Hooks.
- It opens `AGENTS.md` with the agent context contract, adds Contributing and License sections to
  `README.md`, and writes an `UNLICENSED` `LICENSE` for you to replace.
- It adds the preview stylesheet and the Markdown Footnotes extension to `.vscode/`, stages
  everything, and prints a line for the `AGENTS.md` of any workspace above the folder.

Then build the image and make the first commit:

```sh
just build && just setup && just check
git add -A && git commit -m "chore: create knowledgebase"
```

With the LikeC4 add-on, also install Playwright's headless Chromium and its system libraries in
the `Dockerfile`; the setup task doesn't. Rubio-Enterprises/knowledge shows how.

### Embed a knowledgebase in a repository

Run the same command with a `<folder>` inside an existing standards repository. The knowledgebase
gets its own control documents, but no Starter Files and no commit, because those belong to the
repository. Copier prints what to add to the repository once:

1. The Hooks remote, for the repository's own `lefthook.yml`: lefthook fetches but never runs
   `remotes` declared in an extended file. The standards `knowledgebase hooks` Check fails until
   the remote is declared and fetched.
2. The tool pins for `image/mise.toml`, the compiler line for the `Dockerfile` and the Exclusions
   for `lefthook.override.yml`.
3. A pointer line for the repository's `AGENTS.md`, because agents load `AGENTS.md` only from their
   working folder and its parents.

The VS Code entries go to the repository root's `.vscode/`, merged with what is there. One
repository can hold several knowledgebases; the Hooks find each by its
`.copier-answers.knowledgebase.yml` and check each on its own.

A knowledgebase opts itself out of markdownlint with its own `.markdownlint.jsonc`, so the
repository keeps linting its other Markdown.

## Usage

A knowledgebase's `docs/adr/` holds the repository's own ADRs, not Knowledge documents; the Hooks
leave that folder out of formatting, validation, document inventories and generated indexes.
Knowledge documents may link to ADR files, and those links are still checked for missing targets.

Run the checks or re-export diagrams from a knowledgebase's repository:

```sh
just check
just exec lefthook run kb-diagrams
```

- Agents read the knowledgebase's `AGENTS.md`, which points them at `.knowledgebase/blueprints.md`
  and `.knowledgebase/reference.md` when they need them.
- `just check` runs every standards Check and every check the Hooks run at a commit.
- `just exec lefthook run kb-diagrams` re-exports every LikeC4 view.

## Versions

- release-please tags each release `vX.Y.Z`; Copier creates and updates from those tags.
- The major branch (`v2`) moves forward with every v2.x release:
  `.github/workflows/release.yml` fast-forwards it to the release's tag. The Hooks follow it, so fixes reach every knowledgebase
  within 24 hours without anyone visiting it (ADR-0004). The workflow never creates a new major's
  branch; that is created by hand, with its Migration file (ADR-0004).
- `standards check` (`just check` and CI) runs the Hooks baked into the standards base image, not
  the fetched ones. A release reaches that copy
  when standards merges the Renovate pull request that bumps it.
- A change the Hooks can't make themselves needs `copier update`. Raise `hooks/shell-version` to
  the release that carries it, and every knowledgebase created from an older Shell prints a notice
  on its next commit. To update one, run this in its folder:

  ```sh
  copier update --trust -a .copier-answers.knowledgebase.yml
  ```

- A change that would make existing documents fail (a renamed or removed vocabulary value, a new
  required field, a stricter check with no auto-fix) is a new major. Its `_migrations` entry in
  `copier.yml` runs `shell/migrate.sh`, which switches a root knowledgebase's `lefthook.yml` ref
  and leaves `shell/migrations/<version>.md` as `MIGRATION-<version>.md` for an agent
  (ADR-0004). To release it:
  1. Merge it with a `!` commit; release-please tags `vN.0.0`.
  2. Create the `vN` branch at that tag by hand, the one branch move made by hand.
  3. Announce it to the previous major: on a commit on top of its branch, raise
     `hooks/shell-version` to `N.0.0`, tag it as that major's next patch, push the tag, and run
     `release.yml` with it, which fast-forwards the branch.
  4. For embedded knowledgebases, release `@rubio-enterprises/standards` with the new ref in its
     `knowledgebase hooks` Check and initializer, then move the `ref` in each embedding
     repository's `lefthook.yml`.

## Develop the framework

| Path | What it is |
| --- | --- |
| `copier.yml`, `template/` | The Shell |
| `shell/` | The Shell's setup task and the text it adds to the standards Starter Files or prints |
| `hooks/knowledgebase.yml`, `.lefthook/` | The Hooks' lefthook config and the scripts it runs |
| `hooks/knowledgebase.sh` | The pipeline, with every tool pinned |
| `hooks/shell-version` | The oldest Shell the Hooks are content with |
| `frontmatter.schema.json` | The frontmatter contract |
| `managed/` | The only source of all managed text |
| `tests/` | Fixtures and the end-to-end suite |

With Docker, Compose, `just` and Git available, and access to the organization's base image:

```sh
just build
just setup   # dependencies, git hooks and the Hooks' pinned tools
just check   # every standards Check on every tracked file
just test    # tests/run.sh, with a JUnit report in reports/test/
```

The dev image supplies the standards Checks and installs this repository's tool pins from
`image/mise.toml`.

The suite runs offline once the pinned tools are cached: `just build` installs them, with a
Rust toolchain to build okf and Playwright's headless Chromium; `just setup` prepares the Hooks' tools. It runs scripts on `/bin/bash` on macOS,
so it checks bash 3.2 compatibility there. It copies the working tree into a
scratch folder as release `v2.99.0` on top of the newest v1 release in its history
(retagged `v1.0.0` for the test), serves the Hooks from a local bare clone that git's `insteadOf`
substitutes for the GitHub URL, and then creates, commits, breaks and updates
knowledgebases there. Pass group names to run a subset (`just test fixtures likec4`); `KB_TEST_VERBOSE=1` prints the evidence behind each result and
`KB_TEST_KEEP=1` keeps the scratch folder.

## Contributing

Ask questions in [repository issues](https://github.com/Rubio-Enterprises/knowledgebase-framework/issues)
and submit changes through pull requests.
Framework development and CI use the organization's base image as described above.
Follow the [organization PR template](https://github.com/Rubio-Enterprises/.github/blob/main/.github/PULL_REQUEST_TEMPLATE.md): use a
Conventional Commits title, link the work item, and complete What?, Why?, How?, and
Testing? (plus the template's relevant review and dependency sections). Keep the
body within 400 words and run the repository checks before requesting review, after the setup above.

```bash
just check
just test
```

See [AGENTS.md](AGENTS.md) for invariants and test-fixture requirements. `just test`
wraps `tests/run.sh`; this repository has no `typecheck` or `package` recipe.

## License

[MIT](LICENSE) — Copyright (c) 2026 Rubio Enterprises.
