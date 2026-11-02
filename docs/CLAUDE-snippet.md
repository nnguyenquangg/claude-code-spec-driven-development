<!-- Paste this into a project's CLAUDE.md so Claude proactively drives the spec-driven loop. -->

## Spec-Driven Development (OpenSpec) — DEFAULT WORKFLOW

This project uses **OpenSpec** (`@fission-ai/openspec`, global; CLI: `openspec`). Specs live in `openspec/specs/` (approved truth), in-flight work in `openspec/changes/<name>/` (`proposal.md` / `design.md` / `tasks.md` / delta `specs/`), finished work in `openspec/changes/archive/`.

**`/task-analyzer "<task>"` (front door — use this when unsure which track fits).** Sizes up the task (essence, type, scale counted from the files it touches, tags) and reads whether the wording means "just look" or "go do it": look-only wording → hands back the analysis and stops; action wording or a bare description → drives the matched track itself (direct / `/fix` / `/make-plan` / `/autopilot` / `/research`) with no further check-in. A change spanning repos or touching a contract/API is never treated as small.

**`/research "<target>"` (optional pre-step).** For an idea or unknown, research it first: it auto-picks tools (web search, codebase search via the `Explore` agent, the right expert skills), then outputs a read-only brief — sources, ideas/options + recommendation, a wireframe, and a step-by-step flow — that feeds `/make-plan`. Writes no production code.

**Two-phase entry point (human review in between).**
- **`/make-plan "<goal>"` — Phase 1 (Plan & Specify).** Resume-check → rate clarity (🟢 light / 🟡 grill a bit / 🔴 grill hard) → grill-me/`/opsx:explore` → `/opsx:propose` (proposal + design + delta specs + tasks) → write **ADR(s)** for significant decisions → `task-analyzer` to **recommend** the tech-expert lineup (primary + ≤2 supporting, discovered from available skills) → **STOP for human review. No production code.**
- **`/implement-specs` — Phase 2 (Build).** After specs + ADRs are approved: load the finalized change + ADRs + recommended experts → `spec-loop` (implement through those experts → independent review vs specs+ADRs → fix → repeat, cap 6) → quality gate + the sized review step → `/opsx:archive` → `open-pr` (draft PR with the evidence) → auto-record the non-obvious logic decisions + why to the project auto-memory so future sessions don't re-read code.

**`/autopilot "<goal>"` — full-auto (no human gate).** When the user is busy and wants the whole thing done, this fuses `/make-plan` + `/implement-specs` into one hands-off run: it plans, **AI-reviews the specs with an independent sub-agent in place of the human gate**, resolves open decisions with sensible defaults while **logging every assumption**, builds via `spec-loop` (`diagnose` on a repeated failure), runs the quality gate and the sized review step, archives, records memory, and hands back one review packet. It ends with a **draft PR** carrying the evidence (`open-pr`) and never merges — the user reviews and merges.

`/what-now` (read-only) prints "you are here" on the two-phase map + the next command + the skill inventory.

**Operating rule — do this without being asked.** When the user states a requirement in plain language ("add X", "fix Y", "build Z"), proactively drive the flow yourself — don't wait for them to say "give me a spec". Route it through `task-analyzer` first (it reads whether their wording means "just look" or "go do it", and picks the matched track) unless it's obviously a bug (`/fix`) or obviously a full feature ask (`/make-plan`), in which case go straight there.

1. **Plan & Specify (`/make-plan`)** — **first** interview with `grill-me` if there are open decisions (`/opsx:explore` for fuzzy scope) — grilling happens here, during spec creation, **never after code**. Then `/opsx:propose "<requirement>"`: scaffold the change, generate proposal/design/tasks + delta specs; write ADRs; recommend experts. **Then stop for review — don't code yet.**
2. **Build (`/implement-specs`)** — once specs + ADRs are approved: `/opsx:apply`, or hands-off via **`spec-loop`** (implement → independent fresh-subagent review vs finalized specs → fix → repeat, cap 6 → quality gate). No grilling here — questions belong to Phase 1.
3. **Archive** — `/opsx:archive` to fold deltas into `openspec/specs/`. `/opsx:sync` updates main specs without archiving.
4. **Explore** — for fuzzy requests, `/opsx:explore` first.

**Bugs use `/fix`, not `/make-plan`.** For a small bug, run the `fix` skill / `/fix`: `diagnose` the root cause → pick the right tech-expert for the affected stack → failing test → minimal fix → verify for real → the sized review step when non-trivial → `open-pr` (draft PR). No ADR and no human gate (a short OpenSpec change when the fix is non-trivial); it auto-escalates to `/make-plan` if the bug turns out to need a design change.

**Skip everything for** trivial one-liners, typos, or quick questions — `/fix` for bugs, `/make-plan` for features, direct for trivial edits.

### Working rules (every lane)

1. One unit of work at a time. Read code before editing it. Do what was asked and nothing more: no drive-by refactors, renames or reformatting.
2. Every non-trivial change (anything beyond one file with no judgement call; a change spanning repos or touching a contract/API is never trivial) has an OpenSpec change with GIVEN / WHEN / THEN scenarios before any code (no `openspec/` yet: `openspec init --tools claude` first). Tests follow its scenarios; expected values come from the spec, never recomputed the way the code computes them.
3. Done means the project's checks pass **and** the behaviour was exercised for real (request, command, UI), not only unit tests. Any change a user can see also needs a `ui-walkthrough` (real browser, real API, every screenshot read) before reporting done.
4. Never weaken, skip or delete a test, or silence a lint/type rule, to get green.
5. Before reporting done on a non-trivial change, review-fix rounds included: run the review step **sized to the change** in parallel (one message) on the full diff of every repo touched — `diff-reviewer` always, `security-reviewer` on a security surface, `edge-case-reviewer` on a logic/state/boundary/failure surface; the full three plus the walkthrough for a high-risk surface (security, data/auth, a contract or API, unsafe code or a secret in a public repo, or an escalate path) — giving each the task, the base branch, every repo path and the OpenSpec change. When the change is UI-visible, launch the `walkthrough-runner` agent in the same parallel message, so reading the screenshots does not block; done needs each chosen check clean on the same frozen diff and the walkthrough's own verdict decides. Fix every blocking finding, re-run only the reviewer whose domain the fix touched (the full set for a high-risk-surface change), and re-run the walkthrough when the fix touches a walked screen. A BLOCKED walk (server down, unsafe target, no test account) is an access problem to resolve, not a code fix. Skipping needs a written reason.
6. A value a change makes always the same is not a field: remove the flag / parameter / column end to end instead of hard-coding it. Answering a review comment, first trace what it makes redundant and remove that in the same round.
7. A hard bug, or the same failure a third time: use the `diagnose` skill instead of patching again.
8. Git: the build lanes (`/fix`, `/implement-specs`, `/autopilot`) finish with `open-pr`: a feature branch, one commit (plus one per review-fix round), a push of that branch and a **draft** PR with the evidence. Anything else is pushed only when the user asks. Never merge, never push the default branch, never force-push or rewrite history.
