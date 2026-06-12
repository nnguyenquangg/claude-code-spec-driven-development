---
name: fix
description: Lightweight track for a small bug — diagnose root cause → pick the right tech-expert skill for the affected stack → minimal fix via that expert → verify. No specs, no ADR, no review gate. Auto-escalates to /make-plan if the "small bug" turns out to need design/cross-cutting changes. Use for bugs and small defects, NOT new features. Triggers on "fix", "/fix", "bug", "fix the bug", "broken", "throwing", "not working".
---

# fix — fast track for a small bug

For a small bug, the full spec pipeline (`/make-plan` → review → `/implement-specs`) is overkill. This skill is the lightweight lane: find the root cause, fix it minimally **using the right domain expert**, verify, done — no OpenSpec change, no ADR, no review gate. It still picks an expert (a bug in NestJS deserves `nestjs-expert`, a slow query deserves `postgres-pro`) so the fix is done well, not just quickly.

## Step 0 — Scope gate (decide the lane fast)
- **Trivial** (typo, one-liner, obvious mistake) → just fix it directly, skip the ceremony below.
- **Genuine bug** (something is broken / wrong behavior) → continue with this skill.
- **Not actually a bug** — needs a design decision, touches many modules, changes a contract, or is really a feature → **STOP, route to `/make-plan`.** Don't fix-and-hope your way through a design change.

## Step 1 — Diagnose (root cause, not symptom)
Reproduce and locate the actual cause before touching code. Use the `diagnose` skill (or `dev-workflows:investigator` for a murky one): reproduce → minimise → hypothesise → confirm the faulty line/flow. Don't patch the symptom while the cause lives on.

## Step 2 — Pick the expert for the fix (lightweight)
Identify the stack of the faulty code (file type, framework, layer — from the file itself + host CLAUDE.md / package.json), then pick **one primary expert** that actually exists in this environment, plus at most **one supporting** expert if the bug spans two areas. State the pick in one line. Never name an unavailable skill.
- NestJS / API / DI bug → `fullstack-dev-skills:nestjs-expert`
- Next.js / RSC / route bug → `fullstack-dev-skills:nextjs-developer` (or `:react-expert` for component/render bugs)
- Slow / wrong SQL, migration, index → `fullstack-dev-skills:postgres-pro` (or `:database-optimizer`)
- Type error / generics / inference → `fullstack-dev-skills:typescript-pro`
- Gnarly runtime/stack-trace mystery → `fullstack-dev-skills:debugging-wizard`
- Failing/missing test → `fullstack-dev-skills:test-master`
Apply the expert either by loading its guidance into context (default) or, for a trickier fix, delegating to it as a sub-agent (`Agent`, `subagent_type`).

## Step 3 — Minimal fix
Make the **smallest diff** that fixes the root cause. Don't refactor surrounding code, don't add parallel structures, follow the host CLAUDE.md conventions. If the minimal fix turns out to be large or design-y → go back to Step 0 and escalate to `/make-plan`.

## Step 4 — Verify
- The original repro no longer reproduces.
- Lint/build the touched area (respect host CLAUDE.md — e.g. don't run `tsc`/`prisma` yourself in this workspace; leave to the user/CI).
- Add a cheap regression test if one is quick and the bug warrants it (use `test-master` if helpful).

## Step 5 — Record only if non-obvious
If the root cause was **surprising / non-obvious** (a gotcha future-you would re-discover the hard way), write ONE short `project` memory note (cause + why + the fix), dedupe against existing notes, add the `MEMORY.md` pointer. For a routine bug, **skip** — don't spam memory.

## Step 6 — Report
One tight summary: bug → root cause → expert used → the fix (file:line) → verification result → (memory note, if written).

## Guardrails
- Bugs only. New behavior/feature work belongs to `/make-plan`.
- Root cause over symptom; minimal diff over rewrite.
- Escalate honestly the moment scope exceeds a bug fix — never silently turn a fix into an unscoped redesign.
