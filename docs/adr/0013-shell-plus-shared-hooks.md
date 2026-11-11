---
status: accepted
date: 2026-10-09
---

# Deliver the framework as a one-time Shell plus shared Hooks

## Context and Problem Statement

Rules and checks change more often than the files surrounding them, and knowledgebases that are never pushed cannot receive template-update pull requests. How can the framework deliver rule changes without visiting every knowledgebase?

## Considered Options

- Copier Shell plus shared Hooks: render local files with Copier and fetch checks, schema and pinned tools through lefthook.
- Copy everything with Copier: rejected because every rule fix requires updating every knowledgebase and copied schemas drift.
- Dedicated installation and upgrade CLI: rejected because it duplicates capabilities Copier already provides.

## Decision Outcome

Chosen option: "Copier Shell plus shared Hooks", because remotely resolved rules can change without a Shell update in every knowledgebase.

## Consequences

- Good, because rule fixes reach knowledgebases that are never pushed.
- Good, because tool pins travel with the checks that need them rather than in each knowledgebase's own mise configuration.
- Bad, because commits depend on fetched Hooks and their tools rather than only files kept inside the knowledgebase.
