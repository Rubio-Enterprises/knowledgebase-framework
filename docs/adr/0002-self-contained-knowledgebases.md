---
status: accepted
---

# Knowledgebases are self-contained, and pushing is their own choice

Every knowledgebase carries its own control documents, whether it is a whole repository or a folder
inside one (ADR-0008). Whether it is pushed to a remote is decided per knowledgebase, not by the
framework. The framework can only create and update files inside a
knowledgebase's own repository. A pushed knowledgebase is also cloned without its parent folders.
Rules kept in an outside file would therefore drift from the framework, and go missing in a clone.
The source skeleton's Product A knowledgebase was governed from its parent folder's `AGENTS.md`
like this.

## Considered Options

- **A "bare" knowledgebase governed from a parent folder**: rejected, because the framework can't
  keep that file current and clones lose it.
- **A framework-wide local-only rule**, as in the source skeleton: rejected, because some
  knowledgebases are meant to be pushed. Audience rules, such as keeping infrastructure
  identifiers out of a pushed repository, belong to the knowledgebase that needs them.
