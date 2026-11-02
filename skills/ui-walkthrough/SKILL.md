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

## 2. Where the evidence goes
One folder per task in the repo, one sub-folder per slice or scenario, never committed:
`<repo>/verify-screenshots/<YYYY-MM-DD>-<task-slug>/<slice>/` holding the PNGs, `review.md` and
`api.log`. The task slug is short and readable (`invoice-export`, `partial-payments`); a task that
spans several days keeps the folder it started in: `ls verify-screenshots` first and reuse an
existing `*-<task-slug>` folder name instead of today's date. Run this before a slice's first shot;
it only creates what is missing, so running it again is safe. Run it from inside the repo under
test (`cd` there first when the frontend and backend are separate repos). Shell variables do not survive
between commands, so use the `WALK_OUT=` path it prints, literally, in step 3:
```bash
( TASK="<YYYY-MM-DD>-<task-slug>"; SLICE="<slice>"        # fill both: letters, digits, . _ - only
case "$TASK$SLICE" in *[!A-Za-z0-9._-]*|*..*|"") echo "refusing: bad task or slice name"; exit 1;; esac
case "$TASK/$SLICE" in /*|*/|.*|*/.*) echo "refusing: empty or dot task/slice name"; exit 1;; esac
REPO=$(git rev-parse --show-toplevel) || exit 1; EV="$REPO/verify-screenshots"; OUT="$EV/$TASK/$SLICE"
for p in "$EV" "$EV/$TASK" "$OUT" "$EV/README.md"; do     # the repo is untrusted: no symlinks on the way
  [ -L "$p" ] && { echo "refusing: $p is a symlink"; exit 1; }; done
EX=$(git -C "$REPO" rev-parse --git-path info/exclude); case "$EX" in /*) ;; *) EX="$REPO/$EX";; esac
mkdir -p "$(dirname "$EX")"
grep -qxF 'verify-screenshots/' "$EX" 2>/dev/null || printf '\n%s\n' 'verify-screenshots/' >> "$EX"
git -C "$REPO" check-ignore -q verify-screenshots/ &&      # the folder itself: nothing under an
  [ -z "$(git -C "$REPO" ls-files ':(icase)verify-screenshots')" ] ||  # ignored folder can be re-included
  { echo "refusing: this repo's .gitignore or tracked files would let the evidence into git"; exit 1; }
mkdir -p "$OUT" && echo "WALK_OUT=$OUT" )
```
A partial re-walk (only the steps a fix touched) writes into the same folder and keeps
`review.md`, adding FIXED lines under the old FINDING ones; start it with `WALK_FROM=<n>` so its
shots keep the original numbers (the template appends to `api.log`, one header per run). Only a full re-walk of a slice starts
over: point `WALK_OUT` at a fresh folder (a new slice name, or `<slice>-reN`) and run the snippet
again — never shell-`rm` the old evidence. The old folder is git-ignored throwaway; remove it by
hand later if you ever need the space.
`.git/info/exclude` keeps it out of git without touching the project's `.gitignore`. Only git
ignores it: a repo deployed with `docker build .` or rsync needs `verify-screenshots/` in its
`.dockerignore` or exclude list too; a dev server or test runner that watches the whole repo will
see the new files (add the folder to its ignore list if it reloads on them); and `git clean -fdx`
deletes the evidence. The kit writes
straight into the repo because it has no state folder of its own; the private harness it comes
from copies evidence in only after the slice passes.

After the review, keep `verify-screenshots/README.md` as the index. Everything outside the two
marker lines stays as it is, line endings included. If the markers are missing, append this block at
the end; if only one is there or either appears twice, leave the file alone and tell the user:
```markdown
<!-- walks:start -->
| Date | Task folder | Slice | Screenshots | Status | Path |
|---|---|---|---|---|---|
<!-- walks:end -->
```
Then add one row per slice inside it, or replace the row whose task folder and slice match
(Screenshots is the number of PNGs), e.g.
`| 2026-11-02 | 2026-11-02-partial-payments | balance-column | 4 | reviewed | 2026-11-02-partial-payments/balance-column/ |`

