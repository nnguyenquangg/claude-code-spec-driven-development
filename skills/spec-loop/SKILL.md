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
Implement the pending checklist items directly (Edit/Write). On the first iteration, do the full implementation pass following `tasks.md` in dependency order. On later iterations, implement **only the gaps** the reviewer reported. Check off completed items in `tasks.md`. Follow the host project's CLAUDE.md conventions (enums not raw strings, `orgId` scoping, `jsonResponse`, no `any`, etc.).

**Then prune what the change orphaned.** When an edit replaces or bypasses old logic, remove the code it just made dead — orphaned helpers, unreachable branches, dead imports/constants/config reads, replaced functions. For each suspect from your diff, `grep -rn` the whole repo; **zero real consumers → remove it**, then cascade (each deletion can orphan more) until nothing new turns up. Scope it to what THIS change orphaned, not a repo-wide hunt. **Do NOT delete** dynamically-referenced code (reflection, DI, decorators/registries, string dispatch, Odoo model/field names in XML/views, ORM columns), public/exported API, framework/lifecycle hooks, or config/i18n/template references — when unsure it's dynamically used, keep it and note it. Pruning is behavior-preserving: if removing something would change behavior, it wasn't dead. The quality gate (step 4) catches a wrong removal.

### 1b. Self-verify, in order — REQUIRED before requesting review

Run this ordered checklist after every implementation pass (not just once) — fix red at any step before moving to the next, and before handing off to the independent reviewer in step 2:

1. **E2e tests, if the touched area has any** — run them first; they catch integration breakage the fastest feedback loop would miss. Fix red, re-run.
2. **Unit tests** — run the touched area's unit tests (add a cheap one for the new behavior if none exists and it's quick). Fix red, re-run.
3. **Backend/API changes — call the API directly.** Don't stop at green automated tests: hit the running endpoint yourself (curl/httpie/the project's API client) for the happy path **and** a few edge cases the spec implies (empty input, not-found, unauthorized, boundary values) — automated tests can pass while the wiring is still wrong end-to-end.
4. **UI-affecting changes — browser verification with screenshots.** See step 2b below; do this after 1-3 are green, not before — a UI screenshot proves nothing if the underlying logic is still broken.

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

#### 2b. Browser verification (REQUIRED when the change affects visible/interactive UI)
Static code review is not enough for UI behavior — **exercise the running app**, don't just read the code. Run this only after step 1b's e2e/unit/API checks are green. The user keeps the app **logged in** in their Arc browser; `browser-harness` is installed and attaches to that real session (see its SKILL.md, auto-loaded via `~/.claude/CLAUDE.md`). The reviewer sub-agent (it has `Bash`) runs it directly.

Screenshots go under **`<project-root>/screenshots/<change>/`** (create it if missing, and add `screenshots/` to the project's `.gitignore` if it isn't already ignored — these are local proof artifacts, never committed). This replaced the old `~/web-proofs/<change>/` convention; use the new project-relative path.

**Invoke it by full path** — `~/.local/bin/browser-harness` (and `~/.local/bin/web-proof`). The non-interactive Bash environment does NOT have `~/.local/bin` on `$PATH`, so a bare `browser-harness` fails with command-not-found. Helpers (`new_tab`, `wait_for_load`, `capture_screenshot`, `click_at_xy`, `js`, `page_info`) are pre-imported inside the heredoc; the daemon auto-starts and re-attaches to the running Arc.

Apply this pass when **any requirement/scenario describes user-visible behavior** (a page renders X, clicking Y produces Z, a list filters/sorts, a badge/state shows, a form validates). Skip it only for pure backend/API/types/migration changes with no rendered surface — and say so in `notes`.

For each UI-affecting scenario:
1. Navigate to the page that exercises it:
   ```bash
   ~/.local/bin/browser-harness <<'PY'
   new_tab("http://localhost:3000/<path>")
   wait_for_load()
   print(page_info())
   PY
   ```
   Use the project's dev URL (detect from CLAUDE.md / package.json; ask the user once if unknown). First navigation must be `new_tab(url)`, never `goto_url` (it clobbers the user's active tab).
