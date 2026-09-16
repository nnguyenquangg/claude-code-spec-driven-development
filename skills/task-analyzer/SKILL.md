---
name: task-analyzer
description: Front door for a raw task — size it up (essence, type, scale, tags), read whether the user's own words mean "just look" or "go do it", then either hand back the analysis or drive the right amount of ceremony itself (trivial fix / the fix lane / the make-plan lane / the autopilot lane). Self-contained — no dev-workflows dependency. Different from /research (which investigates an external topic; this looks at the task itself). Triggers on "task-analyzer", "analyze this task", "how big is this", or any bare requirement with no other command named.
---

# task-analyzer — size up the task, then do exactly as much as asked

You are often the **first thing invoked** on a new ask, before the user has decided which lane fits. Two jobs, always in this order: (1) analyze the task, (2) read from the user's own words whether they want the analysis or the work done — then act accordingly.

## Step 0 — Read intent from the user's own words (decides everything after)

- **Exploratory wording** ("tìm hiểu thử", "phân tích xem", "research this", "look into", "what would it take", "so sánh xem") → **Analyze-only.** Do Steps 1-4, output the report, **stop**. If the ask is really about an external topic/idea rather than sizing up work, point to `/research` instead.
- **Action wording** ("làm đi", "triển khai", "implement", "fix this", "build it", "code luôn") → Do Steps 1-4, then **Step 5: act** — drive the work yourself through the matched lane, no further check-in.
- **Neither is clear** (a bare description of a problem or a want, no verb telling you which) → do Steps 1-4, present the recommended lane, and ask **one short question**: analyze only, or proceed? This is the one fork worth asking about — guessing wrong either wastes their time (asked again) or does an unwanted build (expensive to undo).

## Step 1 — Understand the essence

Map the request to its fundamental purpose, not the surface wording:

| Surface wording | Fundamental purpose |
|---|---|
| "fix this" / "broken" / "throwing" | Problem solving, root cause analysis |
| "add" / "implement" / "build" | Feature addition, value delivery |
| "refactor" / "clean up" / "extract" | Quality improvement, maintainability |
| "update" / "bump" / "rename" | Change management, consistency |
| "why does X" / "how does X work" | Understanding, not yet a change |

If nothing matches, state the fundamental purpose explicitly in your own words before continuing.

## Step 2 — Classify type & estimate scale

| Type | Characteristics |
|---|---|
| Fix | Something that should work doesn't; a defined wrong behavior |
| Implementation | New code, new capability, nothing broken |
| Refactoring | Behavior-preserving structural change |
| Design | An architecture/approach decision, not yet code |
| Quality | Tests, review, hardening on existing behavior |

| Scale | File count | Indicators |
|---|---|---|
| Trivial | 0-1 | Typo, one-liner, no judgment call |
| Small | 1-2 | Single function/component, no design decision |
| Medium | 3-5 | Multiple related components, some open decisions |
| Large | 6+ | Cross-cutting, architecture impact, contract/schema change |

Ground the estimate in the actual codebase (`Grep`/`Glob`/`Explore`) — don't guess file count from the request text alone when a quick look can confirm it.

## Step 3 — Pick the lane (matters only in do-mode)

| Situation | Lane |
|---|---|
| Trivial | Just do it directly — no ceremony, no other skill |
| Small/medium bug or well-scoped tweak, no real design decision | **`fix`** lane: diagnose → pick expert → minimal fix → ordered verify (e2e → unit → API → UI+screenshot) → memory only if non-obvious → report |
| Medium/large feature or change with open decisions, but they're resolvable with sensible low-risk defaults (or the user said "busy", "do it all", "no need to review each step") | **`autopilot`** lane: plan (specs+ADRs), AI review gate, build via `spec-loop`, quality gate, archive, memory, one review packet — never commits |
| Decisions only the user should make (irreversible, ambiguous business rule, large blast radius), or the user explicitly asked for a plan/spec first | **`make-plan`** lane: stop for human review before any code |
| The ask is itself unscoped — an idea, not yet a task | **`research`** first, then re-run this analysis on its recommendation |

When two lanes look plausible, pick the more cautious one and say why in one line.

## Step 4 — Tag & recommend expert(s)

Extract tags from the request + the touched code's stack (file type, framework, layer — from the file itself, `package.json`, `prisma`, host `CLAUDE.md`). Discover experts from skills **actually present** in this environment (list what's available; never name one that isn't installed). Pick a primary + 0-2 supporting, one line of reasoning each.

## Step 5 — Act

- **Analyze-only** → output exactly this, then stop:
  ```
  ## Task analysis
  Essence: <one line>
  Type: <fix|implementation|refactoring|design|quality>
  Scale: <trivial|small|medium|large> (~N files)
  Tags: <tag, tag, ...>
  Recommended lane: <trivial|fix|make-plan|autopilot|research> — <why, one line>
  Recommended expert(s): <primary> (+ <supporting>) — <why, one line>
  ```
- **Do-mode** → before touching code, read the project's `CLAUDE.md` (root + any nested one in the directories you'll touch) and check project memory (`memory/` + `MEMORY.md`) for anything relevant to this task. Then **follow the matched lane's own SKILL.md end-to-end as if the user had invoked it directly** (`fix`, `autopilot`, or `make-plan`), passing it this step's essence/type/scale/tags/expert output so it doesn't redo that analysis. That lane's own guardrails still apply in full — picking the `make-plan` lane still means **stop for review, no production code**, even though you got there via `task-analyzer`.

## Guardrails

- One command, adaptive depth — the user should not have to know in advance whether this is a `/fix`-sized or `/autopilot`-sized ask.
- Ask exactly once, only at the Step 0 fork, only when wording genuinely doesn't say which. Never ask again once a lane is chosen.
- Never invent an unavailable expert skill.
- Analyze-only means **no code, no tests run, no memory writes** — that's the downstream lane's job, not this one's, when the ask was only to look.
