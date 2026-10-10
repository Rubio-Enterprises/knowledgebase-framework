---
status: accepted
---

# Knowledgebases follow the Hooks through a floating major ref

Each knowledgebase's `lefthook.yml` points at the Hooks through a floating major ref (`v1`) and
re-fetches it every 24 hours. Fixes and additions therefore reach every knowledgebase within a
day, with no visit to each one. A change that would make existing documents fail is a new major
version: a renamed or removed vocabulary value, a new required field, or a stricter check with no
auto-fix. It ships as a new ref (`v2`) with a Copier release whose version-gated `_migrations`
switch the ref and, where content must be converted, leave a Migration file (ADR-0010), all in one
`copier update` per knowledgebase. The floating Hooks never require a migration.

## Consequences

- `v1` is a branch, not a tag, so it never competes with the release tags Copier reads for
  `copier update`. Each v1.x release moves it forward: `.github/workflows/major-branch.yml`
  fast-forwards it to the release's tag and never forces the push. Org rulesets protect only the
  default branch, so moving it needs no bypass.
- The Hooks announce any update that needs `copier update`, such as a new major or a Shell change
  they can't make themselves. They print a notice on each knowledgebase's next commit, so there is
  no inventory or polling.
- Lefthook skips remote config it can't fetch: with nothing cached, it installs no hook and
  commits go through unchecked. The `lefthook.yml` that Copier writes therefore carries one local
  check that blocks commits until the Hooks are cached. Once they are cached, offline commits
  work normally.

## Considered Options

- **Standards-style `stable` and `canary` channels**: promotion needs a ring of test
  knowledgebases, which doesn't exist.
- **An exact tag per knowledgebase**: nothing spreads until each knowledgebase is updated by hand.
