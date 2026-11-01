---
name: ui-walkthrough
description: Walk the running app in a real browser like a user after a UI-visible change - a throwaway Playwright script clicks and types through the flow, screenshots every step, and proves each action on the real backend like a QA (awaits the request, asserts 2xx, reads the record back over the API); you read every screenshot and api.log and report what a user would see. Required before reporting done on any UI-visible change. Use when the user says "test the UI", "walk it like a user", "walkthrough", or before finishing frontend work.
---

# UI walkthrough (test like a user, verify like QA)

E2E specs assert what their author thought of. A walkthrough looks at the screen: broken layout,
wrong or missing text, confusing flows, error toasts, empty states, things that "pass" but look
wrong. It is not a committed test and is never a substitute for one.

"Test UI" means a QA verifying the feature end to end through the real API, not only looking at
the screen. Every action that should reach the backend is proven there: the page's request is
awaited (method + path, 2xx), and the stored record is read back over the API and compared to
what was typed. A screen that looks right while the backend call failed, never happened, or
saved the wrong value is a FINDING. Run against the real backend (any mock switched off).

## 1. Prepare
- The app runs locally (dev server + backend). Find the URLs and a test login in the project's
  `CLAUDE.md`, README or e2e config; never invent credentials. A login wall with no test account
  documented: stop and ask the user, never type real credentials you found elsewhere.
- Starting the local dev servers is part of this step.
- Data the flow needs is set up first, through the UI where a user would do it, or through the
  API when that is not the flow under test.
- List the flows from the task (the change's requirements / scenarios) the change touches, plus
  one neighbouring flow that shares the code.

## 2. Script (throwaway, outside the repo)
Copy `walk.template.mjs` from this skill folder into a temp/scratch directory as `walk.mjs`, fill
in the `steps`, and run it with the project's Playwright:
`WALK_OUT=<out dir> WALK_BASE_URL=<app> WALK_API_URL=<api base> NODE_PATH=<repo>/node_modules node <scratch>/walk.mjs`
Each step is a user action, then an `expect` on the result a user would see (the toast, the new
status, the history line, the value that changed), then `shot('<nn-what-the-user-sees>')`.
A step that writes (create, edit, delete, status, upload, bulk) wraps the click in
`act(method, pathRe, action)`: it awaits the page's own request, fails on a non-2xx and returns
its data; after it, read the record back over the API (`api.get`) and `expect` the stored values
(the field you changed, the status, the history entry, the row that must be gone, 404 after a
delete). Reads that drive the screen (list filters, search, sort, detail) are checked the same
way: the request carries the filter and the response holds what the screen shows. The template
records every backend call in `api.log` and fails the walk on any 4xx/5xx the page made. Point `WALK_API_URL` at the API prefix (`/api/v1`), not the bare origin, when the app and its API share an origin, or every page asset counts as a backend call; use the same host spelling the page uses (`localhost` vs `127.0.0.1`). An empty `api.log` after a write is a finding: nothing was recorded
(including refetches after the action), so read `api.log` with the screenshots. Never a
bare `waitForTimeout`: a step that silently did nothing must fail the walk. Act on the record you
just created (read its id from the screen), never "the first row that matches", and change
values to something different from what is stored, or the edit proves nothing. Use the labels and
roles a user sees (`getByRole`, `getByLabel`, visible text), not CSS selectors. Desktop 1440x900;
add `WALK_VIEWPORT=390x844` when the page must work on a phone (a project rule on viewports wins).
Screenshots and logs stay out of the repo (or in a git-ignored folder) and out of shared or synced folders: they can show user data. Never wrap a login or token-issuing call in `act()` (its body would be logged); log in through the UI or the read-back client. The template masks secret-looking query values in `api.log`; a flow that carries a secret in the path (`/reset-password/<token>`, `/invite/<code>`) is not masked, so do not share that walk's `api.log`.

## 3. Look at every screenshot
Read each PNG with the Read tool, one at a time, the whole image: never judge a shot from its
file name or the script's log. Write `review.md` in the out dir, one line per PNG, after the
last shot:
`<file>.png | expected: <from the requirement> | shown: <the exact values and text on screen, plus the API call and read-back for a write> | OK|FIXED|FINDING`
"shown" names what you actually read (the amount, the status label, the toast text, the row
count), so a reader can tell the image was looked at. After a fix, re-shoot, re-read and add a
new line for that PNG ending in FIXED; the last line for a PNG decides. Check: the action took
effect, numbers and texts are right (compute expected values from the requirement, not from the
code), no stray errors or toasts, empty and loading states, alignment / overflow / truncation,
disabled buttons explain why. A step that fails in the script is a finding too: screenshot the
page at that moment.

## 4. Report and act
- Findings table: step, screenshot path (full absolute path), what is wrong, severity.
- Real bugs: fix them in the same unit of work, add a regression check (unit or e2e) where one
  fits, then re-walk the affected steps and read the new screenshots.
- Product questions (wording, behaviour the spec does not decide) go to the user, not into code.
- Done means the last walk shows no open finding of your own making.