## 3. Script (throwaway, outside the repo)
Copy `walk.template.mjs` from this skill folder into a temp/scratch directory as `walk.mjs`, fill
in the `steps`, and run it with the project's Playwright:
`WALK_OUT=<the path the step 2 snippet printed> WALK_BASE_URL=<app> WALK_API_URL=<api base> NODE_PATH=<repo>/node_modules node <scratch>/walk.mjs`
Each step is a user action, then an `expect` on the result a user would see (the toast, the new
status, the history line, the value that changed), then `shot('<nn-what-the-user-sees>')`.
A step that writes (create, edit, delete, status, upload, bulk) wraps the click in
`act(method, pathRe, action)`: it awaits the page's own request, fails on a non-2xx and returns
its data; after it, read the record back over the API (`api.get`) and `expect` the stored values
(the field you changed, the status, the history entry, the row that must be gone, 404 after a
delete). Reads that drive the screen (list filters, search, sort, detail) are checked the same
way: the request carries the filter and the response holds what the screen shows. The template
records every backend call in `api.log` and fails the walk on any 4xx/5xx the page made, and its loopback guard (the `page.context().route` block near the top, service workers disabled) aborts and fails the walk on any non-asset call — an xhr/fetch/eventsource/navigation, and an off-limits websocket (blocked outright on Playwright >= 1.48, otherwise detected) — the page makes to a host that is not local (`localhost`, `127.0.0.1`, `::1` or `*.localhost`, plus any `WALK_ALLOW_HOSTS` sandbox): the app's own backend, wherever its build or `.env` points it, must be local. A flow that embeds a third-party widget (a payment or captcha iframe on another host) is stubbed locally or walked inline by the implementer; `WALK_ALLOW_HOSTS` is for a named sandbox backend, not a convenience, and the `walkthrough-runner` agent is handed it only under the sandbox exception. Never delete the guard. Point `WALK_API_URL` at the API prefix (`/api/v1`), not the bare origin, when the app and its API share an origin, or every page asset counts as a backend call; use the same host spelling the page uses (`localhost` vs `127.0.0.1`). An empty `api.log` after a write is a finding: nothing was recorded
(including refetches after the action), so read `api.log` with the screenshots. Never a
bare `waitForTimeout`: a step that silently did nothing must fail the walk. Act on the record you
just created (read its id from the screen), never "the first row that matches", and change
values to something different from what is stored, or the edit proves nothing. Use the labels and
roles a user sees (`getByRole`, `getByLabel`, visible text), not CSS selectors. Desktop 1440x900;
add `WALK_VIEWPORT=390x844` when the page must work on a phone (a project rule on viewports wins).
Screenshots and logs stay in that excluded folder, never in a commit, and out of shared or synced folders: they can show user data. Never wrap a login or token-issuing call in `act()` (its body would be logged); log in through the UI or the read-back client. The template masks secret-looking query values in `api.log`; a flow that carries a secret in the path (`/reset-password/<token>`, `/invite/<code>`) is not masked, so do not share that walk's `api.log`.

## 4. Look at every screenshot
Read each PNG with the Read tool, one at a time, the whole image: never judge a shot from its
file name or the script's log. Write `review.md` in the slice folder (the `WALK_OUT` path), one line per PNG, after the
last shot:
`<file>.png | expected: <from the requirement> | shown: <the exact values and text on screen, plus the API call and read-back for a write> | OK|FIXED|FINDING`
"shown" names what you actually read (the amount, the status label, the toast text, the row
count), so a reader can tell the image was looked at. After a fix, re-shoot, re-read and add a
new line for that PNG ending in FIXED; the last line for a PNG decides. Check: the action took
effect, numbers and texts are right (compute expected values from the requirement, not from the
code), no stray errors or toasts, empty and loading states, alignment / overflow / truncation,
disabled buttons explain why. A step that fails in the script is a finding too: screenshot the
page at that moment.

## 5. Run it in parallel with the reviewers
This is the **final review gate**, when you declare the change done — not a single slice walked
mid-loop or a trivial fix, which stay inline (section 4). Reading every screenshot in the main
session blocks everything else. For the final gate the implementer assembles one `walk.mjs` covering
every flow the change touched into one `verify-screenshots/<date>-<task>/final/` folder; then, rather
than reading the shots yourself, hand the running and reading to the `walkthrough-runner` agent and
launch it in the same parallel message as the sized reviewer set (protocol rule 5), so the
walkthrough and the reviewers run while you wait once. Give the agent: the `walk.mjs` path and `WALK_OUT` (that `final/` folder),
`WALK_BASE_URL` / `WALK_API_URL` / the project's `NODE_PATH`, a test login, and each scenario's
expected outcome (the requirement's THEN). It runs the script, reads every PNG, writes `review.md`
and reports. Done needs each chosen check clean on the same frozen diff, and the agent's own verdict decides
even when screenshots from a prior attempt already sit in `WALK_OUT`. Any blocking finding, from a
reviewer or the walkthrough, changes the diff: re-run only the reviewer whose domain the fix touched (the full set for a high-risk-surface change), and re-run the walkthrough
when the fix touches a walked screen. A BLOCKED walk (server down, unsafe target, no test account) is
an access problem, not a code fix.

## 6. Report and act
- Give the user the task folder (`verify-screenshots/<date>-<task>/`) as the place to review the evidence.
- Findings table: step, screenshot path (full absolute path), what is wrong, severity.
- Real bugs: fix them in the same unit of work, add a regression check (unit or e2e) where one
  fits, then re-walk the affected steps and read the new screenshots.
- Product questions (wording, behaviour the spec does not decide) go to the user, not into code.
- Done means the last walk shows no open finding of your own making.
