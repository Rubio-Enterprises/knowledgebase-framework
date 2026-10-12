---
status: accepted
---

# Retired documents are deleted; `status: deprecated` is gone

A knowledgebase exists to give an accurate picture of how things are now. A document that no longer
holds is therefore deleted: anything in it that still holds moves to its replacement first, every
link to it is repointed at the replacement (or removed), and `docs/log.md` records it as `Retired`,
naming the replacement. `status` keeps `draft` and `stable`; `deprecated` is removed from the
schema. A new pipeline step fails any commit that leaves a link to a missing document, so a
deletion can't leave a dangling link behind.

v1 kept a deprecated stub whenever something replaced the document, so that links never broke. In
practice an agent can't see the links that point in from outside the knowledgebase, so it kept
every stub, and a stub can carry stale findings into the index, into search and into answers.
Every other reason to keep one is already served elsewhere:

- **Redirecting links**: links inside the knowledgebase are repointed and checked. A reader who
  follows an outside link to a missing file finds the replacement in the `Retired` log line.
- **History, audit, or reviewing a deletion before it lands**: git history and pull requests.
- **A system being phased out**: that is current truth, written in a `stable` document.
- **Knowledge known to be stale with nothing better yet**: fix what's wrong or delete it; an open
  question is a `draft` or a Plan.
- **Superseded Decisions**: the new Decision names what it replaced. Its predecessor's reasoning
  stays in git history.

## Consequences

- Removing a vocabulary value fails existing documents, so this ships as v2 (ADR-0004) with
  `MIGRATION-2.0.0.md` (ADR-0010), which retires each deprecated document and fixes broken links.
- okf reports broken links only as information, and it also lists links to source snapshots, which
  aren't concept documents. The `links` step fails only on links whose target file doesn't exist.
- Links from `docs/log.md` aren't checked, so `Retired` lines may name deleted files.

## Considered Options

- **Keep the stub only when the owner knows of outside links**, enforcing stub shape and no
  internal links to it: a judgement no agent can make, so in practice it would keep every stub.
- **Keep `deprecated` for superseded Decisions only**: keeps documents that describe a past state,
  which the knowledgebase isn't for.
