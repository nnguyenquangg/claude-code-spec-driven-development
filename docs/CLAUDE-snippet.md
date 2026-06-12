<!-- Paste this into a project's CLAUDE.md so Claude proactively drives the spec-driven loop. -->

## Spec-Driven Development (OpenSpec) — DEFAULT WORKFLOW

This project uses **OpenSpec** (`@fission-ai/openspec`, global; CLI: `openspec`). Specs live in `openspec/specs/` (approved truth), in-flight work in `openspec/changes/<name>/` (`proposal.md` / `design.md` / `tasks.md` / delta `specs/`), finished work in `openspec/changes/archive/`.

**Two-phase entry point (human review in between).**
- **`/make-plan "<goal>"` — Phase 1 (Plan & Specify).** Resume-check → rate clarity (🟢 light / 🟡 grill a bit / 🔴 grill hard) → grill-me/`/opsx:explore` → `/opsx:propose` (proposal + design + delta specs + tasks) → write **ADR(s)** for significant decisions → `dev-workflows:task-analyzer` to **recommend** the tech-expert lineup (primary + ≤2 supporting, discovered from available skills) → **STOP for human review. No production code.**
- **`/implement-specs` — Phase 2 (Build).** After specs + ADRs are approved: load the finalized change + ADRs + recommended experts → `spec-loop` (implement through those experts → independent review vs specs+ADRs → fix → repeat, cap 6) → quality gate → `/opsx:archive` → auto-record the non-obvious logic decisions + why to the project auto-memory so future sessions don't re-read code.

**`/autopilot "<goal>"` — full-auto (no human gate).** When the user is busy and wants the whole thing done, this fuses `/make-plan` + `/implement-specs` into one hands-off run: it plans, **AI-reviews the specs with an independent sub-agent in place of the human gate**, resolves open decisions with sensible defaults while **logging every assumption**, builds via `spec-loop`, runs the quality gate, archives, records memory, and hands back one review packet. It **never commits or push** — changes stay in the working tree for review.

`/what-now` (read-only) prints "you are here" on the two-phase map + the next command + the skill inventory.

**Operating rule — do this without being asked.** When the user states a requirement in plain language ("add X", "fix Y", "build Z"), proactively drive the flow yourself — don't wait for them to say "give me a spec".

1. **Plan & Specify (`/make-plan`)** — **first** interview with `grill-me` if there are open decisions (`/opsx:explore` for fuzzy scope) — grilling happens here, during spec creation, **never after code**. Then `/opsx:propose "<requirement>"`: scaffold the change, generate proposal/design/tasks + delta specs; write ADRs; recommend experts. **Then stop for review — don't code yet.**
2. **Build (`/implement-specs`)** — once specs + ADRs are approved: `/opsx:apply`, or hands-off via **`spec-loop`** (implement → independent fresh-subagent review vs finalized specs → fix → repeat, cap 6 → quality gate). No grilling here — questions belong to Phase 1.
3. **Archive** — `/opsx:archive` to fold deltas into `openspec/specs/`. `/opsx:sync` updates main specs without archiving.
4. **Explore** — for fuzzy requests, `/opsx:explore` first.

**Bugs use `/fix`, not `/make-plan`.** For a small bug, run the `fix` skill / `/fix`: diagnose root cause → pick the right tech-expert for the affected stack → minimal fix → verify. No specs/ADR/review gate; it auto-escalates to `/make-plan` if the bug turns out to need a design change.

**Skip everything for** trivial one-liners, typos, or quick questions — `/fix` for bugs, `/make-plan` for features, direct for trivial edits.
