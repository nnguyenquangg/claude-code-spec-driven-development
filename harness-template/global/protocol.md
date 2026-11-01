# Working protocol

Applies in every repository. The project block imported below this file names the client,
the project and its tech layers; read their files when the task touches them.

1. One unit of work at a time. Read code before editing it. Do what was asked and nothing
   more: no drive-by refactors, renames or reformatting.
2. Every non-trivial change (beyond one file with no judgement call; a change spanning repos or
   touching a contract/API is never trivial) gets a spec before code: an OpenSpec change, or
   `specs/<name>.md` in the project folder, with Why, Scope, GIVEN / WHEN / THEN scenarios,
   decisions (with the alternative rejected), assumptions and open questions.
3. Use the project's vocabulary (its `glossary.md`) for names in code and messages.
4. Done means the project's checks pass **and** the behaviour was exercised for real
   (request, command, UI). A UI-visible change also gets a `ui-walkthrough`. Never weaken,
   skip or delete a test, or silence a lint/type rule, to get green.
5. Before reporting a non-trivial change done: `diff-reviewer`, `security-reviewer` and
   `edge-case-reviewer` in parallel on the full diff of every repo touched. Fix blocking
   findings, re-run the reviewer that failed.
6. End of a session: append to the project's `progress.md` what was done, how it was verified,
   what is still broken and the single next step.
7. Git: the build lanes (`/fix`, `/implement-specs`, `/autopilot`) finish with `open-pr`: a
   feature branch, one commit (plus one per review-fix round), a push of that branch and a draft PR with the evidence. Anything
   else is pushed only when the user asks. Never merge, never push the default branch, never
   force-push or rewrite history.
8. A mistake corrected twice is a harness gap: record it at the narrowest level that is true
   (project, client, layer or global) as a check, a standard, a note or a skill.
9. Hard bug or a repeated failure: use the `diagnose` skill instead of patching again.
