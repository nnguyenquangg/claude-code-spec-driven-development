# claude-code-spec-driven-development

> **A few commands, not thirty.** Describe the work in plain language; the agent picks the right specialist skills and drives it from spec to verified code.

A spec-driven-development (SDD) toolkit for **Claude Code**, built on [OpenSpec](https://github.com/Fission-AI/OpenSpec).

## What you run

| Command | Use it for | What it does |
|---------|-----------|--------------|
| `/fix` | a bug | diagnose root cause → minimal fix → verify (auto-escalates to `/make-plan` if it needs a design change) |
| `/make-plan` | a feature | clarify → specs + ADRs → **stop for your review** |
| `/implement-specs` | approved specs | build via `spec-loop` until the code matches the specs |
| `/autopilot` | "I'm busy, do it all" | `/make-plan` + `/implement-specs` in one hands-off run, no review gate — logs its assumptions and hands back one review packet (never commits) |

A typo or one-liner needs no command — just ask.

Most toolkits hand you dozens of agents and make you choose. Here, each command analyzes the task and invokes the right specialists under the hood — `grill-me`, `task-analyzer`, the stack experts (`nestjs-expert`, `postgres-pro`, `react-expert`, …), `spec-loop`, `code-verifier` — so you get full depth with nothing to memorize.

## The pipeline (two phases, human review in between)

```text
╭─ PHASE 1 · Plan & Specify ──────────────────  /make-plan "<goal>"
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

Most AI coding loops blur planning and building, so unverified assumptions get written into code before anyone catches them. The split puts a deliberate **human review gate** between deciding *what* to build (`/make-plan`, no code) and building it (`/implement-specs`) — you approve the specs + ADRs before a line is written. `/make-plan` also calibrates how hard it interrogates you to how clear the request is — light for a well-scoped task, thorough for an ambiguous one — and you can adjust that depth anytime.

(In a hurry? `/autopilot` runs both phases back-to-back and replaces the human gate with an independent AI review of the specs — see the table above.)

## What's in this repo

| Path | What |
|------|------|
| `skills/` | The skills behind the commands — the four entry points above (`autopilot`, `make-plan`, `implement-specs`, `fix`), plus two helpers they call: `spec-loop` (the implement → independent-review → fix loop, cap 6) and `what-now` (read-only "where am I" cheat-sheet) |
| `commands/` | Thin slash-command wrappers, one per skill |
| `docs/CLAUDE-snippet.md` | Paste-in block for a project's `CLAUDE.md` so Claude defaults to this flow |
| `install.sh` | Installs the skills/commands into `~/.claude/` + all dependencies |

## Dependencies (auto-installed by `install.sh`)

`install.sh` installs all of these for you (and is idempotent — skips anything already present). They are **not** vendored into this repo, just installed from their own sources:

| Dependency | Source | Used by | Manual command |
|------------|--------|---------|----------------|
| **OpenSpec CLI** | npm `@fission-ai/openspec` | Steps 3/7 (propose/archive) | `npm install -g @fission-ai/openspec@latest` |
| **grill-me** skill | [@mattpocock](https://github.com/mattpocock/skills) (MIT) | Step 2 (clarify) | `npx skills add mattpocock/skills --skill=grill-me -y -g` |
| **dev-workflows** plugin | gh `shinpr/claude-code-workflows` | Step 4/6 (`task-analyzer`, `code-verifier`, `quality-fixer`) | `claude plugin marketplace add shinpr/claude-code-workflows && claude plugin install dev-workflows@claude-code-workflows` |
| **fullstack-dev-skills** plugin | gh `jeffallan/claude-skills` | Step 4 experts (`nestjs-expert`, `postgres-pro`, `react-expert`, `typescript-pro`, …) | `claude plugin marketplace add jeffallan/claude-skills && claude plugin install fullstack-dev-skills@fullstack-dev-skills` |

After install, run `openspec init --tools claude` in each project. `make-plan` only ever picks experts that are actually present in your environment, so the two plugin packs are recommended but not strictly required.

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
/fix "P&L total ignores refunds"

/make-plan "add Excel export to the P&L report"   # → review the specs + ADRs, then:
/implement-specs

/autopilot "migrate the export job to a queue"    # both phases in one go, then review the packet

/what-now                                         # lost? this orients you
```

## License

MIT — covers the skills and commands in this repo. `grill-me`, OpenSpec, and the `dev-workflows` / `fullstack-dev-skills` plugin packs are separate projects under their own licenses.
