---
name: what-now
description: Read-only recall/menu for the spec-driven pipeline. Detects where the current OpenSpec change is and prints "you are here" on the pipeline map, the next command to run, and an inventory of the available skills/agents. Use when the user forgets what to do next or what tooling exists. Triggers on "what now", "/what-now", "what do I run", "remind me", "where am I", "which skill".
---

# what-now — "where am I & what can I run"

**Read-only.** Do NOT implement, edit, or create anything. Just orient the user and stop.

## 1. Detect current state
```bash
openspec list --json
```
For the active/most-recent change, also peek at `tasks.md` checkbox progress (via `openspec status --change <name> --json`). Map it to a stage:
- no change → **Stage 0: Idea** (nothing started)
- change exists, specs/ADRs being written, not yet reviewed → **Stage 1: Plan & Specify** (`/make-plan`)
- specs + ADRs final/approved, tasks unchecked or partial → **Stage 2: Build** (`/implement-specs`)
- tasks all checked, not archived → **Stage 3: Archive**
- archived → **Done**

## 2. Print the pipeline map with "you are here"
Render this, marking the current stage with `👉`:

```
🗺️  PICK A TRACK BY THE KIND OF WORK
  • Small bug        → /fix          (diagnose → pick expert → minimal fix → verify)
  • Feature / change → /make-plan …  (the 2-phase SDD pipeline below)
  • Typo / one-liner → just do it, no skill

🗺️  SPEC-DRIVEN PIPELINE  (for features — 2 phases, review in between)
  ① Plan & Specify → /make-plan "<goal>"   (clarify → specs + ADR → STOP for review)
        ⤷ uses grill-me / /opsx:explore / /opsx:propose
  — 👁  human reviews & approves specs + ADRs —
  ② Build          → /implement-specs       (spec-loop: code → review → fix until matched)
        ⤷ implements via the recommended experts, then quality gate
  ③ Archive        → /opsx:archive          (fold specs in, close the change)
  ④ Context        → auto-record to memory   (logic + why, for the next session)
```

## 3. Tell them the single next action
One line: the exact command to run next given the detected stage.
- Stage 0 → `/make-plan "<what you want>"` (produce specs + ADRs for review)
- Stage 1 (specs exist, awaiting approval) → review them, then `/implement-specs`
- Stage 2 (building) → `/implement-specs` to continue, or `/opsx:archive` if tasks are done

## 4. Skill / agent inventory
List the toolkit, one line each, so they remember what's available:
- `/fix <bug>` — **lightweight bug track**: diagnose → pick expert → minimal fix → verify; auto-escalates to /make-plan if it turns out big
- `/make-plan <goal>` — **Phase 1**: clarify → specs + ADR → recommend experts → STOP for review (no code)
- `/implement-specs` — **Phase 2**: after specs/ADRs are approved → spec-loop builds via experts → quality gate → archive → record memory
- `grill-me` — interview the user to lock the plan before coding
- `/opsx:explore` — think through a fuzzy/large problem
- `/opsx:propose` — generate specs + design + tasks from one description
- `spec-loop` — autonomously implement → independent review → fix until specs match
- `dev-workflows:task-analyzer` — analyze a task → suggest the right expert skills
- `dev-workflows:technical-designer` — write ADRs / design docs
- `/opsx:archive` · `/opsx:sync` — close the change / fold delta specs into the main specs
- (support) `dev-workflows:code-verifier` — code vs specs; `dev-workflows:quality-fixer` — fix lint/build/test

Keep the whole output compact — it's a glanceable cheat-sheet, not a tutorial. Then stop.
