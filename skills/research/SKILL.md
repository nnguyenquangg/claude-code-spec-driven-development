---
name: research
description: Research a target (a feature, product idea, integration, or problem) by auto-selecting the right tools — web search for ideas/precedent, codebase search for existing patterns, expert skills for feasibility — and producing a research brief with sources, ideas/options, a wireframe, and a step-by-step flow. Read-only — produces a brief, writes no production code. Feeds into /make-plan. Triggers on "research", "/research", "research my target", "look into", "explore options for", "find ideas for", "how do others do X".
---

# research — investigate a target, output a brief (sources · ideas · wireframe · flow)

The user names a target ("research X"). You investigate it from multiple angles by **choosing the tools that fit the target**, then hand back one **research brief**. You write no production code — this is the step *before* `/make-plan`; the brief feeds planning.

## Step 0 — Scope the target & pick the angles
Restate what's being researched in one line and classify it so you know which tools to use:
- **UI / UX feature** → needs a wireframe + flow + UX-pattern references + existing components in the codebase.
- **API / integration / library** → needs official docs, API shape, constraints, existing usage in the codebase.
- **Product / market idea** → needs competitor/precedent research, what others do, tradeoffs.
- **Technical approach / architecture** → needs design options, feasibility, expert input.
Most targets mix two of these — cover the relevant ones.

## Step 1 — Choose the tools (define them up front, then run)
State which tools you'll use and why (one line), then run them. Pick from what's available in this environment:

| Source | Tool | Use for |
|--------|------|---------|
| **The web** | `WebSearch` + `WebFetch`, or the `deep-research` skill for a thorough multi-source pass | ideas, how others solve it, official docs, UX patterns, prior art |
| **This codebase** | the `Explore` agent (broad) or `Grep`/`Glob` (targeted) | existing implementations, reusable components, conventions, precedent to build on |
| **Domain expertise** | the relevant expert skill — `fullstack-dev-skills:api-designer` (API shape), `:architecture-designer` (system options), `nextjs-developer`/`react-expert` (UI), `:postgres-pro` (data) | feasibility, idiomatic options, tradeoffs |
| **Design exploration** *(optional, UI-heavy)* | `design-an-interface` or `prototype` | multiple UI/interface variants to compare |

Rules: prefer **fresh, primary sources** (official docs, real repos) over blogs; **always look in the codebase**, not just the web — reusing what exists beats inventing; run web + codebase passes in parallel (sub-agents) when both apply.

## Step 2 — Synthesize honestly
Separate **fact** (what a source actually says — cite it) from **idea** (your recommendation). Flag uncertainty; don't present a guess as a finding. Note conflicts between sources.

## Step 3 — Output the research brief
Produce this, in this order. Save it to `docs/research/<kebab-target>.md` if a `docs/` dir exists; otherwise present inline. Skip a section only if truly N/A (say so).

```
# Research: <target>

## Summary
2–4 sentences: what you found and the recommended direction.

## Sources
- Web: <title> — <url>  (one line on what it gave you)
- Codebase: `path/to/file.ts:line` — <what's reusable / the existing pattern>

## Ideas & options
For each viable approach: what it is · who does it this way · pros · cons.
End with a **Recommendation** + why.

## Wireframe
ASCII/text wireframe of the proposed UI (screens / key components / layout).
(Omit for non-UI targets — say "N/A, no UI".)

## Flow
Numbered step-by-step user + system flow (happy path; note key edge cases).
e.g. 1. User taps X → 2. API validates Y → 3. ...

## Open questions / risks
Decisions to make before building; unknowns; risks.

## Next step
→ `/make-plan "<target>, using the recommended approach"` to turn this into specs.
```

## Depth
Match effort to the ask: a quick "look into X" → a fast scan (a few searches + a codebase grep). "Research X thoroughly" / a big decision → use `deep-research` for the web pass, broader codebase exploration, and more options compared.

## Guardrails
- Read-only: produce the brief; never write production code (that's `/make-plan` → `/implement-specs`).
- Cite real sources; never fabricate a URL, a stat, or a codebase reference — verify each one exists.
- Reuse-first: surface what the codebase already has before proposing something new.
- Keep the brief skimmable — the user reads this to decide, not a wall of text.
