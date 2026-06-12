---
name: "implement-specs"
description: Phase 2 (Build) — after specs + ADRs are approved, implement the change via the recommended experts using spec-loop, quality-gate, archive, and record context
category: Workflow
tags: [workflow, openspec, implementation, spec-loop, autonomous]
---

Invoke the **implement-specs** skill — Phase 2 of the spec-driven pipeline. The invocation is the approval signal that the specs + ADRs from `/make-plan` are final.

Change name (optional): $ARGUMENTS

Follow the `implement-specs` SKILL.md: locate & load the finalized change (proposal + delta specs + tasks + ADRs + recommended experts) → confirm experts → run `spec-loop` implementing AS those experts (implement → independent review vs finalized specs + ADRs → fix → repeat, cap 6) → quality gate → `/opsx:archive` → auto-record the non-obvious logic + why to the project memory → report. Honor the ADRs; if one proves wrong, stop and send the user back to `/make-plan`. If no finalized change exists, tell the user to run `/make-plan` first.
