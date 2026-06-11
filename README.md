# claude-code-spec-driven-development

A spec-driven-development (SDD) toolkit for **Claude Code** — state a goal in plain language and let Claude drive the whole pipeline: clarify → specs → implement-until-it-matches → archive → record context. Built on top of [OpenSpec](https://github.com/Fission-AI/OpenSpec).

**Two tracks, matched to the work:**

- **Feature / non-trivial change → the SDD pipeline** (`/my-goal` → review → `/implement-specs`, below).
- **Small bug → `/fix`** — a lightweight lane: diagnose root cause → pick the right tech-expert → minimal fix → verify. No specs, no ADR, no review gate. It auto-escalates to `/my-goal` if the bug turns out to need a design change.
- **Typo / one-liner →** just do it, no skill.

## The pipeline (two phases, human review in between)

```text
╭─ PHASE 1 · Plan & Specify ──────────────────  /my-goal "<goal>"
│
│   0  Resume-check
│   1  Rate clarity        🟢 light · 🟡 some · 🔴 grill hard
│   2  Clarify             grill-me / /opsx:explore
│   3  Propose             /opsx:propose → proposal + design + tasks
│   4  Write ADR(s)        for the significant decisions
│   5  Recommend experts   (recorded for Phase 2)
│   6  STOP                hand specs + ADRs to the reviewer
╰──────────────────────────────────────────────────────────────
                     │
             👁  human reviews & approves specs + ADRs
                     │
                     ▼
╭─ PHASE 2 · Build ───────────────────────────  /implement-specs
│
│   0  Load                change + ADRs + recommended experts
│   1  Confirm experts
│   2  spec-loop           implement → review → fix → repeat (cap 6)
│   3  Quality gate        lint / build / test
│   4  Archive             /opsx:archive
│   5  Record context      logic + why → memory
╰──────────────────────────────────────────────────────────────
```

### Why two phases?

Most AI coding loops blur planning and building, so unverified assumptions get written into code before anyone can catch them. Separating the phases puts a deliberate review gate between *deciding what to build* and *building it*:

- **`/my-goal` plans only.** It produces specs and ADRs but never writes production code — you review and approve the design before a single line is implemented.
- **`/implement-specs` builds.** Invoking it is the approval signal; it implements strictly against the approved specs and ADRs, then verifies the result against them.

**Adaptive interrogation.** `/my-goal` calibrates how much it questions you to how clear the request is — a well-scoped task gets a light pass, an ambiguous one gets thoroughly interrogated — and you can raise or lower that depth at any time.

## What's in this repo

| Path | What |
|------|------|
| `skills/my-goal/` | **Phase 1** — clarify → specs + ADRs → recommend experts → STOP for review (no code) |
| `skills/implement-specs/` | **Phase 2** — load approved specs/ADRs → spec-loop via experts → quality gate → archive → record context |
| `skills/fix/` | **Bug fast-track** — diagnose root cause → pick the right expert → minimal fix → verify; no specs/ADR/gate; auto-escalates to `/my-goal` if it's bigger than a bug |
| `skills/spec-loop/` | Autonomous implement → **independent** fresh-subagent review vs FINAL specs → fix → repeat until matched (cap 6) |
| `skills/what-now/` | Read-only cheat-sheet — "you are here" on the pipeline + next command + skill inventory |
| `commands/*.md` | Thin slash-command wrappers (`/my-goal`, `/implement-specs`, `/fix`, `/spec-loop`, `/what-now`) |
| `docs/CLAUDE-snippet.md` | Paste-in block for a project's `CLAUDE.md` so Claude defaults to this flow |
| `install.sh` | Installs skills/commands into `~/.claude/` + all dependencies |

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
git clone git@github.com:nnguyenquangg/claude-code-spec-driven-development.git
cd claude-code-spec-driven-development
./install.sh          # symlinks into ~/.claude (default) — re-run after pulling updates
./install.sh --copy   # copy instead of symlink
```

Then install the dependencies above, and **restart Claude Code** so the new skills/commands appear.

## Per-project setup

1. `openspec init --tools claude` in the project root.
2. Paste `docs/CLAUDE-snippet.md` into the project's `CLAUDE.md` so Claude proactively drives the loop.

## Usage

```
/fix "P&L total ignores refunds"                 # small bug — diagnose, fix via the right expert, verify
/my-goal "add Excel export to the P&L report"    # feature — Phase 1: produce specs + ADRs, then stop for review
# review and approve the specs / ADRs
/implement-specs                                 # feature — Phase 2: run spec-loop until the code matches the specs
/what-now                                        # show where you are and what to run next
/spec-loop                                       # run the autonomous implement-until-match loop on the active change
```

## License

MIT — covers the skills and commands in this repo. `grill-me`, OpenSpec, and the `dev-workflows` / `fullstack-dev-skills` plugin packs are separate projects under their own licenses.
