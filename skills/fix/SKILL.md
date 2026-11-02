---
name: fix
description: Lightweight track for a small bug — diagnose root cause → pick the right tech-expert skill for the affected stack → failing test → minimal fix via that expert → verify for real → a review step sized to the fix when non-trivial. No ADR and no human review gate; a short OpenSpec change only when the fix is non-trivial. Auto-escalates to /make-plan if the "small bug" turns out to need design/cross-cutting changes. Use for bugs and small defects, NOT new features. Triggers on "fix", "/fix", "bug", "fix the bug", "broken", "throwing", "not working".
---

# fix — fast track for a small bug

For a small bug, the full spec pipeline (`/make-plan` → review → `/implement-specs`) is overkill. This skill is the lightweight lane: find the root cause, fix it minimally **using the right domain expert**, verify, done — no ADR, no human review gate, and an OpenSpec change only when the fix is non-trivial (Step 1b). It still picks an expert (a bug in NestJS deserves `nestjs-expert`, a slow query deserves `postgres-pro`) so the fix is done well, not just quickly.

## Step 0 — Scope gate (decide the lane fast)
- **Trivial** (typo, one-liner, obvious mistake) → just fix it directly, skip the ceremony below.
- **Genuine bug** (something is broken / wrong behavior) → continue with this skill.
- **Not actually a bug** — needs a design decision, touches many modules, changes a contract, or is really a feature → **STOP, route to `/make-plan`.** Don't fix-and-hope your way through a design change.

## Step 1 — Diagnose (root cause, not symptom)
Reproduce and locate the actual cause before touching code. Use the `diagnose` skill: reproduce → minimise → hypothesise → confirm the faulty line/flow. Don't patch the symptom while the cause lives on.

## Step 1b — Spec, when the fix is non-trivial
A fix that touches more than one file or involves a judgement call gets a short OpenSpec change before code (`/opsx:propose`): the proposal states the bug and its root cause, one delta-spec requirement whose GIVEN / WHEN / THEN scenario is the reproduction and the correct behaviour. It is the audit trail of what was wrong and what was decided. A trivial or single-file, no-judgement fix skips this.

## Step 2 — Pick the expert for the fix (lightweight)
If `task-analyzer` already dispatched here, reuse its essence/type/scale/tags. Otherwise run its §3 Size (essence, type, scale, tags & experts) on the bug (the faulty code + symptom) now. Map that — plus the stack of the faulty code (file type, framework, layer — from the file itself + host CLAUDE.md / package.json) — to **one primary expert** that actually exists in this environment, plus at most **one supporting** expert if the bug spans two areas. State the pick in one line. Never name an unavailable skill.
- NestJS / API / DI bug → `fullstack-dev-skills:nestjs-expert`
- Next.js / RSC / route bug → `fullstack-dev-skills:nextjs-developer` (or `:react-expert` for component/render bugs)
- Slow / wrong SQL, migration, index → `fullstack-dev-skills:postgres-pro` (or `:database-optimizer`)
- Type error / generics / inference → `fullstack-dev-skills:typescript-pro`
- Gnarly runtime/stack-trace mystery → `fullstack-dev-skills:debugging-wizard`
- Failing/missing test → `fullstack-dev-skills:test-master`
Apply the expert by **loading its Skill into context via the Skill tool** (default), or for a trickier fix dispatch a **`general-purpose` agent** (`Agent` tool) and tell it to load that expert Skill itself — note `subagent_type` only accepts a real agent type, never a Skill name.

## Step 3 — Failing test, then minimal fix
First turn the reproduction into a failing test at the public interface (or the closest the project allows) and watch it fail for the right reason; expected values come from the bug report or the spec scenario, never recomputed the way the code computes them. Then make the **smallest diff** that fixes the root cause. Don't refactor surrounding code, don't add parallel structures, follow the host CLAUDE.md conventions. If the minimal fix turns out to be large or design-y → go back to Step 0 and escalate to `/make-plan`.

