---
status: accepted
date: 2026-10-12
---

# Delete retired documents instead of keeping deprecated stubs

## Context and Problem Statement

Knowledgebases describe what holds now, but deprecated stubs can carry stale findings into the index, search and answers. Agents cannot know which documents have incoming links from outside a knowledgebase. How should a document that no longer holds be retired?

## Considered Options

- Delete retired documents after moving current facts and repointing internal links.
- Keep stubs when the owner knows of outside links: rejected because agents cannot make that judgement and would keep every stub.
- Keep deprecated documents for superseded Decisions only: rejected because they still describe a past state rather than current knowledge.

## Decision Outcome

Chosen option: "Delete retired documents after moving current facts and repointing internal links", because link redirection alone does not justify keeping stale knowledge in the live bundle.

## Consequences

- Good, because the index, search and answers no longer include retired documents.
- Good, because git history preserves old text and the Retired log entry names its replacement; the Hooks reject missing internal link targets.
- Bad, because external links can break; readers must find the replacement in the Retired log entry.
