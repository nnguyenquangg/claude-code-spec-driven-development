---
name: "my-goal"
description: Phase 1 (Plan & Specify) — turn a goal into reviewable specs + ADRs, then stop for review. Does not write code; hand off to /implement-specs once approved.
category: Workflow
tags: [workflow, openspec, planning, specs, adr]
---

Invoke the **my-goal** skill — Phase 1 of the spec-driven pipeline: planning only.

Goal: $ARGUMENTS

Follow the `my-goal` SKILL.md: resume-check → rate clarity (🟢/🟡/🔴) and announce the lane → clarify (grill-me/explore as the lane requires) → `/opsx:propose` (proposal + design + delta specs + tasks) → write ADR(s) for the significant decisions → analyze the task and **recommend** (record, don't run) the tech-expert skills for implementation → **STOP and present the review package**. Do NOT write production code. Close by telling the user to run `/implement-specs` once the specs + ADRs are approved.

If no goal is given, behave like `/what-now` (show pipeline status + menu) instead.
