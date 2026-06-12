---
name: make-plan
description: PHASE 1 (Plan & Specify) of the spec-driven pipeline — takes a plain-language goal and produces reviewable specs + ADRs, then STOPS for human review. Does NOT write production code. Adaptive — how hard it interrogates the user depends on how clear the task is. Resume-aware. Hand off to /implement-specs once the specs/ADRs are approved. Triggers on "make-plan", "/make-plan", "plan this", "spec this out", "write the specs".
---

# make-plan — Phase 1: Plan & Specify (stops at review)

The user gives a goal in plain language. You turn it into **reviewable artifacts** — proposal, design, delta specs, tasks, and ADR(s) for the significant decisions — then **STOP and hand them to the user/reviewer**. You do **not** implement production code here; that is `/implement-specs` (Phase 2), which runs after the specs and ADRs are approved.

**How hard you interrogate depends on how clear the task is** — clear tasks get a light pass, fuzzy tasks get grilled. Always announce the lane and let the user override.

Sub-skills you compose (Skill tool or slash command):
- `grill-me` — interview the user to firm up an unclear plan
- `openspec-explore` / `/opsx:explore` — think through a fuzzy/large problem
- `openspec-propose` / `/opsx:propose` — generate proposal + design + delta specs + tasks
- `dev-workflows:task-analyzer` / `dev-workflows:technical-designer` — analyze the task and author ADRs

## Step 0 — Resume check (always first)
```bash
openspec list --json
```
- Change for this goal **exists with specs but not yet implemented** → it's already planned; tell the user to run `/implement-specs` (don't redo planning). Offer to revise the specs if they want.
- Change **in progress with code / partial tasks** → planning is done; point them to `/implement-specs` to continue.
- **Archived** → done; ask if this is a new follow-up goal.
- Otherwise → start fresh at Step 1.

## Step 1 — Assess clarity, pick the lane
Rate the goal and **announce the rating + lane** before doing anything. Base it on: are requirements/constraints concrete? is there an existing spec/code precedent? how big is the blast radius?

| Lane | Looks like | grill-me | explore | ADRs |
|------|-----------|----------|---------|------|
| 🟢 **Clear** | concrete, scoped, has precedent (e.g. "add `phone` to client API, required, E.164") | skip | skip | usually none (note decisions inline in design.md) |
| 🟡 **Medium** | known shape, some open decisions (e.g. "add Excel export to P&L report") | a few questions | skip | ADR for each non-trivial choice |
| 🔴 **Fuzzy / large** | vague or cross-cutting (e.g. "build a tax-reminder system") | grill hard | yes | ADRs for each architectural decision |

- State it plainly: *"Rating this 🟡 — I'll ask a few questions, propose, write ADRs for the key decisions, then stop for your review."*
- User can override anytime ("go light" → 🟢; "grill me hard" → 🔴).
- When unsure between two lanes, pick the **more cautious** one — planning is cheap, a wrong spec is expensive.

## Step 2 — Clarify (lane-dependent)
- 🟢 → skip.
- 🟡 → `grill-me`, kept short (only genuinely open decisions; anything answerable from the codebase, read the codebase instead).
- 🔴 → `/opsx:explore` to map the problem, then `grill-me` thoroughly until shared understanding.

## Step 3 — Propose
Run `openspec-propose` / `/opsx:propose "<goal, enriched with what you learned>"` to scaffold the change and generate proposal/design/delta-specs/tasks.

## Step 4 — ADRs for the significant decisions
For each architectural / cross-cutting / hard-to-reverse decision the change makes, record an **ADR** (context → decision → alternatives considered → consequences). Use `dev-workflows:technical-designer` / `documentation-criteria` for the format.
- Location: if the repo already uses `docs/adr/`, add `docs/adr/NNNN-<slug>.md` there; otherwise capture them in a **`## Decisions (ADR)`** section of the change's `design.md`.
- Scope by lane (table above). Don't manufacture ADRs for trivial 🟢 changes — a one-line note in design.md is enough.

## Step 5 — Recommend the implementation experts (record, don't run)
Analyze the task (`dev-workflows:task-analyzer`: essence/type/scale/tags) + the stack (host CLAUDE.md / `package.json` / `prisma` / file types), then **recommend** the tech-expert skills that `/implement-specs` should use to code — so the reviewer sees them too.
- Discover from skills **actually present** in this environment (e.g. `fullstack-dev-skills:nestjs-expert`, `:postgres-pro`, `:react-expert`, `:typescript-pro`, `nextjs-developer`, `:test-master`). Never name an unavailable skill.
- Pick a **primary** + 0–2 **supporting** (≤3 total), one line of reasoning each.
- **Write the recommendation into the change** (a `## Implementation experts` note in `design.md` or `tasks.md`) so `/implement-specs` can pick it up.

## Step 6 — STOP for review (the hand-off)
Do **not** start coding. Present a tight review package and stop:
- What to review: `proposal.md`, the delta specs, `tasks.md`, and the ADR(s) — with their paths.
- The recommended experts.
- Any open question the reviewer must settle.
- Closing line: **"Specs + ADRs are ready for review. Once approved, run `/implement-specs` to build (spec-loop will code → review → fix until it matches)."**

## Guardrails
- Phase 1 only. NEVER write production code in `/make-plan` — that belongs to `/implement-specs`. (Scaffolding the OpenSpec artifacts + ADR docs is expected; application/source code is not.)
- Announce the lane and each phase transition in one line.
- Honest about open questions — surface ambiguities for the reviewer instead of guessing.
- Respect the host project's CLAUDE.md conventions.
- One goal at a time.
