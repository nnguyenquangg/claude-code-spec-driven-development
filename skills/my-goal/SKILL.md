---
name: my-goal
description: Orchestrator for the spec-driven pipeline — takes a plain-language goal and autonomously drives the right sub-skills end to end (grill-me → /opsx:propose → spec-loop → /opsx:archive), with the number of human checkpoints chosen ADAPTIVELY based on how clear the task is. Resume-aware. Use when the user states a goal and wants the whole pipeline run for them. Triggers on "my-goal", "/my-goal", "build this for me", "drive the whole flow", "tự lo từ đầu tới cuối".
---

# my-goal — adaptive orchestrator for the spec-driven pipeline

The user gives a goal in plain language. You run the whole pipeline for them by composing the existing sub-skills. **How many times you stop to check in is decided by how clear the task is** — clear tasks run hands-off, fuzzy tasks get interrogated first. Always tell the user which lane you picked and let them override.

Sub-skills you compose (invoke via the Skill tool, or run the slash command):
- `grill-me` — interview the user to firm up an unclear plan
- `openspec-explore` / `/opsx:explore` — think through a fuzzy/large problem
- `openspec-propose` / `/opsx:propose` — generate proposal + design + specs + tasks
- `spec-loop` — autonomously implement → independent review vs final specs → fix → repeat until matched
- `openspec-archive-change` / `/opsx:archive` — fold deltas into specs and close the change

## Step 0 — Resume check (always first)
Detect where this goal already is so you never restart from scratch:
```bash
openspec list --json
```
- If a change clearly matching this goal is **in progress with unchecked tasks** → jump straight to the **Implement** phase (spec-loop).
- If its tasks are **all checked but not archived** → jump to **Archive**.
- If it's **already archived** → tell the user it's done; ask if this is a new follow-up goal.
- Otherwise → start fresh at Step 1.

## Step 1 — Assess clarity, pick the lane
Rate the goal and **announce the rating + chosen lane** before doing anything. Base it on: are the requirements/constraints concrete? is there an existing spec or code precedent? how big is the blast radius?

| Lane | Looks like | grill-me | explore | propose | 🚦 Checkpoint | spec-loop |
|------|-----------|----------|---------|---------|--------------|-----------|
| 🟢 **Clear** | concrete, scoped, has precedent (e.g. "add `phone` to client API, required, E.164") | skip | skip | lightweight | **none** — run straight through | yes |
| 🟡 **Medium** | known shape, some open decisions (e.g. "add Excel export to P&L report") | a few questions | skip | full | **1 gate** after propose | yes |
| 🔴 **Fuzzy / large** | vague or cross-cutting (e.g. "build a tax-reminder system") | grill hard | yes | full | **1 gate** after propose (may also pause mid-grill) | yes |

Rules for the rating:
- State it plainly: *"Mình xếp task này là 🟡 — sẽ hỏi vài câu rồi propose, dừng 1 lần cho bạn duyệt specs."*
- The user can override anytime ("full auto đi" → drop to 🟢 behavior; "grill kỹ vào" → bump to 🔴).
- When unsure between two lanes, pick the **more cautious** one — a wrong-spec spec-loop wastes far more than one extra question.

## Step 2 — Clarify (lane-dependent)
- 🟢 → skip.
- 🟡 → invoke `grill-me` but keep it short (only the genuinely open decisions; anything answerable from the codebase, read the codebase instead).
- 🔴 → `/opsx:explore` to map the problem, then `grill-me` thoroughly until shared understanding.

## Step 3 — Propose
Run `openspec-propose` / `/opsx:propose "<goal, enriched with what you learned>"` to scaffold the change and generate proposal/design/specs/tasks.

## Step 4 — Tech analysis → pick the expert skills (all lanes)
Now that the work is concrete, figure out **which specialist skills should drive the coding** — don't just hand everything to a generic implementer.

