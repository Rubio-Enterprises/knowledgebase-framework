---
status: accepted
---

# Agents record themselves; only people write `human:` actors

A document's `generated.by` names whoever actually produced it, using OKF's actor convention. An AI
agent writes itself as `<producer>/<version>`. A program that isn't an AI agent writes
`process:<id>`. A `human:<id>` actor, whether in `generated.by` or in a `verified` entry, is written
only by that person. The framework never gives agents the owner's id: Copier doesn't ask for it,
and no managed text contains it. Without the id, an agent can't claim a human author or record a
review that never happened. The source skeleton wrote `human:author` on every document, including
the agent-written ones, so OKF's trust tiers couldn't tell agent work from human work.

## Considered Options

- **Store the owner's id in each knowledgebase**: agents could then sign as the person, which is
  the failure this decision prevents.
