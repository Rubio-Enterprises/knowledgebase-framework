---
status: accepted
date: 2026-10-09
---

# Keep the framework independent of standards

## Context and Problem Statement

Knowledgebases must work without Rubio-Enterprises standards, whether standalone or embedded, but a containing repository may already lint Markdown and manage hooks. Where should integration with those repository-wide tools belong?

## Considered Options

- Standards-independent framework: each knowledgebase owns its Markdown lint opt-out; the containing repository wires the Hooks.
- Hand-maintained lefthook-local configuration: rejected because its remotes replace rather than merge the host's list, duplicating configuration that can drift.
- Host integration listing knowledgebase paths for Markdown exclusions: rejected because it requires a path answer for every knowledgebase.
- A framework Copier answer for layering on standards: rejected because it couples the framework to one organization.

## Decision Outcome

Chosen option: "Standards-independent framework", because knowledgebases can work outside the organization without duplicating their paths in host configuration.

## Consequences

- Good, because a knowledgebase can use the framework without adopting organization standards.
- Good, because its own Markdown lint opt-out leaves the containing repository's other Markdown covered.
- Bad, because an embedding repository must integrate the Hooks in its own hook configuration.
