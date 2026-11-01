---
name: "fix"
description: Lightweight bug track — diagnose root cause → pick the right tech-expert → failing test → minimal fix → verify for real → three reviewers when non-trivial. No ADR, no human gate. Auto-escalates to /make-plan if it's bigger than a bug.
category: Workflow
tags: [workflow, bug, fix, debugging, lightweight]
---

Invoke the **fix** skill — the lightweight lane for a small bug (not a feature).

Bug: $ARGUMENTS

Follow the `fix` SKILL.md: scope-gate (trivial → just do it; real bug → continue; needs design / cross-cutting / a contract change → STOP and route to `/make-plan`) → diagnose root cause (`diagnose` skill) → pick the right expert for the affected stack via `task-analyzer` (primary + ≤1 supporting, from skills available here) → short OpenSpec change if the fix is non-trivial → failing test → minimal fix via that expert, removing what it orphaned → verify in order (e2e tests if any → unit tests → API calls for a backend bug → `ui-walkthrough` for a UI bug, screenshots read before calling it fixed) → three reviewers in parallel when non-trivial → `open-pr` (draft PR with the evidence, never merged) → record to memory only if the root cause was non-obvious → report. No ADR, no human review gate.
