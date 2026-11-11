---
status: accepted
date: 2026-10-09
---

# Knowledgebases follow the Hooks through a floating major ref

## Context and Problem Statement

Knowledgebases need rule fixes without individual visits, but automatically fetched checks must not invalidate existing documents. How can fixes spread unattended while content conversions remain explicit?

## Considered Options

- Floating major Hooks with explicit major migrations: compatible updates follow a major branch; incompatible changes require Copier updates and Migration files.
- Exact tag per knowledgebase: rejected because nothing spreads until each is updated manually.
- Stable and canary channels: rejected because there is no ring of test knowledgebases.
- Deprecation windows with commit-time migration notices: rejected because the Hooks would carry old and new paths, and notices arrive late in an agent's task.
- Conditional pointers to managed migration notes: rejected because each migration needs a detection check and conditional managed text.

## Decision Outcome

Chosen option: "Floating major Hooks with explicit major migrations", because compatible rules can spread automatically without making content conversion an unattended side effect.

## Consequences

- Good, because compatible fixes reach every knowledgebase within 24 hours without a visit.
- Bad, because changes that fail existing documents need a new major and a Copier update per knowledgebase; agents must complete each Migration file's done-test and delete it before committing.
- Bad, because first-time commits must wait for the Hooks to be fetched, although cached Hooks permit offline commits.