1. **Analyze the task.** Run `dev-workflows:task-analyzer` (essence / type / scale / tags) against the change's `proposal.md` + `tasks.md` + the files it will touch. Also read the change's tech footprint: the stack from the host CLAUDE.md / `package.json` / `prisma` schema / file extensions involved.
2. **Discover what's available — do NOT hardcode.** Match the task's tags + stack against the skills actually present in THIS environment (the skill list in context: e.g. `fullstack-dev-skills:nestjs-expert`, `:postgres-pro`, `:react-expert`, `:typescript-pro`, `:api-designer`, `:security-reviewer`, `:test-master`, `nextjs-developer`, `dev-workflows:*`, etc.). Never name a skill that isn't available here.
3. **Select a small set:** one **primary** expert (the main stack of the change) + 0–2 **supporting** experts (e.g. a DB expert for a migration, a security/test expert when warranted). Keep it minimal — 3 max. State each pick in one line with the reason.
   - Example (dynatax-backend NestJS endpoint hitting Postgres): primary `fullstack-dev-skills:nestjs-expert`, supporting `fullstack-dev-skills:postgres-pro` + `fullstack-dev-skills:test-master`.
   - Example (dynatax-web Next.js page + API route): primary `fullstack-dev-skills:nextjs-developer` (or `react-expert`), supporting `fullstack-dev-skills:typescript-pro`.

## Step 5 — Checkpoint (lane-dependent) — specs **and** experts
- 🟢 → no gate; the goal *is* the spec. Announce the chosen experts and proceed.
- 🟡 / 🔴 → show the user the proposal + tasks **and the proposed expert lineup**, ask one focused question: **"Specs final + dùng các expert này ok? (chỉnh gì không?)"** Apply edits (incl. swapping experts) if any, then proceed. This is the ONLY mandatory stop.

## Step 6 — Implement via the chosen experts (hands-off)
Invoke `spec-loop` for the change, **telling it which expert skills to use as the implementer**. Two ways spec-loop applies them — pick per task size:
- **Load guidance (default, small/medium):** invoke the selected expert skill(s) via the Skill tool so their conventions/patterns are in context, then implement following them + the host CLAUDE.md.
- **Delegate to expert sub-agents (large / parallelisable):** dispatch implementation chunks to those experts as sub-agents (`Agent` tool, `subagent_type` = the expert) and integrate their output.
spec-loop still loops implement → **independent** fresh-context review against the finalized specs → fix → repeat (cap 6), then quality gate. The reviewer stays separate from the implementing experts so it doesn't rubber-stamp. Do NOT babysit with extra check-ins.

## Step 7 — Archive
When spec-loop reports success, run `openspec-archive-change` / `/opsx:archive` to fold the delta specs into `openspec/specs/` (this captures *what* the system now does). If spec-loop hit its cap or a spec ambiguity, skip archiving and hand back to the user.

## Step 8 — Capture session context (AUTOMATIC — do not skip)
So the next session understands the change without re-reading the code, record the **non-obvious** outcome to the project's existing auto-memory (`<project>/memory/` + `MEMORY.md`) — same mechanism already in use, follow its rules exactly:
- Write/update ONE memory file capturing the **logic decision(s) + why**, the affected flow/files at a high level, and any gotcha. Type `project` (or `feedback` if it's a working-preference correction). Convert relative dates to absolute.
- Capture only what code/git/specs do NOT already make obvious — the *reasoning*, trade-offs, cross-cutting effects, "why it's done this way". Do NOT dump code structure, file lists, or a git-diff restatement.
- **Dedupe first:** if a related memory exists, update it instead of creating a duplicate; link related notes with `[[name]]`. Add a one-line pointer in `MEMORY.md` for any new file.
- If the run stopped early (cap / ambiguity), still record what was done, what's left, and the blocker so the next session can resume.
- Then give the user a tight summary: goal → lane chosen → **experts used** → specs satisfied (and where) → quality gate result → archived → **memory note written** (filename).

## Guardrails
- Announce the lane and every phase transition in one line each — the user should always know where in the pipeline you are without asking.
- Honest stops only: stop on the lane's planned checkpoint, on a genuine spec ambiguity, or on spec-loop's safety cap. Never silently loop, never fake completion.
- Respect the host project's CLAUDE.md (conventions, and "don't run tsc/prisma yourself" in this workspace).
- One goal at a time. If the user fires a second `/my-goal` while one is mid-flight, ask which to continue or run them as separate OpenSpec changes.
