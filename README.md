# claude-sdd-pipeline

A spec-driven-development (SDD) toolkit for **Claude Code** — state a goal in plain language and let Claude drive the whole pipeline: clarify → specs → implement-until-it-matches → archive → record context. Built on top of [OpenSpec](https://github.com/Fission-AI/OpenSpec).

## The pipeline

```
/my-goal "<what you want>"
   │
   0. Resume-check        — am I already mid-way on this goal?
   1. Rate clarity        — 🟢 clear / 🟡 medium / 🔴 fuzzy  → pick autonomy lane
   2. Clarify             — grill-me / /opsx:explore  (lane-dependent)
   3. /opsx:propose       — generate proposal + design + specs + tasks
   4. Tech analysis       — task-analyzer → pick expert skills to drive the code
   5. Checkpoint          — approve specs + experts (gate only for 🟡/🔴)
   6. spec-loop           — implement → independent review vs specs → fix → repeat
   7. /opsx:archive       — fold delta specs into the source-of-truth specs
   8. Capture context     — auto-write the non-obvious logic + why to memory
```

**Adaptive gating:** how often Claude stops to check in is decided by how clear the task is. Clear tasks run hands-off; fuzzy ones get interrogated first. You can override the lane anytime ("full auto" / "grill me hard").

## What's in this repo

| Path | What |
|------|------|
| `skills/my-goal/` | Orchestrator skill — runs the whole pipeline, adaptive autonomy, picks expert skills, auto-records context |
| `skills/spec-loop/` | Autonomous implement → **independent** fresh-subagent review vs FINAL specs → fix → repeat until matched (cap 6 iterations) |
| `skills/what-now/` | Read-only cheat-sheet — "you are here" on the pipeline + next command + skill inventory |
| `commands/*.md` | Thin slash-command wrappers (`/my-goal`, `/spec-loop`, `/what-now`) |
| `docs/CLAUDE-snippet.md` | Paste-in block for a project's `CLAUDE.md` so Claude defaults to this flow |
| `install.sh` | Symlinks skills/commands into `~/.claude/` and checks dependencies |

## Dependencies (auto-installed by `install.sh`)

`install.sh` installs all of these for you (and is idempotent — skips anything already present). They are **not** vendored into this repo, just installed from their own sources:

| Dependency | Source | Used by | Manual command |
|------------|--------|---------|----------------|
| **OpenSpec CLI** | npm `@fission-ai/openspec` | Steps 3/7 (propose/archive) | `npm install -g @fission-ai/openspec@latest` |
| **grill-me** skill | [@mattpocock](https://github.com/mattpocock/skills) (MIT) | Step 2 (clarify) | `npx skills add mattpocock/skills --skill=grill-me -y -g` |
| **dev-workflows** plugin | gh `shinpr/claude-code-workflows` | Step 4/6 (`task-analyzer`, `code-verifier`, `quality-fixer`) | `claude plugin marketplace add shinpr/claude-code-workflows && claude plugin install dev-workflows@claude-code-workflows` |
| **fullstack-dev-skills** plugin | gh `jeffallan/claude-skills` | Step 4 experts (`nestjs-expert`, `postgres-pro`, `react-expert`, `typescript-pro`, …) | `claude plugin marketplace add jeffallan/claude-skills && claude plugin install fullstack-dev-skills@fullstack-dev-skills` |

After install, run `openspec init --tools claude` in each project. `my-goal` only ever picks experts that are actually present in your environment, so the two plugin packs are recommended but not strictly required.

## Install

```bash
git clone <this-repo> claude-sdd-pipeline
cd claude-sdd-pipeline
./install.sh          # symlinks into ~/.claude (default) — re-run after pulling updates
./install.sh --copy   # copy instead of symlink
```

Then install the dependencies above, and **restart Claude Code** so the new skills/commands appear.

## Per-project setup

1. `openspec init --tools claude` in the project root.
2. Paste `docs/CLAUDE-snippet.md` into the project's `CLAUDE.md` so Claude proactively drives the loop.

## Usage

```
/my-goal "add Excel export to the P&L report"   # run the whole pipeline
/what-now                                        # forgot where you are? this orients you
/spec-loop                                       # just the autonomous implement-until-match loop on the active change
```

## License

MIT (the three skills/commands in this repo). `grill-me` and OpenSpec are separate projects under their own licenses.
