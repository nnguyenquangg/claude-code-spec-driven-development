---
name: "fix"
description: Lightweight bug track — diagnose root cause → pick the right tech-expert → minimal fix → verify. No specs/ADR/gate. Auto-escalates to /my-goal if it's bigger than a bug.
category: Workflow
tags: [workflow, bug, fix, debugging, lightweight]
---

Invoke the **fix** skill — the lightweight lane for a small bug (not a feature).

Bug: $ARGUMENTS

Follow the `fix` SKILL.md: scope-gate (trivial → just do it; real bug → continue; needs design / cross-cutting / a contract change → STOP and route to `/my-goal`) → diagnose root cause (use `diagnose` / `dev-workflows:investigator`) → pick the right expert for the affected stack (primary + ≤1 supporting, from skills available here) → minimal fix via that expert → verify (repro gone + lint/build touched area + cheap regression test) → record to memory only if the root cause was non-obvious → report. No OpenSpec change, no ADR, no review gate.
