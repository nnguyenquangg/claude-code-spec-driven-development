# claude-code-spec-driven-development

Claude Code skills, commands and subagents that take a task from plain language to a reviewed,
verified draft PR. Built on [OpenSpec](https://github.com/Fission-AI/OpenSpec).

This is the public part of my **harness engineering** setup: the workflow, the rules and the
reviewers, with nothing tied to one machine or one client. A private personal harness runs on
top of it (per-project context, hooks, scheduled loops) and is not shared.

## Commands

| Command | For | Does |
|---|---|---|
| `/task-analyzer <task>` | any task | sizes it, then runs the right lane below (or just reports, if you only asked) |
| `/fix <bug>` | a bug | root cause → failing test → minimal fix → verify → reviewers → draft PR |
| `/make-plan <goal>` | a feature | specs + ADRs, then **stops for your review** |
| `/implement-specs` | approved specs | builds until the code matches the specs → verify → reviewers → draft PR |
| `/autopilot <goal>` | "do it all" | plan + build in one run, an AI gate instead of yours, assumptions logged → draft PR |
| `/research <target>` | an idea | web + codebase brief: options, wireframe, flow |
| `/what-now` | lost | where you are and what to run next |

## The flow

```text
task ─► spec (OpenSpec, GIVEN / WHEN / THEN) ─► [your review, unless /autopilot]
     ─► build: failing test → smallest change → independent spec review → repeat
     ─► verify: lint · unit · e2e · call the API · ui-walkthrough
                  └ Playwright clicks through like a user, every write read back over the API,
                    every screenshot read and logged in review.md
     ─► review: diff · security · edge-case reviewers, in parallel, blocking findings fixed
     ─► open-pr: feature branch, commit, DRAFT PR with spec, checks, screenshots, verdicts
```

You review and merge the PR. Nothing is ever merged, pushed to the default branch or
force-pushed for you.

## Rules every lane follows

- A spec before code for anything beyond a one-file, no-judgement edit.
- Done means exercised for real, not just green unit tests. UI changes get a walkthrough.
- Never weaken, skip or delete a test to get green; expected values come from the spec.
- A change that makes a flag constant or a branch dead removes it end to end.
- The same failure three times → `diagnose` instead of another patch.

## Harness structure

The rules above are generic. What makes an agent good on *your* projects is context: the
project's vocabulary, its commands, the gotchas of its stack, the client's conventions. A harness
keeps that context outside the code repos, in layers that Claude Code loads through `@imports`:

```text
my-harness/
├── global/                 protocol.md (how to work) · standards.md (what reviewers check)
├── layers/<tech>/          standards.md · notes.md        e.g. nestjs, postgres, react
└── clients/<client>/       standards.md · notes.md        their conventions, environments
    └── projects/<project>/ context.md · glossary.md · standards.md · progress.md
                            decisions/ · specs/ · index.md (what a session in the repo loads)
```

`scripts/harness-scaffold.sh` creates it from `harness-template/`. It never overwrites a file and
never commits anything into your project repos:

```bash
scripts/harness-scaffold.sh init    ~/my-harness                    # global protocol + standards
scripts/harness-scaffold.sh global  ~/my-harness                    # ~/.claude/CLAUDE.md imports it
scripts/harness-scaffold.sh project ~/my-harness acme/shop nestjs postgres
scripts/harness-scaffold.sh link    ~/my-harness acme/shop ~/code/shop
```

`link` writes a `CLAUDE.local.md` into the repo that imports the project's `index.md`. The file
is git-ignored through `.git/info/exclude`, so the client's `.gitignore` stays untouched. Claude
Code asks once to allow the external import. Keep the harness folder private and writable only
by you: whatever is in it is read as instructions in every session. The imports hold absolute paths: after moving the harness folder, re-run `global` and `link`
and delete the old lines. Fill in `context.md` and `glossary.md` first. After
that, every repeated mistake becomes a line at the narrowest level where it is true.

## What's inside

- `skills/` — the commands above, plus `spec-loop`, `ui-walkthrough` (with a Playwright
  template), `open-pr` and `diagnose`.
- `agents/` — `diff-reviewer`, `security-reviewer`, `edge-case-reviewer` (read-only).
- `harness-template/` + `scripts/harness-scaffold.sh` — the empty harness above.
- `commands/` — slash-command wrappers. `docs/CLAUDE-snippet.md` — paste into a project's
  `CLAUDE.md` to make this the default workflow.

## Install

```bash
git clone git@github.com:nnguyenquangg/claude-code-spec-driven-development.git
cd claude-code-spec-driven-development && ./install.sh   # symlinks into ~/.claude
```

`--copy` copies instead of linking. `--force` replaces a same-named skill or agent that you
installed from elsewhere; by default those are skipped. Use `--force` once to upgrade an old
`--copy` install. The script also installs the OpenSpec CLI, the `grill-me` skill and two
optional plugin packs of stack experts. Restart Claude Code afterwards.

Per project, run `openspec init --tools claude`. For UI checks, install Playwright in that project
(`npm i -D playwright @playwright/test`). For draft PRs, the GitHub CLI must be logged in
(`gh auth login`).

MIT licensed. Dependencies keep their own licenses.
