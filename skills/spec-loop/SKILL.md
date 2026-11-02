---
name: spec-loop
description: Autonomously implement an OpenSpec change end-to-end — implement → independently review the code against the FINALIZED specs in a fresh sub-agent → fix every gap → repeat until all requirements/scenarios and tasks are satisfied, with NO manual review between cycles. Use when specs are already final and the user wants hands-off "make the code match the specs" execution. Triggers on "spec loop", "spec-loop", "auto apply", "implement until specs match", "keep going until it matches", "finish it autonomously".
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
Implement the pending checklist items directly (Edit/Write). On the first iteration, do the full implementation pass following `tasks.md` in dependency order. On later iterations, implement **only the gaps** the reviewer reported. Check off completed items in `tasks.md`. Follow the host project's CLAUDE.md conventions. One unit of work at a time; read code before editing it; no drive-by refactors, renames or reformatting.

**Then prune what the change orphaned.** When an edit replaces or bypasses old logic, remove the code it just made dead — orphaned helpers, unreachable branches, dead imports/constants/config reads, replaced functions. For each suspect from your diff, `grep -rn` the whole repo; **zero real consumers → remove it**, then cascade (each deletion can orphan more) until nothing new turns up. Scope it to what THIS change orphaned, not a repo-wide hunt. **Do NOT delete** dynamically-referenced code (reflection, DI, decorators/registries, string dispatch, Odoo model/field names in XML/views, ORM columns), public/exported API, framework/lifecycle hooks, or config/i18n/template references — when unsure it's dynamically used, keep it and note it. Pruning is behavior-preserving: if removing something would change behavior, it wasn't dead. A value the change makes always the same is not a field: when a flag, parameter or column becomes constant, remove it end to end (contract, producer, every consumer, docs, tests) instead of hard-coding it. The quality gate (step 4) catches a wrong removal.

### 1b. Self-verify, in order — REQUIRED before requesting review

Run this ordered checklist after every implementation pass (not just once) — fix red at any step before moving to the next, and before handing off to the independent reviewer in step 2:

1. **E2e tests, if the touched area has any** — run them first; they catch integration breakage the fastest feedback loop would miss. Fix red, re-run.
2. **Unit tests** — run the touched area's unit tests (add a cheap one for the new behavior if none exists and it's quick). Fix red, re-run.
3. **Backend/API changes — call the API directly.** Don't stop at green automated tests: hit the running endpoint yourself (curl/httpie/the project's API client) for the happy path **and** a few edge cases the spec implies (empty input, not-found, unauthorized, boundary values) — automated tests can pass while the wiring is still wrong end-to-end.
4. **UI-affecting changes — browser walkthrough.** See step 2b below; do this after 1-3 are green, not before — a UI screenshot proves nothing if the underlying logic is still broken.

Expected values in tests come from the spec scenarios or a worked example, never recomputed the way the code computes them. Never weaken, skip or delete a test, or silence a lint/type rule, to get green. If the same failure comes back a third time, stop patching and run the `diagnose` skill (reproduce → minimise → hypothesise → instrument → fix → guard).

Cover **more than one case per step** whenever it's cheap — the goal is confidence the change works broadly, not just on the one example in the spec.

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

#### 2b. UI walkthrough (REQUIRED when the change affects visible/interactive UI)
Static code review is not enough for UI behavior — **exercise the running app**, don't just read the code. Run this only after step 1b's e2e/unit/API checks are green. The **implementer** runs the walkthrough (it has the dev servers and the context); hand the reviewer sub-agent the slice folder (`verify-screenshots/<date>-<task>/<slice>/`: `review.md`, `api.log`, screenshots) so it judges the live evidence alongside the code, and treat a screenshot whose last review line is FINDING as a gap.

Apply it when **any requirement/scenario describes user-visible behavior** (a page renders X, clicking Y produces Z, a list filters/sorts, a badge/state shows, a form validates). Skip it only for pure backend/API/types/migration changes with no rendered surface — and say so in `notes`.

