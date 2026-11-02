---
name: "task-analyzer"
description: Front door for a raw task - sizes it up (essence, type, scale, tags), reads whether your wording means "just look" or "go do it", then either hands back the analysis or drives the right lane itself (direct / fix / make-plan / autopilot / research).
category: Workflow
tags: [workflow, analysis, routing, triage]
---

Invoke the **task-analyzer** skill: size up a task, then do exactly as much as asked.

Task: $ARGUMENTS

Follow the `task-analyzer` SKILL.md: read intent from the wording (look-only → analysis and stop; do or neither → do the work, never ask) → orient (in-flight OpenSpec change, project CLAUDE.md + memory, the code it touches) → size (essence, type, scale counted from files; multi-repo or contract changes are never small) → pick the lane → act: follow the lane's own SKILL.md end to end, write an OpenSpec change for anything non-trivial, run the review step sized to the change (and the `walkthrough-runner` agent in the same parallel message for a UI-visible change) before reporting done. If no task is given, behave like `/what-now` instead.
