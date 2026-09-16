---
name: "task-analyzer"
description: Front door for a raw task — sizes it up (essence, type, scale, tags), reads whether your wording means "just look" or "go do it", then either hands back the analysis or drives the right lane itself (trivial / fix / make-plan / autopilot). Self-contained, no dev-workflows dependency.
category: Workflow
tags: [workflow, analysis, routing, triage]
---

Invoke the **task-analyzer** skill — size up a task, then do exactly as much as asked.

Task: $ARGUMENTS

Follow the `task-analyzer` SKILL.md: read intent from the wording (exploratory → analyze-only; action → do the work; unclear → analyze then ask once) → understand the essence → classify type + estimate scale (grounded in the actual codebase) → pick the lane (trivial / `fix` / `make-plan` / `autopilot` / `research` first) → tag + recommend expert(s) from skills actually installed → act: analyze-only outputs the report and stops; do-mode reads the project CLAUDE.md + memory first, then follows the matched lane's own SKILL.md end-to-end (that lane's guardrails still apply in full, e.g. `make-plan` still stops for review). If no task is given, behave like `/what-now` instead.
