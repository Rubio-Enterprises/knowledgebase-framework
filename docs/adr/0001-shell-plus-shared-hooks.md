---
status: accepted
---

# Deliver the framework as a one-time Shell plus shared Hooks

A knowledgebase receives the framework in two parts. The Shell is written once by Copier. The
Hooks are the commit-time checks, schema and pinned tools, fetched from the framework repository at
a pinned version through lefthook `remotes`. The rules and checks change far more often than the
files around them. A knowledgebase that is never pushed can't receive template-update pull
requests, so fetching the Hooks keeps every knowledgebase on the same rules without visiting each
one. This applies the same rule as standards ADR-0003: render only what can't be resolved remotely.

## Consequences

- Knowledgebases carry no `mise.toml`. The Hooks pin every tool in their own commands, so a
  version change ships with the logic that needs it, and there is no config to trust.

## Considered Options

- **Copy everything with a Copier template**: every rule fix needs `copier update` in every
  knowledgebase, and copies of the schema drift apart.
- **A dedicated CLI that installs and upgrades the framework** (the Spec Kit / Agent OS model): we
  would own an installer and an upgrader, re-implementing what Copier already does.
