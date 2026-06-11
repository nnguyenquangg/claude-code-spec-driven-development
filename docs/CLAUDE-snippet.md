<!-- Paste this into a project's CLAUDE.md so Claude proactively drives the spec-driven loop. -->

## Spec-Driven Development (OpenSpec) — DEFAULT WORKFLOW

This project uses **OpenSpec** (`@fission-ai/openspec`, global; CLI: `openspec`). Specs live in `openspec/specs/` (approved truth), in-flight work in `openspec/changes/<name>/` (`proposal.md` / `design.md` / `tasks.md` / delta `specs/`), finished work in `openspec/changes/archive/`.

**One-command entry point.** `/my-goal "<goal>"` orchestrates the whole pipeline: resume-check → rate clarity (🟢 hands-off / 🟡 1 checkpoint / 🔴 grill first) → grill-me → `/opsx:propose` → analyze the task (`dev-workflows:task-analyzer`) and pick the tech-expert skills to drive coding (primary + ≤2 supporting, discovered from available skills) → `spec-loop` (implement through those experts) → `/opsx:archive` → auto-record the non-obvious logic decisions + why to the project auto-memory so future sessions don't re-read code. `/what-now` (read-only) prints "you are here" + the next command + the skill inventory.

**Operating rule — do this without being asked.** When the user states a requirement in plain language ("add X", "fix Y", "build Z"), proactively drive the loop yourself — don't wait for them to say "give me a spec". This is what `/my-goal` automates.

1. **Propose** — `/opsx:propose "<requirement>"`: scaffold the change, generate proposal/design/tasks + delta specs. Show for a quick confirm.
2. **Apply** — `/opsx:apply` to implement, or for hands-off execution once specs are FINAL, use **`spec-loop`**: implement → independently review code vs finalized specs in a fresh sub-agent → fix every gap → repeat (cap 6) → quality gate. No manual review between cycles.
3. **Archive** — `/opsx:archive` to fold deltas into `openspec/specs/`. `/opsx:sync` updates main specs without archiving.
4. **Explore** — for fuzzy requests, `/opsx:explore` first.

**Skip the loop for** trivial one-liners, typos, quick questions, or pure debugging with no spec impact.
