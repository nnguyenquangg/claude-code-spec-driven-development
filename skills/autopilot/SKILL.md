---
name: autopilot
description: Full-auto end-to-end — fuses /make-plan and /implement-specs into one hands-off run with NO human review gate in the middle. Plans (specs + ADRs), self-reviews them with an independent sub-agent in place of the human gate, makes sensible default assumptions for anything it would normally ask (logging each one), builds via spec-loop through the right experts, runs the quality gate, archives, records memory, and hands back a single review packet. Ends by committing on a feature branch and opening a draft PR with the verification evidence; never merges, never pushes the default branch. Use when the user is busy and wants the whole thing done, reviewing only the final output. Triggers on "autopilot", "/autopilot", "do it all", "just build it end to end", "I'm busy, handle it", "full auto".
---

# autopilot — plan + build, hands-off, review only the output

The user is busy and wants the whole change done in one shot. This fuses the two SDD phases with **no human review gate between them** — it plans, builds, and verifies autonomously, then hands back one review packet. The user reviews the *output*, not the process.

Removing the human gate raises the risk of building the wrong thing, so two safeguards replace it: an **independent AI review of the specs before any code**, and a loud **assumptions log** for every decision that would normally have been a question. Never silently guess on something important — guess, then surface it.

## Step 1 — Rate clarity & set confidence
Rate the request 🟢 clear / 🟡 medium / 🔴 fuzzy (concrete constraints? precedent in the codebase? blast radius?). Announce it. This sets how many assumptions you'll have to make and the confidence note in the final packet. You proceed in all three cases — you do **not** stop to interview the user (they're away) — but 🔴 means a denser assumptions log and a "low confidence — review carefully" flag.

## Step 2 — Plan (specs + ADRs + experts)
Do `/make-plan`'s planning work, but **do not stop**:
- Scaffold the change and generate `proposal.md` / `design.md` / `tasks.md` / delta specs (`/opsx:propose`).
- Resolve open design decisions yourself by picking the **most sensible, lowest-risk default** (prefer existing codebase patterns, conventions in CLAUDE.md, and reversible choices). Record **every** such decision in an **Assumptions** list (what you assumed + why + how to change it).
- Shape the delta specs as **vertical slices**: one requirement per piece of observable behaviour delivered end to end, each with GIVEN / WHEN / THEN scenarios whose expected values come from the request or a worked example, never from how the code will compute them. `tasks.md` follows the requirements in order. A bug fix starts with "reproduce: failing test for <bug>".
- Write ADR(s) for the significant/architectural decisions.
- Analyze the task: if `task-analyzer` already dispatched here, reuse its essence/type/scale/tags/expert output; otherwise run `task-analyzer`'s §3 Size (essence, type, scale, tags & experts) yourself now, then pick the implementation experts from that (primary + ≤2 supporting, from skills available here).

## Step 3 — AI review gate (replaces the human gate — REQUIRED)
Before writing any production code, spawn an **independent fresh-context sub-agent** (`general-purpose`, or a spec/plan-review agent if one is installed) to sanity-check the plan. Give it the request, the proposal/specs/ADRs, and the Assumptions list. Ask it to flag, as STRICT findings: contradictions, missing requirements implied by the request, assumptions that are risky/likely-wrong, and anything that would make the build go sideways. Apply its fixes. Only proceed once it has no blocking findings. This is the safety net for the missing human review.