Run the `ui-walkthrough` skill over every UI-affecting scenario: a throwaway Playwright script (from the skill's template, kept outside the repo) reproduces each scenario's **GIVEN/WHEN** like a user, `expect`s its **THEN** on the rendered page, and verifies like QA — each write awaits the page's own API call (2xx) and the stored record is read back over the API; any 4xx/5xx in `api.log` fails the walk. **Read every screenshot back** (Read tool on the PNG) and write one `review.md` line per shot with the exact values seen — a screenshot captured but never looked at is not verification. Cover more than one case when the scenario has variants (different input, role, or empty state).

Any divergence between what the UI does and what the scenario requires is a **gap** in the same JSON shape — put the screenshot path(s) in `problem` as evidence (e.g. `"problem": "scenario requires the saved filter to persist after reload; the list resets to all rows — see verify-screenshots/<date>-<task>/<slice>/04-after-reload.png"`). Code that looks correct but renders/behaves wrong still fails.

**Login wall:** if no test account is documented, STOP and ask the user — never type real credentials or read them from screenshots.

### 3. Decide
- `satisfied === true` and `gaps` empty → go to **Quality gate**.
- Otherwise → record gap count. If it did not drop vs the previous iteration, `noProgress++`; else reset `noProgress = 0`. Feed `gaps` back into step 1 and loop.
- If `reviewer.notes` flags a genuine spec ambiguity (the spec is silent/contradictory, not just unimplemented) → **stop and ask the user**. Never invent a requirement to make the reviewer pass.

### 4. Quality gate
Step 1b already confirmed e2e + unit tests (and, for backend/UI changes, API + screenshot verification) green for this iteration — this gate re-runs the **full** project suite once more as the final safety net (catches regressions from later iterations), plus whatever step 1b doesn't cover: lint, build and any other project check (detect from package.json / CLAUDE.md; if the host CLAUDE.md says some commands are left to CI or the user, respect that). Fix anything red, then re-run. A passing reviewer with a red quality gate is NOT done.

**Review step (REQUIRED).** The spec review only checks *matches the spec*. Once it passes and the checks are green, launch the review step **sized to the change** (protocol rule 5) **in one message** (parallel Agent calls) on the full diff of every repo touched — `diff-reviewer` always, `security-reviewer` on a security surface, `edge-case-reviewer` on a logic/state/boundary/failure surface, the full three plus the walkthrough when the change touches security, data/auth, a contract or API, unsafe code or a secret in a public repo, or an escalate path; give each the change name, the base branch and every repo path. `diff-reviewer` reads the OpenSpec change and the project `CLAUDE.md`, and also hunts leftovers the change made redundant. **When any requirement is UI-visible**, launch the `walkthrough-runner` agent in the **same message** as the chosen reviewers — the implementer assembles one `walk.mjs` covering every flow the change touched (not just the last) into one `verify-screenshots/<date>-<task>/final/` folder, and the agent runs that single script, reads every screenshot and reports, so reading the shots does not block; done needs each chosen check clean on the same frozen diff and the walkthrough's own verdict decides. Fix every blocking finding, re-run only the reviewer whose domain the fix touched (the full set for a high-risk-surface change), and re-run the walkthrough when the fix touches a walked screen; a BLOCKED walk (server down, unsafe target, no test account) is an access problem to resolve, not a code fix. Minor findings are fixed or listed in the report. Don't exit until no reviewer has a blocking finding. Skipping needs a written reason in the report.

### 5. Exit
Stop when **either**:
- ✅ reviewer `satisfied` + quality gate green → report success: list each requirement and where it's satisfied (for UI requirements, the walkthrough's screenshots and review lines), the reviewer verdicts, and the tasks now checked off. Offer `/opsx:archive`.
- 🛑 `iteration > 6` or `noProgress >= 2` → stop and report: the remaining `gaps`, what you tried, and why it isn't converging. Do not loop forever or fake completion.

## Rules
- Autonomous: no "should I continue?" between cycles — that's the whole point.
- Honest: never check off a task or claim a spec is met without the independent reviewer confirming it. Report failures plainly.
- In scope only: implement exactly what the finalized specs say — no scope creep, no guessing on ambiguity.
- Minimal diff: change only what each gap requires.
- Verify behavior, not just code: any requirement with a rendered/interactive surface must be confirmed in the live app via the UI walkthrough (step 2b), not by reading code alone.
