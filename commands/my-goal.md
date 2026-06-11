---
name: "my-goal"
description: Orchestrate the full spec-driven pipeline for a goal — adaptively runs grill-me → /opsx:propose → spec-loop → /opsx:archive, with checkpoints chosen by task clarity
category: Workflow
tags: [workflow, openspec, orchestrator, spec-driven, autonomous]
---

Invoke the **my-goal** skill to drive the whole spec-driven pipeline for this goal.

Goal: $ARGUMENTS

Follow the `my-goal` SKILL.md: resume-check via `openspec list` → rate the goal's clarity (🟢/🟡/🔴) and announce the lane → clarify (grill-me/explore as the lane requires) → `/opsx:propose` → **analyze the task (`dev-workflows:task-analyzer`) and select the tech-expert skills to drive the coding** (discover from available skills; primary + ≤2 supporting) → checkpoint on specs + experts if the lane calls for one → `spec-loop` (implementing via the chosen experts) until specs match → `/opsx:archive` → **auto-record the non-obvious logic decisions to the project auto-memory (MEMORY.md) so other sessions don't re-read code** → report. Clear tasks run hands-off; fuzzy tasks get interrogated first. The user can override the lane or swap experts anytime.

If no goal is given, behave like `/what-now` (show pipeline status + menu) instead.
