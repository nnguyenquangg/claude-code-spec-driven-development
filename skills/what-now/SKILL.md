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
🗺️  NOT SURE WHICH TRACK? → /task-analyzer "<task>"
      Sizes up the task and either hands back the analysis (if you're just
      asking) or drives the right track itself (if you said to do it) —
      no need to pick /fix vs /make-plan vs /autopilot yourself.

🗺️  OR PICK A TRACK DIRECTLY BY THE KIND OF WORK
  • Idea / unknown   → /research     (web + codebase → sources, options, wireframe, flow → then plan)
  • Small bug        → /fix          (diagnose → failing test → minimal fix → verify for real → reviewers)
  • Feature / change → /make-plan …  (the 2-phase SDD pipeline below)
  • "I'm busy, do it all" → /autopilot  (plan + build hands-off, AI gate + three reviewers, review the output)
  • Typo / one-liner → just do it, no skill

🗺️  SPEC-DRIVEN PIPELINE  (for features — 2 phases, review in between)
  ① Plan & Specify → /make-plan "<goal>"   (clarify → specs + ADR → STOP for review)
        ⤷ uses grill-me / /opsx:explore / /opsx:propose
  — 👁  human reviews & approves specs + ADRs —
  ② Build          → /implement-specs       (spec-loop: code → review → fix until matched)
        ⤷ implements via the recommended experts, then quality gate + three reviewers → draft PR
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
- `/task-analyzer <task>` — **front door**: sizes up any task, then either hands back the analysis or drives the matched track itself (direct / fix / make-plan / autopilot / research); never asks "analyze or proceed?"
- `/research <target>` — investigate (web + codebase), output a brief: sources, options, wireframe, flow; read-only, feeds /make-plan
- `/fix <bug>` — **lightweight bug track**: diagnose → failing test → minimal fix → verify for real → three reviewers when non-trivial → draft PR; auto-escalates to /make-plan if it turns out big
- `/make-plan <goal>` — **Phase 1**: clarify → specs + ADR → recommend experts → STOP for review (no code)
- `/implement-specs` — **Phase 2**: after specs/ADRs are approved → spec-loop builds via experts → quality gate + three reviewers → archive → draft PR → record memory
- `/autopilot <goal>` — **full-auto**: make-plan + implement-specs in one run, no human gate; AI-reviews the specs, runs the three reviewers, logs assumptions, hands back a review packet; opens a draft PR with the evidence, never merges
- `grill-me` — interview the user to lock the plan before coding
- `/opsx:explore` — think through a fuzzy/large problem
- `/opsx:propose` — generate specs + design + tasks from one description
- `spec-loop` — autonomously implement → independent review → fix until specs match
- `dev-workflows:technical-designer` — write ADRs / design docs
- `/opsx:archive` · `/opsx:sync` — close the change / fold delta specs into the main specs
- `open-pr` — feature branch, one commit, push, **draft** PR with the spec, checks, walkthrough screenshots and reviewer verdicts; never merges
- `diagnose` — disciplined debugging loop (reproduce → minimise → hypothesise → instrument → fix → guard)
- `ui-walkthrough` — click through the running app like a user, verify every write over the real API, read every screenshot
- agents `diff-reviewer` · `security-reviewer` · `edge-case-reviewer` — the three parallel reviewers every non-trivial change gets before done
- (optional) `dev-workflows:code-verifier` — code vs specs; `dev-workflows:quality-fixer` — fix lint/build/test

Keep the whole output compact — it's a glanceable cheat-sheet, not a tutorial. Then stop.
