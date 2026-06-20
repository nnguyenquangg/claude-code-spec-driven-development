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
Run **`dev-workflows:task-analyzer`** on the bug (the faulty code + symptom) to get its type/tags, then map that — plus the stack of the faulty code (file type, framework, layer — from the file itself + host CLAUDE.md / package.json) — to **one primary expert** that actually exists in this environment, plus at most **one supporting** expert if the bug spans two areas. State the pick in one line. Never name an unavailable skill.
- NestJS / API / DI bug → `fullstack-dev-skills:nestjs-expert`
- Next.js / RSC / route bug → `fullstack-dev-skills:nextjs-developer` (or `:react-expert` for component/render bugs)
- Slow / wrong SQL, migration, index → `fullstack-dev-skills:postgres-pro` (or `:database-optimizer`)
- Type error / generics / inference → `fullstack-dev-skills:typescript-pro`
- Gnarly runtime/stack-trace mystery → `fullstack-dev-skills:debugging-wizard`
- Failing/missing test → `fullstack-dev-skills:test-master`
Apply the expert by **loading its Skill into context via the Skill tool** (default), or for a trickier fix dispatch a **`general-purpose` agent** (`Agent` tool) and tell it to load that expert Skill itself — note `subagent_type` only accepts a real agent type, never a Skill name.

## Step 3 — Minimal fix
Make the **smallest diff** that fixes the root cause. Don't refactor surrounding code, don't add parallel structures, follow the host CLAUDE.md conventions. If the minimal fix turns out to be large or design-y → go back to Step 0 and escalate to `/make-plan`.

## Step 3b — Remove code the fix orphaned
A fix that replaces or bypasses old logic often leaves **dead code behind** — helpers nobody calls now, branches made unreachable, imports/constants/config reads with no consumer left (PR #206: removing the trial special-case orphaned `_is_free_trial_event`, `_has_any_trial_event`, and the `trial_preferred_floor`/`trial_service_ids` reads — deleted in the same PR). Don't leave that rot.
- From the diff, list what the fix **stopped calling / made unreachable / replaced**. For each suspect, `grep -rn` the whole repo for remaining references; **zero real consumers → dead → remove it**.
- **Scope to what THIS fix orphaned** — not a repo-wide dead-code hunt. A pre-existing unused symbol unrelated to the fix is out of scope (mention, don't delete).
- Cascade: each deletion can orphan more (an import, a constant only that fn read) — re-check until nothing new turns up.
- **Do NOT delete** symbols that are dynamically referenced (reflection, DI, decorators/registries, string dispatch, Odoo model/field names in XML/views, ORM columns), public/exported API, framework/lifecycle hooks, or anything in config/i18n/templates. When unsure it's dynamically used → **keep it and ask**, don't guess-delete.
- Behavior-preserving only: if removing something would change behavior, it wasn't dead.

## Step 4 — Verify
- The original repro no longer reproduces.
- Lint/build the touched area (respect host CLAUDE.md — e.g. don't run `tsc`/`prisma` yourself in this workspace; leave to the user/CI).
- Add a cheap regression test if one is quick and the bug warrants it (use `test-master` if helpful).
- **If the bug has a visible/interactive UI surface, reproduce it in the live app** — don't declare it fixed from code alone. The user keeps the app logged in in Arc; drive it via `~/.local/bin/browser-harness` (full path — `~/.local/bin` is NOT on the non-interactive `$PATH`). Confirm the exact repro steps now produce the correct behavior:
  ```bash
  ~/.local/bin/browser-harness <<'PY'
  new_tab("http://localhost:3000/<path-that-triggered-the-bug>")   # first nav = new_tab, never goto_url
  wait_for_load()
  # reproduce the bug's steps: read state with js("..."), act with click_at_xy() / js("el.click()")
  capture_screenshot("~/web-proofs/fix-<bug>/after.png", max_dim=1600)
  print(page_info())
  PY
  ```
  Read the screenshot back and confirm the symptom is gone. Capture a `before.png` first (on the unfixed state) when an A/B proof is worth keeping.
  - **React/Next.js inputs** (DynaTax): setting `el.value` does NOT update React state — use the native setter + dispatch `input`: `Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set.call(el, v); el.dispatchEvent(new Event('input',{bubbles:true}))`.
  - Login wall / logged-out → STOP and ask the user to log in; never type credentials.

## Step 5 — Record only if non-obvious
If the root cause was **surprising / non-obvious** (a gotcha future-you would re-discover the hard way), write ONE short `project` memory note (cause + why + the fix), dedupe against existing notes, add the `MEMORY.md` pointer. For a routine bug, **skip** — don't spam memory.

## Step 6 — Report
One tight summary: bug → root cause → expert used → the fix (file:line) → dead code removed (symbols the fix orphaned, file:line) + any candidates kept and why → verification result (for a UI bug, link the proof screenshot under `~/web-proofs/fix-<bug>/`) → (memory note, if written).

## Guardrails
- Bugs only. New behavior/feature work belongs to `/make-plan`.
- Root cause over symptom; minimal diff over rewrite.
- Escalate honestly the moment scope exceeds a bug fix — never silently turn a fix into an unscoped redesign.