## Step 3b — Remove code the fix orphaned
A fix that replaces or bypasses old logic often leaves **dead code behind** — helpers nobody calls now, branches made unreachable, imports/constants/config reads with no consumer left (e.g. removing a special case orphans the two helpers that only it called and the config keys only they read — delete them in the same change). Don't leave that rot.
- From the diff, list what the fix **stopped calling / made unreachable / replaced**. For each suspect, `grep -rn` the whole repo for remaining references; **zero real consumers → dead → remove it**.
- **Scope to what THIS fix orphaned** — not a repo-wide dead-code hunt. A pre-existing unused symbol unrelated to the fix is out of scope (mention, don't delete).
- Cascade: each deletion can orphan more (an import, a constant only that fn read) — re-check until nothing new turns up.
- **Do NOT delete** symbols that are dynamically referenced (reflection, DI, decorators/registries, string dispatch, Odoo model/field names in XML/views, ORM columns), public/exported API, framework/lifecycle hooks, or anything in config/i18n/templates. When unsure it's dynamically used → **keep it and ask**, don't guess-delete.
- Behavior-preserving only: if removing something would change behavior, it wasn't dead.
- A value the fix makes always the same is not a field: when a flag, parameter or column becomes constant, remove it end to end (contract, producer, every consumer, docs, tests) instead of hard-coding it.

## Step 4 — Verify, in order
Run this checklist in order — fix red at any step before moving to the next. Cover more than the exact repro when it's cheap (a couple of related inputs/cases), not just the one failing example.

1. **E2e tests, if the touched area has any** — run them first. Fix red, re-run.
2. **Unit tests** — run the touched area's tests, including the Step 3 regression test, which must now pass (use `test-master` if helpful). Fix red, re-run.
3. **Backend/API bug — call the API directly.** Hit the endpoint yourself (curl/httpie/the project's API client) with the original repro input **and** a couple of nearby cases (boundary value, the other branch of whatever condition was wrong) — don't rely on the automated tests alone to prove the fix.
4. **UI-visible bug — prepare the walk.** Don't declare it fixed from code alone. Start the dev servers, set up the data, and write the throwaway `walk.mjs` (from the `ui-walkthrough` skill's template, kept outside the repo) that clicks the repro steps plus one neighbouring flow like a user — each write awaited (2xx) and read back over the API. Keep a `before` shot on the unfixed state when an A/B proof is worth it. Login wall with no documented test account → stop and ask the user; never type real credentials. **A trivial UI fix** (no Step 4b) runs the walk inline here with the `ui-walkthrough` skill and reads every screenshot itself; a **non-trivial** one hands the prepared `walk.mjs` to the `walkthrough-runner` agent in Step 4b, so the walk runs alongside the reviewers.

Never weaken, skip or delete a test, or silence a lint/type rule, to get green.

## Step 4b — Review step + walkthrough (non-trivial fixes)
Unless the fix was trivial (one file, no judgement call — the same line task-analyzer draws), launch the review step **sized to the fix** (protocol rule 5) **in one message** on the full diff of every repo touched — `diff-reviewer` always, `security-reviewer` on a security surface, `edge-case-reviewer` on a logic/state/boundary/failure surface, the full three for a high-risk surface (security, data/auth, a contract or API, unsafe code or a secret in a public repo, or an escalate path); give each the bug, the root cause, the base branch, every repo path and the OpenSpec change name if any. When the bug was UI-visible, launch the `walkthrough-runner` agent in the **same message** (the implementer prepared the `walk.mjs` in Step 4), so reading the screenshots does not block. Done needs each clean on the same frozen diff, the walkthrough's own verdict deciding. Fix every blocking finding, re-run only the reviewer whose domain the fix touched (the full set for a high-risk-surface change), and re-run the walkthrough when the fix touches a walked screen; a BLOCKED walk is an access problem, not a code fix. Skipping needs a written reason in the report.

## Step 4c — Open the draft PR
Once the checks are green, the walkthrough is reviewed and the reviewers passed (or the fix was trivial), run the `open-pr` skill: feature branch, one commit, push, draft PR with the root cause, the regression test, the checks run and the walkthrough screenshots. Never merge. A trivial fix the user wanted local, or no remote: stop at the local commit.

## Step 5 — Record only if non-obvious
If the root cause was **surprising / non-obvious** (a gotcha future-you would re-discover the hard way), write ONE short `project` memory note (cause + why + the fix), dedupe against existing notes, add the `MEMORY.md` pointer. For a routine bug, **skip** — don't spam memory.

## Step 6 — Report
One tight summary: bug → root cause → expert used → the fix (file:line) → dead code removed (symbols the fix orphaned, file:line) + any candidates kept and why → verification result (for a UI bug, the walkthrough's screenshots and review lines) → reviewer verdicts → draft PR link → (memory note, if written).

## Guardrails
- Bugs only. New behavior/feature work belongs to `/make-plan`.
- Root cause over symptom; minimal diff over rewrite.
- Escalate honestly the moment scope exceeds a bug fix — never silently turn a fix into an unscoped redesign.
