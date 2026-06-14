---
name: implement-specs
description: PHASE 2 (Build) of the spec-driven pipeline — runs AFTER specs + ADRs are approved. Loads the finalized OpenSpec change, implements it via the recommended tech-expert skills, runs spec-loop (implement → independent review vs specs → fix → repeat until matched), quality gate, archives, and auto-records context to memory. Use when the user says specs/ADRs are final and wants the code built. Triggers on "implement-specs", "/implement-specs", "specs are final, build it", "implement the change", "build the approved change".
---

# implement-specs — Phase 2: Build the approved change

Runs after `/make-plan` (Phase 1) produced specs + ADRs and a human **approved** them. The invocation itself is the approval signal. This phase turns finalized specs into working code via `spec-loop`, then archives and records context. It does **not** re-do planning or invent requirements — the specs/ADRs are the contract.

Sub-skills you compose:
- `spec-loop` — implement → independent fresh-subagent review vs FINAL specs → fix → repeat until matched (cap 6)
- the **recommended expert skills** from the change (e.g. `fullstack-dev-skills:nestjs-expert`, `:postgres-pro`, `nextjs-developer`, `:typescript-pro`)
- `openspec-archive-change` / `/opsx:archive` — fold deltas into `openspec/specs/`

## Step 0 — Read the project CLAUDE.md, then locate & load the change
**Always read the project's `CLAUDE.md` first** (the root one, and any nested `CLAUDE.md` in the directories you'll touch) before writing any code — it is the source of truth for this repo's conventions, flow, commands, and do/don't rules (e.g. enums-not-strings, `orgId` scoping, "don't run tsc/prisma yourself"). Everything spec-loop implements must follow it. If it conflicts with a spec, surface the conflict instead of silently picking one.

Then locate the change:
```bash
openspec list --json
```
Resolve the active change (if several, ask which). Then load the **finalized contract**: `proposal.md`, every delta spec, `tasks.md`, the ADR(s) (`docs/adr/*` or the `## Decisions (ADR)` section of `design.md`), and the `## Implementation experts` recommendation. Read `openspec status --change <name> --json` for paths.
- If no change exists, or specs are clearly still draft/empty → stop and tell the user to run `/make-plan` first.
- If tasks are already partly checked → resume from the unchecked ones (don't redo finished work).

## Step 1 — Confirm experts
Use the experts recommended in the change. If none were recorded, do a quick `dev-workflows:task-analyzer` pass to pick a primary + ≤2 supporting from the skills available in this environment. Announce them in one line.

## Step 2 — Implement via spec-loop (hands-off)
Invoke `spec-loop` for the change, **telling it which expert skills to implement as**. Two application modes — pick per task size:
- **Load guidance (default, small/medium):** invoke the expert skill(s) via the Skill tool so their patterns are in context, then implement following them + the ADRs + the host CLAUDE.md.
- **Parallel build (large / disjoint surfaces):** the `Agent` tool's `subagent_type` must be a **real agent type** (`general-purpose`, `Explore`, …) — it is **NOT** a Skill, so passing an expert's name (e.g. `fullstack-dev-skills:nestjs-expert`) silently no-ops. Instead dispatch one **`general-purpose` agent per disjoint file-set** and instruct each agent to (a) **load the relevant expert Skill itself via the Skill tool**, (b) read the project `CLAUDE.md` + the specs, then (c) build **only its assigned, non-overlapping files**. Lock any shared contract (a component/interface both depend on) **before** dispatching, so parallel agents code against it. Integrate the results.
spec-loop loops implement → **independent** fresh-context review against the finalized specs **and the ADR decisions** → fix gaps → repeat (cap 6), then runs the quality gate. The reviewer stays separate from the implementing experts so it never rubber-stamps. Do NOT babysit with check-ins — that's the point.

Honor the ADRs: if implementation reveals an ADR decision is wrong or infeasible, **stop and report** — do not silently deviate. A changed decision means going back to `/make-plan` to update the ADR/specs.

## Step 3 — Quality gate
Run the project's checks if present (`npm run lint`, `build`, tests — detect from package.json / CLAUDE.md). Fix red, re-run. Respect host CLAUDE.md (e.g. don't run `tsc`/`prisma` yourself in this workspace). A passing reviewer with a red quality gate is NOT done.

## Step 4 — Archive
When spec-loop reports success and quality is green, run `openspec-archive-change` / `/opsx:archive` to fold the delta specs into `openspec/specs/`. If spec-loop hit its cap or an ADR/spec conflict, skip archiving and hand back to the user with the blocker.

## Step 5 — Capture session context (AUTOMATIC — do not skip)
Record the **non-obvious** outcome to the project auto-memory (`<project>/memory/` + `MEMORY.md`), following its rules exactly:
- Write/update ONE memory file: the **logic decision(s) + why** (link the ADR), affected flow/files at a high level, gotchas. Type `project` (or `feedback` for a working-preference correction). Absolute dates.
- Only what code/git/specs don't already make obvious — reasoning, trade-offs, cross-cutting effects. No code-structure dumps or git-diff restatements.
- **Dedupe:** update a related memory instead of duplicating; link with `[[name]]`; add a one-line pointer in `MEMORY.md` for new files.
- If stopped early, record what's done, what's left, and the blocker so the next session resumes.

## Step 6 — Report
Tight summary: change → experts used → specs satisfied (and where) → ADRs honored → quality gate result → archived → memory note written (filename).

## Guardrails
- The specs + ADRs are the contract: implement exactly them, no scope creep, no guessing on ambiguity (stop and ask).
- Never fake completion: spec-loop's independent reviewer must confirm before any task is checked off.
- Announce each phase transition in one line.