## Step 4 — Build (hands-off)
**Read the project's `CLAUDE.md` first** (root + any nested one in the directories you'll touch) — it is the source of truth for this repo's conventions, flow, and do/don't rules; everything you implement must follow it. Then run `spec-loop` for the change, implementing **as the chosen experts** — load each expert's Skill into context via the Skill tool, or for larger/parallel work dispatch a **`general-purpose` agent per disjoint file-set** that loads the expert Skill itself (the `Agent` tool's `subagent_type` is a real agent type like `general-purpose`, **never** a Skill name; lock shared contracts before parallelising). spec-loop loops implement → **self-verify in order** (step 1b: e2e tests if any → unit tests → API calls for a backend change → `ui-walkthrough` for a UI change) → independent review vs the finalized specs + ADRs + CLAUDE.md → fix → repeat (cap 6); its **UI walkthrough** (step 2b) exercises UI-affecting requirements in a real browser through the real API, each write read back and every screenshot actually read — a captured-but-unread screenshot doesn't count. The same failure a third time → stop patching and run `diagnose`. Then run the project's quality gate (lint/build/test as available; respect any commands the host CLAUDE.md leaves to CI).

## Step 4b — Final walkthrough + three reviewers (REQUIRED)
- `spec-loop` already ran the three reviewers **and**, for a UI-visible change, the `walkthrough-runner` agent at its final gate (spec-loop step 4), over every flow the run changed. This step is the outer confirmation, not a second pass: the run is not done while any of them has an open blocking finding.
- **Only if code changed after that gate** (a fix applied during this step) re-launch the affected checks in **one message** (parallel Agent calls): `diff-reviewer`, `security-reviewer`, `edge-case-reviewer`, plus the `walkthrough-runner` agent when the fix touched a walked screen, on the full diff of every repo touched, now also giving the reviewers the Assumptions list. A BLOCKED walk is an access problem, not a code fix.
- Done needs all four clean on the same frozen diff, the walkthrough's own verdict deciding. Skipping needs a written reason in the packet.

## Step 5 — Archive & record memory
When spec-loop reports success and quality is green, run `/opsx:archive`, then record the non-obvious logic + why to the project memory (`memory/` + `MEMORY.md`), deduping as usual.

## Step 5b — Open the draft PR
Run the `open-pr` skill: feature branch, one commit, push, draft PR whose body carries the spec, the checks run, the walkthrough table and its screenshots, the reviewer verdicts and the **Assumptions** list. No remote, no `gh` auth, or the user said "local only": stop after the local commit and say so in the packet.

## Step 6 — Hand back ONE review packet
Stop and present a single, skimmable packet for when the user returns:
```
🎯 Goal
⚠️  Assumptions I made (please confirm) — each with why + how to change it
✅ Specs satisfied (and where)
📸 UI proof — walkthrough screenshots + review lines per UI requirement, if any
🔍 Reviewers — diff / security / edge-case verdicts, findings fixed, minors left
🧹 Dead code pruned — symbols the change orphaned (file:line); candidates kept + why
🧰 Experts used
📁 Files changed (tight summary, not a full diff)
🟢 Quality gate: lint / build / test results
📝 Memory note written: <filename>
🔗 Draft PR: <url> (or why it was not opened)
```
End with: *"The draft PR is open for your review — check the assumptions above first; tell me what's wrong and I'll push fixes to the same branch. Merging is yours."*

## Guardrails
- **Never merge, never push the default branch, never force-push.** The work goes to a feature branch and a draft PR (`open-pr`); the user reviews and merges.
- Autonomous, but honest: surface assumptions loudly; do not bury a guess. The assumptions log is the user's review surface.
- Stop mid-run **only** for a true blocker — an irreversible/outward-facing action that needs the user's OK, a decision or access only the user has, or a high-blast-radius decision with no safe default. A failing test, an unknown error or a hard bug is not a blocker: keep going.
- Never weaken, skip or delete a test, or silence a lint/type rule, to get green. Stay inside the goal: note other problems in the packet instead of fixing them.
- If `spec-loop` hits its cap or the AI gate finds an unresolvable conflict, stop and report it in the packet instead of forcing completion.
- Reuses the same pieces as `/make-plan` + `/implement-specs`; the only difference is no human gate in the middle. For anything truly ambiguous and high-stakes, recommend the user run `/make-plan` (with a real review) next time.
