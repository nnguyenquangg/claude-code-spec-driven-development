---
name: "research"
description: Research a target — auto-pick tools (web search, codebase search, expert skills), output a brief with sources, ideas/options, a wireframe, and a step-by-step flow. Read-only; feeds /make-plan.
category: Workflow
tags: [workflow, research, discovery, ideation]
---

Invoke the **research** skill to investigate a target and produce a research brief.

Target: $ARGUMENTS

Follow the `research` SKILL.md: scope the target & classify it (UI / API / product / architecture) → choose the tools that fit and state them (`WebSearch`/`WebFetch` or `deep-research` for the web; the `Explore` agent / `Grep` for the codebase; the right expert skill for feasibility; `design-an-interface`/`prototype` for UI variants) → run web + codebase passes (in parallel when both apply) → synthesize, separating cited fact from recommendation → output the brief: **Summary · Sources · Ideas & options (+ recommendation) · Wireframe · Flow · Open questions/risks · Next step**. Save to `docs/research/<target>.md` if `docs/` exists, else present inline. Read-only — write no production code; cite only real sources; reuse-first. End by pointing to `/make-plan`.
