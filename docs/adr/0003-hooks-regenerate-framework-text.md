---
status: accepted
date: 2026-10-09
---

# Hooks keep framework-owned text current at commit time

## Context and Problem Statement

The Hooks refresh enforced rules independently of the Shell, so guidance refreshed only by Copier would drift from the checks. How can managed text stay aligned without requiring a manual update after every framework release?

## Considered Options

- Regenerate managed text through the Hooks at commit time.
- Refresh text only through Copier: rejected because updates are manual and required in every knowledgebase.
- Detect drift and block until a separate sync command runs: rejected because it adds a step after every framework release.

## Decision Outcome

Chosen option: "Regenerate managed text through the Hooks at commit time", because guidance and enforcement must follow the same framework rules without per-knowledgebase intervention.

## Consequences

- Good, because knowledgebases receive current guidance alongside current checks.
- Bad, because a commit can change framework-owned control documents its author did not edit.
- Bad, because managed text must be identical everywhere; text depending on Copier answers must stay in local sections.
