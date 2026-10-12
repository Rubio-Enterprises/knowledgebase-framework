# Reference

Rules for rarer work in a knowledgebase. Read the section that matches the task in hand:

- [Citing sources](#citing-sources)
- [Source snapshots](#source-snapshots)
- [Splitting and merging documents](#splitting-and-merging-documents)
- [Settling a Plan](#settling-a-plan)
- [Retiring a document](#retiring-a-document)
- [Diagrams](#diagrams)
- [LikeC4](#likec4)

## Citing sources

External material a document relies on (a repository, a file at a commit, a wiki page, a chat
thread, a pull request) is an OKF `sources` entry, cited with a footnote at the claim it supports.
The Hooks check that every footnote matches a `sources` entry and every entry is cited.

```yaml
sources:
  - id: order-router                  # kebab-case; the footnote label
    resource: https://github.com/example-org/example-service/blob/<sha>/src/OrderRouter.java
    title: "example-service OrderRouter: routes each order to processor v1 or v2"
    last_modified: "2025-12-29T16:07:12+01:00"   # when the source changed, not the document
    author: human:colleague                      # optional; for a message or page with one author
```

```markdown
The `RoutingTable` config routes each order, defaulting to v1.[^order-router]

## Sources

[^order-router]: example-service [`OrderRouter.chooseProcessor`](https://…) at `abc1234`.
```

- **Cite only what repays the reader's time**: the full inventory behind a summary, the reasoning
  behind a decision, the code that implements a rule, the discussion that settled a question. In
  Research and Investigations a citation is the evidence for a claim: keep it while the claim
  stands, and where several sources back one claim keep the strongest one or two. A source that
  repeats what the document already says gets no entry.
- **One entry per source.** Cite the same `id` again wherever another claim rests on it.
- **The footnote says what to look at there** and carries the link, so the rendered document stays
  clickable. Keep it to one line.
- **Pin what can move**: files and trees at a commit SHA from the remote default branch, never a
  branch name or a local checkout; chat messages by permalink.
- **Cite code by file path and class or method name**, never by line number.
- **These aren't sources**: links between documents in the knowledgebase (ordinary relative
  links), the work item (the `work_item` field), repositories named in passing (a backticked name),
  and infrastructure identifiers (code spans, never links). Links a reader opens to carry out a
  step, such as a form or a console, stay inline, as do the entries of a directory.
- **End with a `Sources` heading** directly above the footnote definitions, numbered if the
  document numbers its sections.

## Source snapshots

A source snapshot is the original file of a source that a document transcribes (a workbook behind
a sign-in, an emailed attachment), kept because tools can't fetch the live copy.

- **Name it after the document it backs**, keeping the original extension:
  `docs/<document-name>.<ext>`, or `docs/<document-name>-<part>.<ext>` when there are several. A
  file no document transcribes doesn't belong in the knowledgebase.
- **The document carries the content.** The validator, the index, search and agents read
  Markdown, so every fact also appears in the document.
- **Cite the live location** as the `sources` entry; its footnote also links the snapshot. `okf`
  reports that link as `info`, which is expected.
- **Refresh in place**: overwrite the snapshot, update the transcription and bump `generated.at`.
  Git keeps the earlier copies, so the filename carries no date.
- **Keep it small**: a few MB at most. Larger files belong outside the knowledgebase.

## Splitting and merging documents

A document does one Diátaxis job. Split a section written in another mode into its own document
only when it can stand alone: roughly 400 words or more, or linked from other documents. Keep a
short section that serves the parent's job (the rationale behind a procedure, a runbook's traps, a
decision's migration steps, open questions) in the parent. Link the new document from the parent,
merge fragments that only their parent links to back into it, and record either change in
`docs/log.md`.

## Settling a Plan

When a Plan's question is answered, settle it in place: keep the filename, change `genre` (usually
to `Investigation` or `Decision`), set `status: stable`, change `type` if its job changed, and
rewrite the body to the new genre's Blueprint. Links to it keep working.

## Retiring a document

Delete a document once it no longer describes how things are; update one that is only partly out
of date instead. Before deleting, move any fact that still holds into the document that replaces it.
Then:

1. Point every link to it at its replacement, or remove the link when nothing replaces it. The
   Hooks fail a commit that leaves a link to a missing document.
2. Record it in `docs/log.md`:
   `* **Retired**: old-name.md, replaced by [New title](new-name.md).`

Git history keeps the old text.

## Diagrams

A diagram's source and its exported images are assets, so they live in `assets/`, and documents
embed the images by relative path, e.g. `![Landscape](../assets/likec4/index.png)`. Change a
finding everywhere at once: update the document that states it and the diagram's model in the same
commit, including any prose that describes the diagram.

## LikeC4

The LikeC4 add-on keeps one LikeC4 project in `assets/likec4/`: `likec4.config.json` plus `.c4`
files with the specification, the model and the views. Each view exports to `<view-id>.png` next
to the `.c4` file that defines it. Pictures the model embeds, such as icons, go in its `images/`
folder.

- **Exports are automatic.** Any commit that changes a `.c4` file formats and validates the model,
  re-exports every view and deletes the PNG of any view that no longer exists. `lefthook run
  kb-diagrams` does the same on demand.
- **A dynamic view exports as a sequence diagram** when it declares `variant sequence`, and as a
  box diagram otherwise.
- **Check a view's content in its computed JSON**, not by eyeballing a large PNG:
  `mise x node@24.21.0 npm:likec4@1.59.4 -- likec4 export json -o /tmp/model.json assets/likec4`,
  then read `.[0].views["<view-id>"].nodes` and `.edges` with `jq`.
- **Browse the views live** with `mise x node@24.21.0 npm:likec4@1.59.4 -- likec4 serve assets/likec4`.
