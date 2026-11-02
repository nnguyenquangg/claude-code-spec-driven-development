---
name: task-analyzer
description: Front door for a raw task - size it up (essence, type, scale, tags), read whether the user's own words mean "just look" or "go do it", then either hand back the analysis or drive the matching lane itself (direct / fix / make-plan / autopilot / research). Different from /research (which investigates an external topic; this looks at the task itself). Triggers on "task-analyzer", "analyze this task", "how big is this", or any bare requirement with no other command named.
---

# task-analyzer: size the task, then do exactly as much as asked

You are often the first thing invoked on a new ask, before the user has decided which lane
fits. Two jobs, in this order: size the task, then do exactly as much as the words ask.

## 1. Intent, from the user's own words (decides everything after)
- **Look-only** wording ("look into", "analyze", "what would it take", "how big", "compare"):
  steps 2–4, print the analysis, stop. Reading only: no edits, no long-running checks, no
  memory writes. If the ask is really about an external topic rather than the work, point to
  `/research`.
- **Do** wording ("do it", "fix", "implement", "build", "ship it"): steps 2–5, no further
  check-in.
- **Neither** (a bare description of a problem or a want): treat it as do-wording. The user
  invoked this skill to hand the task over, so never ask "analyze or proceed?". Questions about
  the requirement itself belong to `grill-me`; a decision only the user can make still goes to
  the `make-plan` lane, which stops for review.
- **A spec is always written** for anything beyond trivial, whatever the wording: an OpenSpec
  change (proposal + delta specs with GIVEN / WHEN / THEN scenarios) is the audit trail of what
  was asked and what was decided. With do-wording the spec is written and the build continues;
  when the user asked for specs first, it is written and stops for review; with look-only
  wording nothing is written, the analysis only names the spec that would be. No
  `openspec/` in the project yet: run `openspec init --tools claude` first (it only adds the
  `openspec/` folder); if the user does not want OpenSpec there, write the same sections
  (why, scope, GIVEN / WHEN / THEN scenarios, decisions) into the PR description instead.

## 2. Orient
- `openspec list --json`: a change already in flight for this goal means the task is a
  continuation; resume it (`/implement-specs`) instead of starting over.
- Read the project's `CLAUDE.md` (root + any nested one where the work lands) and project
  memory for anything relevant: vocabulary, conventions, gotchas, architecture decisions.
- Locate the code the task touches (`Grep` / `Glob` / the `Explore` agent): the scale is
  counted, not guessed.
- Do-mode only: run the project's fast checks (lint / unit tests as the project defines them).
  Red before you touched anything makes "baseline green" the first unit of work.

## 3. Size
- **Essence**: the fundamental purpose behind the wording. "broken / throwing / not working"
  is a fix (a defined wrong behaviour); "add / implement / build" is an implementation;
  "refactor / clean up / extract" is behaviour-preserving; "why / how does X work" is
  understanding, not yet a change; an architecture choice is design.
- **Type**: fix | implementation | refactoring | design | quality | understanding.
- **Scale** by files actually touched: trivial: at most one file and no judgement call; small: 1–2
  files, one function or component, with a judgement call or a test to write; medium 3–5 with some open decisions; large 6+, cross-cutting, or
  touching a contract, schema or public API. A change that spans more than one repo, or touches
  a contract or API shape, is never trivial or small.
- **Tags & experts**: tags from the request and the touched code's stack (file types,
  framework, layer). Pick a primary expert skill + 0–2 supporting from the skills actually
  installed here, one line of reasoning each; never name one that is not present.

## 4. Lane
| Situation | Lane |
|---|---|
| Trivial | **direct**: edit, run the project's checks, exercise it once for real |
| Small or medium defect, no design decision | **`fix`**: `diagnose` for the cause, failing test first, smallest change, verify for real, reviewers when non-trivial |
| Medium or large change whose open decisions have conservative defaults, or the user said "busy", "do it all" | **`autopilot`**: specs + AI review gate + build, assumptions logged |
| A decision only the user can make (irreversible, business rule, large blast radius), or the user asked for a plan/spec first | **`make-plan`**: specs + ADRs, stop for review |
| The ask is itself unscoped (an idea, not yet a task) | **`research`** first, then re-run this analysis on its recommendation |

Two lanes plausible: take the more cautious one and say why in one line.

Print exactly this block (look-only stops here):
```
## Task analysis
Essence: <one line>
Type: <fix|implementation|refactoring|design|quality|understanding>
Scale: <trivial|small|medium|large> (~N files: <paths>)
Repos / contracts touched: <one repo, none | list>
In-flight change: <none | openspec change name>
Lane: <direct|fix|make-plan|autopilot|research> — <why, one line>
Spec: <trivial, none | will be written: openspec/changes/<name> | exists: <name>>
Expert(s): <primary> (+ <supporting>) — <why, one line>
```

## 5. Act (do-mode)
- **Review comment** (the task is a reviewer's note on an open PR/MR): before editing, trace
  what the requested change makes redundant across every repo it touches: a value that becomes
  constant, a branch that can no longer run, a field nobody reads. Remove those end to end in
  the same round (contract, producer, every consumer, docs, tests) and say so in the reply,
  rather than applying the words literally and waiting for the next comment.
- **Follow the lane's own SKILL.md end to end** (`fix`, `autopilot`, `make-plan`, `research`)
  as if the user had invoked it, passing this analysis so it is not redone. That lane's
  guardrails apply in full: `make-plan` still stops for review with no production code.
- **Review step is not optional**: anything beyond trivial, review-fix rounds included, ends
  with the three reviewers run in parallel (one message, three Agent calls): `diff-reviewer`
  (task/spec, project rules, leftovers), `security-reviewer`, `edge-case-reviewer`, on the full
  diff of every repo touched, each given the task, the base branch, every repo path and the
  OpenSpec change name. When the change is UI-visible, launch the `walkthrough-runner` agent in
  the same parallel message (the implementer has prepared the servers, data and `walk.mjs`), so
  reading the screenshots does not block. Done needs all four clean on the same frozen diff, the
  walkthrough's own verdict deciding. Any blocking finding, from a reviewer or the walkthrough, is
  fixed, then the three reviewers re-run and the walkthrough re-runs when the fix touches a walked
  screen; a BLOCKED walk is an access problem, not a code fix. Skipping needs a written reason in
  the final report.
- **Done** means the project's checks pass and the behaviour was exercised for real (a request,
  a command, the page), not only unit tests. A UI-visible change also gets a `ui-walkthrough`: a
  non-trivial one as the `walkthrough-runner` agent at the review step above, a trivial one (the
  `direct` lane, no review step) walked inline with the `ui-walkthrough` skill.

## Guardrails
- One command, adaptive depth: the user should not have to know in advance whether this is a
  `/fix`-sized or `/autopilot`-sized ask.
- Never ask whether to analyze or proceed; read it from the words.
- Never invent an unavailable expert skill.
- Look-only means no code, no long-running checks, no memory writes.
