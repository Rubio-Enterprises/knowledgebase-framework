# Blueprints

One Blueprint per genre: the shape every document of that genre starts from, so documents of one
genre read alike. Create the file as `docs/<subject>.md`, copy the shared frontmatter and your
genre's body, then replace every `<…>`. Drop a section only when it has nothing to say, and keep
the order of the rest.

## Shared frontmatter

```yaml
---
type: <the genre's mode, below>
genre: <Research | Investigation | Runbook | Plan | Decision | Map>
title: <identical to the H1>
description: <one sentence: what the document covers>
tags:
  - <subject-tag>
status: <stable, or draft while it's still being shaped (a Plan stays draft until it settles)>
work_item: "[<owner/repo#123>](<https://github.com/owner/repo/issues/123>)"  # optional
generated:
  by: <producer>/<version>
  at: "<YYYY-MM-DDTHH:MM:SSZ>"
sources:  # only when the body cites; see reference.md, Citing sources
  - id: <kebab-case-id>
    resource: <URL, pinned where it can move>
    title: <what the source is>
    last_modified: "<when the source last changed>"
---
```

Every body opens with the H1, then one paragraph that says what the document covers, unless the
genre's Blueprint starts with a Bottom line. A document that cites ends with a `Sources` heading
above its footnote definitions.

## Research

Mode `Explanation`; title `About <topic>`. Knowledge gathered from external sources.

```markdown
# About <topic>

## Bottom line

<The answer to the research question in two or three sentences, so a reader can stop here.>

## 1. The question and why it matters

## 2. What established practice says

<The consensus from vendors, standards and public write-ups, each claim cited.>

## 3. Options compared

| Option | Fits our constraints | Cost | Risk |
| --- | --- | --- | --- |

## 4. Recommendation

<The recommended option, tied back to section 2.>

## 5. Open questions

## 6. Sources
```

## Investigation

Mode `Reference` for settled findings, titled with a noun phrase (`<System> <behaviour>`); mode
`Explanation`, titled `About <topic>`, when the job is explaining why our system works as it does.
Knowledge gathered from our own systems, code and data.

```markdown
# <System> <behaviour>

<What the findings cover and how they were verified: in source, live, or both.>

## Bottom line

- <The most important finding.>

## 1. Inventory

| Item | Where it lives | Owner | Notes |
| --- | --- | --- | --- |

## 2. How it behaves

### 2.1 <Mechanism>

<A neutral description, citing code by file path and class or method name.>

## 3. Problems found

## 4. Open questions

## 5. Sources
```

## Runbook

Mode `How-to guide`; title `How to <goal>`. A procedure for reaching or operating a live
environment.

````markdown
# How to <goal>

<One sentence: what the procedure achieves, and in which environment.>

## Before you start

- <Access or tools required, and how to get them.>

## Steps

1. <Action.>

   ```sh
   <command>
   ```

2. <Action, and what you should see.>

## Verify

<How to confirm it worked.>

## Traps

- <A known gotcha and how to avoid it.>
````

## Plan

Mode `Explanation`; title `About <proposal>`; `status: draft` until it settles in place. A proposal
or open question awaiting a decision.

```markdown
# About <proposal>

<The proposal and the open question it waits on.>

## 1. The question

<What needs deciding, and by whom.>

## 2. Target state

| Area | Today | Target | Status |
| --- | --- | --- | --- |

## 3. Gaps between today and the target

## 4. Proposed steps

1. <Step, with a done-when check.>

## 5. Open questions
```

## Decision

Mode `Explanation`; title `About <choice>`. A recorded choice and the reasons for it.

```markdown
# About <choice>

<The choice in one sentence, and what it replaced.>

## 1. Context

<The forces at play: constraints, incidents, what was hurting.>

## 2. Decision

<The decision, stated plainly in the present tense.>

## 3. Alternatives considered

| Alternative | Why not |
| --- | --- |

## 4. Consequences

- <What becomes easier, and what becomes harder that we accept.>

## 5. Migration steps

## 6. Sources
```

## Map

Mode `Explanation`; title `About <systems>`. Cross-system architecture written to communicate,
usually around a diagram from `assets/`.

```markdown
# About <systems>

<What the map covers and who it is for.>

![<View title>](../assets/<path>.png)

## 1. Components

| Component | What it does | Main parts |
| --- | --- | --- |

## 2. Environments

## 3. How they connect

<The main flows, in prose that matches the diagram.>

## 4. Open questions

## 5. Sources
```
