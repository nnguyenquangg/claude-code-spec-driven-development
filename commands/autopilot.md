---
name: "autopilot"
description: Full-auto — plan + build end to end with no human gate. Self-reviews specs with an AI gate, logs every assumption, builds via spec-loop, archives, records memory, hands back one review packet. Does NOT commit.
category: Workflow
tags: [workflow, openspec, autonomous, hands-off]
---

Invoke the **autopilot** skill — fuse `/make-plan` and `/implement-specs` into one hands-off run for when the user is busy and wants the whole thing done.

Goal: $ARGUMENTS

Follow the `autopilot` SKILL.md: rate clarity → plan (propose specs + ADRs, resolve open decisions with sensible low-risk defaults and **log every assumption**, pick experts) → **AI review gate** (an independent sub-agent sanity-checks the specs/ADRs in place of the human gate; apply fixes) → build via `spec-loop` through the experts → quality gate → `/opsx:archive` → record memory → hand back ONE review packet (goal, ⚠️ assumptions to confirm, specs satisfied, experts, files changed, quality results, memory note). **Never commit or push** — leave changes in the working tree. Stop mid-run only for a true blocker.
