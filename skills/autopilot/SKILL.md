---
name: autopilot
description: Full-auto end-to-end — fuses /make-plan and /implement-specs into one hands-off run with NO human review gate in the middle. Plans (specs + ADRs), self-reviews them with an independent sub-agent in place of the human gate, makes sensible default assumptions for anything it would normally ask (logging each one), builds via spec-loop through the right experts, runs the quality gate, archives, records memory, and hands back a single review packet. Does NOT commit or push. Use when the user is busy and wants the whole thing done, reviewing only the final output. Triggers on "autopilot", "/autopilot", "do it all", "just build it end to end", "I'm busy, handle it", "full auto".
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
- Write ADR(s) for the significant/architectural decisions.
- Analyze the task (`dev-workflows:task-analyzer`) and pick the implementation experts (primary + ≤2 supporting, from skills available here).

## Step 3 — AI review gate (replaces the human gate — REQUIRED)
Before writing any production code, spawn an **independent fresh-context sub-agent** (`dev-workflows:code-verifier` or `general-purpose`) to sanity-check the plan. Give it the request, the proposal/specs/ADRs, and the Assumptions list. Ask it to flag, as STRICT findings: contradictions, missing requirements implied by the request, assumptions that are risky/likely-wrong, and anything that would make the build go sideways. Apply its fixes. Only proceed once it has no blocking findings. This is the safety net for the missing human review.

## Step 4 — Build (hands-off)
**Read the project's `CLAUDE.md` first** (root + any nested one in the directories you'll touch) — it is the source of truth for this repo's conventions, flow, and do/don't rules; everything you implement must follow it. Then run `spec-loop` for the change, implementing **as the chosen experts** — load each expert's Skill into context via the Skill tool, or for larger/parallel work dispatch a **`general-purpose` agent per disjoint file-set** that loads the expert Skill itself (the `Agent` tool's `subagent_type` is a real agent type like `general-purpose`, **never** a Skill name; lock shared contracts before parallelising). spec-loop loops implement → independent review vs the finalized specs + ADRs + CLAUDE.md → fix → repeat (cap 6). Then run the project's quality gate (lint/build/test as available; respect host CLAUDE.md — e.g. don't run `tsc`/`prisma` yourself here).

## Step 5 — Archive & record memory
When spec-loop reports success and quality is green, run `/opsx:archive`, then record the non-obvious logic + why to the project memory (`memory/` + `MEMORY.md`), deduping as usual.

## Step 6 — Hand back ONE review packet
Stop and present a single, skimmable packet for when the user returns:
```
🎯 Goal
⚠️  Assumptions I made (please confirm) — each with why + how to change it
✅ Specs satisfied (and where)
🧰 Experts used
📁 Files changed (tight summary, not a full diff)
🟢 Quality gate: lint / build / test results
📝 Memory note written: <filename>
```
End with: *"Nothing is committed — review the assumptions above; tell me what's wrong and I'll adjust, or say commit when you're happy."*

## Guardrails
- **Never commit or push.** Leave all changes in the working tree for the user to review.
- Autonomous, but honest: surface assumptions loudly; do not bury a guess. The assumptions log is the user's review surface.
- Stop mid-run **only** for a true blocker — an irreversible/outward-facing action that needs the user's OK, or a high-blast-radius decision with no safe default. Otherwise keep going.
- If `spec-loop` hits its cap or the AI gate finds an unresolvable conflict, stop and report it in the packet instead of forcing completion.
- Reuses the same pieces as `/make-plan` + `/implement-specs`; the only difference is no human gate in the middle. For anything truly ambiguous and high-stakes, recommend the user run `/make-plan` (with a real review) next time.