2. Reproduce the scenario's **GIVEN/WHEN** steps in the live UI — `capture_screenshot("<project-root>/screenshots/<change>/<scenario>-<step>.png", max_dim=1600)` to find targets, `click_at_xy()` / form fills / `js()` to act, re-screenshot after each meaningful action. (Or `~/.local/bin/web-proof <url> <label>` for a quick single shot.) Read DOM state with `js("document.querySelector('…').value/textContent")`; trigger actions with `js("el.click()")` or `click_at_xy()`. **React/Next.js inputs:** `el.value = x` does NOT update React state — use `Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set.call(el, x); el.dispatchEvent(new Event('input',{bubbles:true}))`.
3. **Read every screenshot back** (Read tool on the PNG) and judge the **actual rendered behavior** against the scenario's **THEN** (expected outcome) — a screenshot captured but never looked at is not verification. Cover more than one case when the scenario has variants (different input, role, or empty state); one lucky screenshot isn't proof of the general behavior. Only once every captured screenshot has been reviewed and looks correct does the UI requirement count as satisfied.

Any divergence between what the UI does and what the scenario requires is a **gap** in the same JSON shape — put the screenshot path(s) in `problem` as evidence (e.g. `"problem": "spec requires trial tutors keep preferred floor; UI shows 3F forced — see screenshots/<change>/floor-after.png"`). Code that looks correct but renders/behaves wrong still fails.

**Login wall:** if a page redirects to login / shows a logged-out state, STOP and ask the user to log in (they own the session) — never type credentials or read them from screenshots.

### 3. Decide
- `satisfied === true` and `gaps` empty → go to **Quality gate**.
- Otherwise → record gap count. If it did not drop vs the previous iteration, `noProgress++`; else reset `noProgress = 0`. Feed `gaps` back into step 1 and loop.
- If `reviewer.notes` flags a genuine spec ambiguity (the spec is silent/contradictory, not just unimplemented) → **stop and ask the user**. Never invent a requirement to make the reviewer pass.

### 4. Quality gate
Step 1b already confirmed e2e + unit tests (and, for backend/UI changes, API + screenshot verification) green for this iteration — this gate re-runs the **full** project suite once more as the final safety net (catches regressions from later iterations), plus whatever step 1b doesn't cover: `npm run lint`, `npm run build`, and any other project check (detect from package.json / CLAUDE.md). Fix anything red, then re-run. (Respect host CLAUDE.md: in this workspace, do NOT run `tsc`/`prisma` yourself — leave those to the user/CI.) A passing reviewer with a red quality gate is NOT done.

**Code review pass (if available).** In addition to the spec review (which only checks *matches the spec*), run a **code-review** over the changed files to catch bugs / security / quality the spec review won't — use the `dev-workflows:code-reviewer` agent or the `fullstack-dev-skills:code-reviewer` / built-in `code-review` skill, whichever is present (skip if none). Have it check against the project's `CLAUDE.md` conventions (enums-not-strings, `orgId` scoping, `jsonResponse`, no `any`, reuse-first, etc.). Fix every real finding; ignore pure style nits the repo doesn't mandate. Don't exit until its blocking findings are resolved.

### 5. Exit
Stop when **either**:
- ✅ reviewer `satisfied` + quality gate green → report success: list each requirement and where it's satisfied (for UI requirements, link the proof screenshot under `screenshots/<change>/`), and the tasks now checked off. Offer `/opsx:archive`.
- 🛑 `iteration > 6` or `noProgress >= 2` → stop and report: the remaining `gaps`, what you tried, and why it isn't converging. Do not loop forever or fake completion.

## Rules
- Autonomous: no "should I continue?" between cycles — that's the whole point.
- Honest: never check off a task or claim a spec is met without the independent reviewer confirming it. Report failures plainly.
- In scope only: implement exactly what the finalized specs say — no scope creep, no guessing on ambiguity.
- Minimal diff: change only what each gap requires.
- Verify behavior, not just code: any requirement with a rendered/interactive surface must be confirmed in the live app via browser verification (step 2b), not by reading code alone.
