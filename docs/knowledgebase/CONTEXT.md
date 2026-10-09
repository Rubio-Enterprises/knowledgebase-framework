# Knowledgebase

The organizing language of a knowledgebase built on the Knowledgebase Framework.

## Language

**Knowledgebase**:
A folder of settled knowledge built on the Knowledgebase Framework and marked by its Copier answers
file: either a whole git repository or a folder inside one.
_Avoid_: Knowledge repo, workshop, scratch

**Scope**:
The subjects a knowledgebase covers, stated in its own control documents.
_Avoid_: Tier, zone

**Related knowledgebase**:
Another knowledgebase whose scope overlaps or nests with this one's, named with its path and scope
so that each document goes to the narrowest knowledgebase whose scope covers it.
_Avoid_: Parent tier, sibling repo

**Bundle**:
An OKF v0.2 folder of concept documents validated as a unit: a knowledgebase's `docs/`. Flat unless
content demands structure.
_Avoid_: Zone, quadrant folder

**Concept document**:
One Markdown file with OKF frontmatter, doing one Diátaxis job.
_Avoid_: Note, page

**Source snapshot**:
The original file (`.xlsx`, `.pdf`, …) of a source that a concept document transcribes, kept next to
it under the same name because tools cannot fetch the live copy. Never the only copy of a fact.
_Avoid_: Attachment, artifact, raw file

**Asset**:
A file that a concept document embeds or links but that is not itself a document, such as a
diagram's source or render, an image or an export. Kept in the knowledgebase's `assets/` folder,
outside the bundle.
_Avoid_: Artifact, attachment, media

**Actor**:
Who produced or verified a document, written in OKF's actor convention: `human:<id>` for a person,
`process:<id>` for a program that isn't an AI agent, `<producer>/<version>` for other software,
including AI agents.
_Avoid_: Author, owner

**Work item**:
The one issue or spec, in any tracker, that a concept document was written for: its parent, never
every item that mentions it. Optional.
_Avoid_: Ticket, task

**Control document**:
A file that governs a knowledgebase rather than describing a subject: `README.md`, `AGENTS.md` and
the framework's files under `.knowledgebase/`. Never inside a bundle, and never outside the
knowledgebase it governs.
_Avoid_: Concept document

**Genre**:
The `genre` extension key of a document, named for where its knowledge came from or what it is for:
Research, Investigation, Runbook, Plan, Decision, Map.
_Avoid_: Category, kind

**Research**:
Knowledge gathered from external sources: vendors, best practice, public documentation.
_Avoid_: Investigation

**Investigation**:
Knowledge gathered by digging into our own systems, code and data; settled findings about how they
actually behave.
_Avoid_: Research, reference

**Runbook**:
Step-by-step procedure for reaching or operating a live environment.
_Avoid_: Explainer, inventory

**Plan**:
A proposal or open question awaiting a decision. Draft until it settles in place.
_Avoid_: Spec, ticket

**Decision**:
A recorded choice and the reasons for it.
_Avoid_: ADR file, plan

**Map**:
Cross-system architecture written to communicate how things fit together, usually with diagrams.
_Avoid_: Overview dump, inventory

**Diátaxis mode**:
The OKF `type` of a document: How-to guide, Reference, Explanation or Tutorial. Decides its shape,
its title and its heading in the generated `index.md`.
_Avoid_: Genre, folder

**Settling in place**:
Changing a Plan's `genre` and `status` (and `type` if its job changed) once its question is
answered, keeping the filename.
_Avoid_: Graduating, moving to reference

**Scratch folder**:
A knowledgebase's hidden `.scratch/` folder, for anything not meant to become a permanent or
semi-permanent document or asset.
_Avoid_: Scratch repo, workbench, drafts
