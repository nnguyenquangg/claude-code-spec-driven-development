---
name: "spec-loop"
description: Autonomously implement an OpenSpec change — implement → independent review vs finalized specs → fix → repeat until everything matches, no manual review between cycles
category: Workflow
tags: [workflow, openspec, autonomous, spec-driven]
---

Invoke the **spec-loop** skill to autonomously implement the OpenSpec change until the code matches every finalized spec, requirement, scenario, and task — with independent fresh-context review between cycles and no stopping for manual review.

Change name (optional): $ARGUMENTS

Follow the `spec-loop` SKILL.md exactly: load finalized artifacts → implement → spawn an independent reviewer sub-agent that returns structured gaps → fix gaps → repeat (cap 6 iterations / 2 no-progress) → quality gate → report. Only stop on success, the safety cap, or a genuine spec ambiguity.
