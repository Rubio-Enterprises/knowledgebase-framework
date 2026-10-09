---
status: accepted
---

# The framework knows nothing about standards; a facet only wires the Hooks

A knowledgebase must work in any GitHub org, or in none, without Rubio-Enterprises standards. Each
knowledgebase therefore handles the one standards conflict it can solve itself. Its root carries a
`.markdownlint.jsonc` containing `{ "default": false }`, so markdownlint-cli2 skips and never
fixes anything under it. Every other Markdown file in the repository keeps full coverage. This
was verified with standards' config, passing explicit file paths the way standards' treefmt does.

The other conflict needs standards' cooperation. Standards generates the whole `lefthook.yml`,
and lefthook replaces the `remotes` list from `lefthook-local.yml` instead of merging it. A
standards facet, `has_knowledgebase`, solves it by adding the Hooks remote and the fail-closed
check to standards' generated stub. The facet ships with framework v1, and the framework never
references standards. The facet says *has*, not *is*, because a repository can contain a
knowledgebase without being one (ADR-0008).

## Considered Options

- **Fix each org knowledgebase by hand**: `lefthook-local.yml` would repeat standards' remotes and
  drift whenever standards' stub changes.
- **The facet lists knowledgebase paths and excludes them from markdownlint**: needs a path answer
  per knowledgebase. The knowledgebase's own opt-out works in any repository.
- **A "layered on standards" Copier answer in the framework**: couples the framework to one org.
