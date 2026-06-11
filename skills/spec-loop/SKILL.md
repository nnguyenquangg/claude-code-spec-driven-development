---
name: spec-loop
description: Autonomously implement an OpenSpec change end-to-end — implement → independently review the code against the FINALIZED specs in a fresh sub-agent → fix every gap → repeat until all requirements/scenarios and tasks are satisfied, with NO manual review between cycles. Use when specs are already final and the user wants hands-off "make the code match the specs" execution. Triggers on "spec loop", "spec-loop", "auto apply", "implement until specs match", "làm tới khi match hết specs", "tự làm tới khi xong".
---

# spec-loop — autonomous implement → review → fix until specs match

Run the full implement/review/fix cycle **autonomously** against a finalized OpenSpec change. The user runs this **once**; you keep going until the code satisfies every requirement, scenario, and task — you do NOT stop to ask the user to review between cycles. Only stop on success, on the safety cap, or when genuinely blocked.

**Precondition:** the specs are final. If the change still has open design questions, stop and tell the user to finalize specs first (via `/opsx:propose` / `grill-me`) — do NOT invent requirements.

## Inputs

- Optional change name (kebab-case) as argument. If none given, resolve the active change:
  ```bash
  openspec list --json
  ```
  If exactly one in-progress change exists, use it. If several, ask the user which one (the only question you may ask up front). If none, stop and say there is no change to implement.

## The loop

Maintain two counters: `iteration` (cap **6**) and `noProgress` (cap **2**).

### 0. Load the source of truth (once)
Read the finalized artifacts for the change — these are the spec, nothing outside them is in scope:
```bash
openspec show <name> --json
openspec status --change <name> --json
```
Read `proposal.md`, `design.md`, `tasks.md`, and every delta spec under the change's `specs/` (use the paths from `status`/`show`, don't assume repo-relative paths). Build a checklist of **every requirement + scenario + unchecked task**. This checklist is the loop's exit condition.

### 1. Implement
Implement the pending checklist items directly (Edit/Write). On the first iteration, do the full implementation pass following `tasks.md` in dependency order. On later iterations, implement **only the gaps** the reviewer reported. Check off completed items in `tasks.md`. Follow the host project's CLAUDE.md conventions (enums not raw strings, `orgId` scoping, `jsonResponse`, no `any`, etc.).

### 2. Independent review (fresh sub-agent — REQUIRED)
Do **not** review your own work inline — you will rubber-stamp it. Spawn a fresh-context reviewer via the **Agent tool** (`subagent_type: "dev-workflows:code-verifier"`, or `general-purpose` if unavailable). Give it: the change name, the list of artifact paths, and the files you touched. Instruct it to verify the code against the finalized specs **only** and return STRICT JSON:

```json
{
  "satisfied": false,
  "gaps": [
    { "requirement": "<spec/requirement/scenario id or quote>",
      "file": "path:line",
      "problem": "what is missing or wrong vs the spec",
      "fix": "concrete change needed" }
  ],
  "notes": "anything ambiguous in the spec the implementer must NOT guess on"
}
```
Tell the reviewer: report only real spec mismatches (missing requirement, wrong behavior, unhandled scenario, violated constraint) — not style preferences or anything the spec doesn't mandate. Be adversarial; default to listing a gap when unsure rather than passing.

### 3. Decide
- `satisfied === true` and `gaps` empty → go to **Quality gate**.
- Otherwise → record gap count. If it did not drop vs the previous iteration, `noProgress++`; else reset `noProgress = 0`. Feed `gaps` back into step 1 and loop.
- If `reviewer.notes` flags a genuine spec ambiguity (the spec is silent/contradictory, not just unimplemented) → **stop and ask the user**. Never invent a requirement to make the reviewer pass.

### 4. Quality gate
Run the project's checks if they exist (detect from package.json / CLAUDE.md), e.g. `npm run lint`, `npm run build`, tests. Fix anything red, then re-run. (Respect host CLAUDE.md: in this workspace, do NOT run `tsc`/`prisma` yourself — leave those to the user/CI.) A passing reviewer with a red quality gate is NOT done.

### 5. Exit
Stop when **either**:
- ✅ reviewer `satisfied` + quality gate green → report success: list each requirement and where it's satisfied, and the tasks now checked off. Offer `/opsx:archive`.
- 🛑 `iteration > 6` or `noProgress >= 2` → stop and report: the remaining `gaps`, what you tried, and why it isn't converging. Do not loop forever or fake completion.

## Rules
- Autonomous: no "should I continue?" between cycles — that's the whole point.
- Honest: never check off a task or claim a spec is met without the independent reviewer confirming it. Report failures plainly.
- In scope only: implement exactly what the finalized specs say — no scope creep, no guessing on ambiguity.
- Minimal diff: change only what each gap requires.
