---
status: accepted
date: 2026-11-21
---

# Knowledgebases live in standards repositories

## Context and Problem Statement

ADR-0006 kept the framework usable without Rubio-Enterprises standards, so every knowledgebase had two ways to run its checks: `just check` in the dev image, or `lefthook run kb-check` with host tools. The organization keeps project tools off the host, and a knowledgebase repository outside the standards could not commit there. Should the host path stay?

## Considered Options

- Standards repositories only: every knowledgebase lives in a repository with the standards Starter Files, and its Hooks run in the dev image.
- Both paths, as in ADR-0006: rejected because the host path needs lefthook, mise and a compiler on every machine, and no knowledgebase uses the framework outside the organization.
- A container of the framework's own: rejected because it duplicates the standards dev image.

## Decision Outcome

Chosen option: "Standards repositories only", because one path keeps tools off the host and gives every knowledgebase the same commands.

## Consequences

- Good, because agents and people run `just check` everywhere and the managed text names one command.
- Bad, because the framework cannot be used outside the organization without the standards base image.
- Bad, because creating a root knowledgebase needs Docker, npm and access to the organization's packages.
