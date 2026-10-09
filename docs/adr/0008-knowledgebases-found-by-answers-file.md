---
status: accepted
---

# A knowledgebase is any folder marked by its answers file, at a repository root or inside one

The Hooks find every knowledgebase in a repository by its `.copier-answers.knowledgebase.yml` and
run once per knowledgebase, on that folder only. A knowledgebase can therefore be a whole
repository or a folder inside a larger one, such as `parent-repo/knowledge/`. Several can share one
repository.

The Shell writes `lefthook.yml` only when the knowledgebase is the repository root, because that
file belongs to the repository. For an embedded knowledgebase, the parent repository wires the
Hooks once: through the standards facet (ADR-0006), or with the lines Copier prints for the
parent's own `lefthook.yml`.

## Consequences

- Pi loads `AGENTS.md` from its working directory and that directory's parents, never from
  subfolders. A repository or workspace containing a knowledgebase therefore needs one pointer line
  in its own `AGENTS.md`, naming the knowledgebase's `AGENTS.md`. Copier prints that line too.
- Every Hooks job takes a knowledgebase root rather than assuming the repository root.
