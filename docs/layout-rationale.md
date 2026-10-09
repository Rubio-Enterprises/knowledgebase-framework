# Why a knowledgebase is laid out the way it is

The rules every knowledgebase follows live in its managed text: the managed block of `AGENTS.md`
and the files under `.knowledgebase/`. This document keeps the reasons behind them, for the people
who change the framework. It started as the source skeleton's `docs/knowledge-layout.md`; the
framework's own decisions are in [`adr/`](adr/).

## Documents are OKF concept documents in one flat bundle

Every document is an Open Knowledge Format v0.2 concept: Markdown with YAML frontmatter. OKF was
chosen because it is the only standard that puts type, lifecycle, freshness and provenance in
per-document frontmatter, it stays plain Markdown, and it has CLI tooling (validate, lint, format,
index). It is young (v0.2, 2026), so the layout uses spec fields plus two extension keys, `genre`
and `work_item`, which the spec allows and the framework's schema enforces.

The bundle is `docs/`, not the knowledgebase root, because the validator can't exclude files and
the root holds control documents. The bundle is flat on purpose: classification lives in
frontmatter, not in folders. The skeleton once had a `maps/` bundle; it was merged into `docs/`
because a folder per genre classifies by folder, and `genre: Map` already says it.

Files that aren't documents, such as diagram sources and their renders, sit in `assets/`, outside
the bundle, so the validator and index never see them. Documents embed or link them by relative
path. A flat bundle has no folder to scope an `AGENTS.md` to, so instructions for a subset of
documents become a How-to guide linked from those documents.

## The Diátaxis mode is OKF's `type`

- `type` is the Diátaxis mode: How-to guide, Reference, Explanation or Tutorial.
- `genre` says where the knowledge came from or what it is for: Research (external sources),
  Investigation (our own systems, code and data), Runbook (operating a live environment), Plan (an
  open proposal or question), Decision (a recorded choice and its reasons), Map (architecture
  written to communicate).

The mode is `type`, not a tag or an extension key, because `type` is the one field OKF requires and
the only one `okf index` groups by. Every generated `index.md` is therefore a Diátaxis landing page
without a folder per mode. In the skeleton, `type` once held the genre and the mode was the first
tag; it moved because a tag couldn't be enforced.

`okf validate` ignores extension keys and most field values, so `frontmatter.schema.json` enforces
the vocabularies, the required fields, the actor and instant formats, and no unknown keys.

## One mode per document, split only what stands alone

One document does one job. A whole section in a different mode is split into its own document and
linked, but only when it can stand alone: roughly 400 words or more, or linked from elsewhere. A
short section that serves the parent's job (the rationale behind a procedure, a runbook's traps, a
decision's migration steps, a document's open questions) stays in the parent. The threshold exists
because splits made without it left fragments of 100–350 words that only their parent linked to.

Diátaxis is applied from the inside, as its guidance prescribes: no folders per mode and no empty
structure. Improve one document at a time; structure follows.

## Plans settle in place

A Plan is `status: draft` while its question is open. When it settles, the same file changes
`genre`, `status` and, if its job changed, `type`, so links never break. Superseded documents get
`status: deprecated` and a link to their replacement.

## Filenames carry the subject only

Filenames lead with the subject in kebab-case, with no date prefix: the date lives in
`generated.at`, where a narrow file browser can't truncate it. They carry no ticket key either; the
work item is a frontmatter link (ADR-0005).

## Source snapshots pair a transcription with its original

A source snapshot is the original file of a source that a document transcribes, kept next to it
because tools can't fetch the live copy: a workbook behind a sign-in, an emailed attachment. A link
alone leaves an agent with a sign-in page, and a transcription alone can't be checked against what
the source said when it was copied; the pair gives both. The document carries the content, because
the validator, the index, search and agents read Markdown.

## Citations are OKF `sources` joined to footnotes

External material a document relies on is an OKF `sources` entry, cited with a footnote at the
claim it supports. That is OKF's own provenance mechanism, so its tools understand it, and each
entry records when the source last changed. `okf lint` reports a broken join only as a warning, or
not at all, so the Hooks enforce it with their own citations check. A `Sources` heading above the
footnote definitions exists because renderers put footnotes at the very end, after only a thin
rule; the managed preview stylesheet hides that rule under the heading.

## Agents record themselves

`generated.by` names whoever produced the document, in OKF's actor convention. The skeleton wrote
`human:author` on every document, so agent-written documents claimed a human author and OKF's trust
tiers couldn't tell agent work from human work (ADR-0009).
