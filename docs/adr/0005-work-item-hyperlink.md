---
status: accepted
---

# A document links at most one work item, as a Markdown hyperlink to any tracker

The source skeleton's `ticket` field accepted only Jira keys, and filenames ended with the key.
It is replaced by an optional `work_item` field. The field holds a single Markdown hyperlink to the
issue or spec the document was written for, in any tracker:
`[owner/repo#123](https://github.com/owner/repo/issues/123)` for GitHub, which guidance and examples
use by default, or `[PROJ-1234](https://<jira>/browse/PROJ-1234)` for Jira. The schema checks only
that the value is one hyperlink rather than a bare URL or a list. Linking only the parent item,
never every item that mentions the document, is written guidance, because a schema can't judge it.
Filenames no longer carry a ticket key.

## Consequences

- Frontmatter values are not clickable in rendered previews. VS Code's preview escapes them as
  plain text. The URL inside the link is still Cmd+clickable in the editor.
- Knowledgebases that adopt the framework with `ticket` keys need a one-time migration to
  `work_item` links.

## Considered Options

- **Keep the Jira-only `ticket` key**: a knowledgebase whose work lives in GitHub issues couldn't
  link its work items.
- **GitHub shorthand only**: leaves out the Jira-tracked knowledgebase the framework came from.
- **A bare URL**: nothing to read in the source before you follow it.
- **A clickable link line generated into the document body**: breaks the rule that metadata lives
  only in frontmatter.
