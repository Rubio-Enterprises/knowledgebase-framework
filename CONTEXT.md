# Knowledgebase Framework

How a reusable set of knowledge conventions is packaged once and delivered to every knowledgebase
that adopts it.

## Language

**Knowledgebase Framework**:
The reusable package of conventions, checks and agent guidance that every knowledgebase is built
on.
_Avoid_: Standards, kit, template, skeleton

**Knowledgebase**:
A folder of settled knowledge built on the Knowledgebase Framework and marked by its Copier answers
file: either a whole git repository or a folder inside one.
_Avoid_: Knowledge repo, KB repo, vault

**Shell**:
The files Copier writes into a knowledgebase when it is created, and refreshes on
`copier update`.
_Avoid_: Scaffold, boilerplate, template output

**Hooks**:
The framework's shared commit-time checks, with the schema and pinned tools they use, which every
knowledgebase fetches from the framework at its major version.
_Avoid_: Engine, remote config, ruleset, gate

**Add-on**:
An optional part of the framework that a knowledgebase opts into when it is created, such as
LikeC4 diagrams.
_Avoid_: Module, plugin, extension

**Blueprint**:
The example structure for one genre's documents, so that agents give every document of that genre
the same basic shape.
_Avoid_: Template, skeleton, placeholder

**Managed block**:
Framework-owned text inside a knowledgebase's control document, set apart by markers and never
edited by hand.
_Avoid_: Generated section, template region

**Managed file**:
A file in a knowledgebase that the framework owns outright and the Hooks regenerate, such as the
Blueprints under `.knowledgebase/`.
_Avoid_: Generated file, vendored file

**Migration file**:
A `MIGRATION-<version>.md` that `copier update` leaves in a knowledgebase when it crosses a major
version needing content converted: steps for an agent to follow, ending in a done-test and the
file's own deletion.
_Avoid_: Upgrade notes, changelog

**Local section**:
The part of a control document outside its managed block, owned by the knowledgebase itself.
_Avoid_: Custom section, override
