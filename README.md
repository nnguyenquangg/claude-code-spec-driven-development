# claude-code-spec-driven-development

> **A few commands, not thirty.** Describe the work in plain language; the agent picks the right specialist skills and drives it from spec to verified code.

A spec-driven-development (SDD) toolkit for **Claude Code**, built on [OpenSpec](https://github.com/Fission-AI/OpenSpec).

## What you run

| Command | Use it for | What it does |
|---------|-----------|--------------|
| `/task-analyzer` | not sure which track fits | sizes up the task, then either hands back the analysis or drives the matched track itself — no need to pick the others yourself |
| `/research` | an idea / unknown | investigate via web + codebase, output a brief: sources, options, a wireframe, and a step-by-step flow (feeds `/make-plan`) |
| `/fix` | a bug | diagnose root cause → failing test → minimal fix → verify for real → three reviewers when non-trivial (auto-escalates to `/make-plan` if it needs a design change) |
| `/make-plan` | a feature | clarify → specs + ADRs → **stop for your review** |
| `/implement-specs` | approved specs | build via `spec-loop` until the code matches the specs |
| `/autopilot` | "I'm busy, do it all" | `/make-plan` + `/implement-specs` in one hands-off run, an AI gate instead of the human one — logs its assumptions, runs the three reviewers and hands back one review packet (never commits) |

A typo or one-liner needs no command — just ask.

Most toolkits hand you dozens of agents and make you choose. Here, `task-analyzer` sizes up the task and picks the track for you if you don't already know it, then each command analyzes further and invokes the right specialists under the hood — `grill-me`, the stack experts (`nestjs-expert`, `postgres-pro`, `react-expert`, …), `spec-loop`, `diagnose`, `ui-walkthrough`, the three reviewers — so you get full depth with nothing to memorize.

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
│   3  Quality gate        lint / build / test + three parallel reviewers
│   4  Archive             /opsx:archive
│   5  Record context      logic + why → memory
╰──────────────────────────────────────────────────────────────
```

### Why two phases?

Most AI coding loops blur planning and building, so unverified assumptions get written into code before anyone catches them. The split puts a deliberate **human review gate** between deciding *what* to build (`/make-plan`, no code) and building it (`/implement-specs`) — you approve the specs + ADRs before a line is written. `/make-plan` also calibrates how hard it interrogates you to how clear the request is — light for a well-scoped task, thorough for an ambiguous one — and you can adjust that depth anytime.

(In a hurry? `/autopilot` runs both phases back-to-back and replaces the human gate with an independent AI review of the specs — see the table above.)

### Rules every lane follows

- **A spec for anything non-trivial.** Every change beyond a one-file, no-judgement edit gets an OpenSpec change with GIVEN / WHEN / THEN scenarios before code — in `/fix` and `/autopilot` too. It is the audit trail of what was asked and decided; tests follow its scenarios and the reviewers check the diff against it.
- **Done means exercised for real.** Checks green *and* the behaviour run for real: the API called, the command run. A UI-visible change gets a `ui-walkthrough`: a throwaway Playwright script clicks through like a user, every write is awaited and read back over the real API, and every screenshot is actually read.
- **Three reviewers before done.** `diff-reviewer` (does what was asked, project rules, leftovers the change made redundant), `security-reviewer` and `edge-case-reviewer` run in parallel on the full diff of every repo touched. Blocking findings get fixed and the reviewer re-run.
- **No green by cheating.** Never weaken, skip or delete a test, or silence a lint/type rule. Expected values come from the spec, never recomputed the way the code computes them.
- **Leave nothing redundant.** When a change makes a flag constant or a branch unreachable, it is removed end to end (contract, producers, consumers, docs, tests), not hard-coded.
- **Repeated failure → `diagnose`.** The same failure a third time stops the patching: reproduce → minimise → hypothesise → instrument → fix → guard.

## What's in this repo

| Path | What |
|------|------|
| `skills/` | The skills behind the commands — the entry points above (`task-analyzer`, `research`, `autopilot`, `make-plan`, `implement-specs`, `fix`), plus the helpers they call: `spec-loop` (the implement → independent-review → fix loop, cap 6), `diagnose` (disciplined debugging loop), `ui-walkthrough` (browser walkthrough that verifies through the real API, with a Playwright template) and `what-now` (read-only "where am I" cheat-sheet) |
| `commands/` | Thin slash-command wrappers for the entry points, `spec-loop` and `what-now` |
| `agents/` | The three read-only reviewer subagents: `diff-reviewer`, `security-reviewer`, `edge-case-reviewer` |
| `docs/CLAUDE-snippet.md` | Paste-in block for a project's `CLAUDE.md` so Claude defaults to this flow |
| `install.sh` | Installs the skills, commands and agents into `~/.claude/` + all dependencies |

## Dependencies (auto-installed by `install.sh`)

`install.sh` installs all of these for you (and is idempotent — skips anything already present). They are **not** vendored into this repo, just installed from their own sources:

| Dependency | Source | Used by | Manual command |
|------------|--------|---------|----------------|
| **OpenSpec CLI** | npm `@fission-ai/openspec` | `/make-plan` propose, `/implement-specs` archive | `npm install -g @fission-ai/openspec@latest` |
| **grill-me** skill | [@mattpocock](https://github.com/mattpocock/skills) (MIT) | `/make-plan` clarify | `npx skills add mattpocock/skills --skill=grill-me -y -g` |
| **dev-workflows** plugin | gh `shinpr/claude-code-workflows` | optional helpers (`code-verifier` as spec-loop's reviewer, `technical-designer` for ADRs, `quality-fixer`) | `claude plugin marketplace add shinpr/claude-code-workflows && claude plugin install dev-workflows@claude-code-workflows` |
| **fullstack-dev-skills** plugin | gh `jeffallan/claude-skills` | implementation experts (`nestjs-expert`, `postgres-pro`, `react-expert`, `typescript-pro`, …) | `claude plugin marketplace add jeffallan/claude-skills && claude plugin install fullstack-dev-skills@fullstack-dev-skills` |

`ui-walkthrough` needs Playwright in the project under test (`npm i -D playwright @playwright/test && npx playwright install chromium`); it is not installed globally. After install, run `openspec init --tools claude` in each project. `make-plan` only ever picks experts that are actually present in your environment, so the two plugin packs are recommended but not strictly required.

## Install

```bash
git clone git@github.com:nnguyenquangg/claude-code-spec-driven-development.git
cd claude-code-spec-driven-development
./install.sh          # symlinks into ~/.claude (default) — re-run after pulling updates
./install.sh --copy   # copy instead of symlink
./install.sh --force  # also replace a same-named skill/command/agent you installed from elsewhere
```

Upgrading a `--copy` install made before this installer kept a manifest: re-run with `--force` once. By default the installer leaves alone any existing skill, command or agent with the same name that it did not put there, and prints `skip`. Then **restart Claude Code** so the new skills, commands and agents appear.

## Per-project setup

1. `openspec init --tools claude` in the project root.
2. Paste `docs/CLAUDE-snippet.md` into the project's `CLAUDE.md` so Claude proactively drives the loop.

## Usage

```
/task-analyzer "the export button sometimes shows the wrong total"   # not sure which track? start here
                                                                       # → sizes it up, then drives /fix itself

/fix "P&L total ignores refunds"

/make-plan "add Excel export to the P&L report"   # → review the specs + ADRs, then:
/implement-specs

/autopilot "migrate the export job to a queue"    # both phases in one go, then review the packet

/what-now                                         # lost? this orients you
```

## License

MIT — covers the skills, commands and agents in this repo. `grill-me`, OpenSpec, and the `dev-workflows` / `fullstack-dev-skills` plugin packs are separate projects under their own licenses.
