---
name: open-pr
description: Finish a verified change by opening a DRAFT pull request that carries its evidence - feature branch, one commit, push, then a PR body with the spec, the checks run, the UI walkthrough table and its screenshots. Never merges, never pushes to the default branch, never force-pushes. The last step of /fix, /autopilot and /implement-specs; also on "open a PR", "make a PR", "push it for review".
---

# open-pr: a draft PR with the proof attached

The reviewer of a PR should see what changed, what it was checked against, and what the
screen looked like, without re-running anything. This skill packages that. It does not
decide whether the work is done: it runs only after the lane's own gate passed.

## 0. Preconditions (stop if one fails, and say which)
- The project's checks are green on the final code.
- A UI-visible change has a reviewed `ui-walkthrough` (out dir with screenshots and `review.md`
  holding no open FINDING of this change's making).
- The three reviewers (`diff-reviewer`, `security-reviewer`, `edge-case-reviewer`) returned PASS,
  or the skip reason is written down.
- The user did not say "local only" / "don't push". A repo with no remote, or `gh auth status`
  failing: do steps 1–2 only and report that the PR could not be opened.

## 1. Branch
- `git branch --show-current`. Empty (detached HEAD): `git switch -c <type>/<short-slug>` first.
  On the default branch (`gh repo view --json defaultBranchRef -q
  .defaultBranchRef.name`, else `main`/`master`): `git switch -c <type>/<short-slug>`
  (`feat/`, `fix/`, `chore/`; the slug from the change name). Never commit to the default
  branch, never push it.

## 2. Commit the unit of work
- `git status --porcelain`: stage only files this change touched, by name. Never stage `.env*`,
  keys, credential files, screenshots, walkthrough output or editor files; if one shows up
  untracked, leave it out and mention it.
- Commit message: what changed (imperative, one line), a blank line, then `Spec: <change name>`
  and `Verified: <checks / requests / walkthrough>`. The repo's own commit convention wins.
- A review-fix round on a branch that already has its PR: add a new commit on the same branch
  (`fix: <what the review asked>`). Never amend, squash or rebase: history is never rewritten.

## 3. Push
`git push -u origin <branch>` (the remote that `git remote` lists for the repo, usually `origin`;
a fork workflow pushes to the fork and opens the PR against upstream). Never `--force` /
`--force-with-lease`. A push rejected because the remote moved: `git pull --no-rebase` on the
feature branch, re-run the checks, push again. Rejected for permission (403, "denied"): stop and
report; never retry another way.

## 4. Screenshots into the PR
Embed them only when the repo is private (`gh repo view --json visibility -q .visibility`) or the
project's `CLAUDE.md` says PR screenshots are allowed; a public repo otherwise gets the table and
the file names, and the author drags the images in. Before uploading, look at every image once
more: one that shows a secret, a token or a real person's data is left out and named in the PR.
Upload only the files you approved, by name: never a glob. Name them per round
(`02-saved-r2.png`) so a review-fix round does not overwrite images an earlier PR body points at. A pushed image stays in the branch
history for anyone who can read the repo, even after the PR closes. On a public repo, keep the
"Shown" column of the table to non-sensitive values for the same reason. Making a private repo
public later exposes `pr-evidence`: delete that branch first. Treat anything already pushed as possibly seen:
deleting a branch does not purge GitHub's copies.

Upload to the orphan branch `pr-evidence` through a temporary worktree, so the feature branch and
your checkout stay untouched:
```bash
D=$(mktemp -d); W="$D/evidence"; B=<feature branch>
trap 'git worktree remove --force "$W" 2>/dev/null; rm -rf "$D"; true' EXIT   # always cleaned up
if git ls-remote --exit-code --heads origin pr-evidence >/dev/null; then
  git fetch origin pr-evidence && git worktree add --detach "$W" FETCH_HEAD
else   # a fresh root commit with no branch name left behind
  git worktree add --detach "$W" && git -C "$W" checkout --orphan "evidence-$$" \
    && git -C "$W" rm -rfq --ignore-unmatch .
fi || { echo "evidence worktree setup failed; not uploading"; exit 1; }
mkdir -p "$W/$B" && cp <out>/<approved-1>.png <out>/<approved-2>.png "$W/$B/"   # by name, no glob
git -C "$W" add "$B"
if ! git -C "$W" diff --cached --quiet; then   # identical images: nothing to upload
  git -C "$W" commit -qm "evidence: $B" && git -C "$W" push origin HEAD:pr-evidence
fi
git -C "$W" checkout -q --detach 2>/dev/null || true
git branch -D "evidence-$$" >/dev/null 2>&1 || true
```
Image URL: `https://github.com/<owner>/<repo>/blob/pr-evidence/<branch>/<file>.png?raw=true`
(renders for anyone who can see the repo).

## 5. Open the draft PR
Use `.github/pull_request_template.md` (or `.github/PULL_REQUEST_TEMPLATE/`) when the repo has
one, filling its sections; otherwise this body, short and factual:
```markdown
## What
<2–4 bullets: behaviour that changed, for a user or a caller>

## Spec
<OpenSpec change name + path; ADRs if any>

## Verified
| Check | Result |
|---|---|
| <lint / unit / e2e command> | pass |
| <API call: method path → status, value read back> | pass |

## UI walkthrough
| Step | Expected | Shown | |
|---|---|---|---|
| <from review.md, one row per screenshot> | | | OK |

<one image per row: ![01-login](<image URL>)>

## Review
diff / security / edge-case: PASS (<minor findings left, if any>)
```
Leave out the "UI walkthrough" section when nothing in the change is visible in a UI.
`gh pr view --json url,state` on the branch first: a PR in state `OPEN` (a review-fix round) gets the new
commit and an updated body (`gh pr edit --body-file <file>`), never a second PR. Otherwise
`gh pr create --draft --base <default branch> --title "<commit subject>" --body-file <file>`.
A change spanning several repos gets one draft PR per repo, each linking the others.
The body never contains tokens, credentials or raw `api.log` lines with secrets (the walk
template masks them; check anyway).

## 6. Report
The PR URL, the branch, what is embedded vs left for the author, and anything not pushed.
Merging, marking ready for review and requesting reviewers are the user's.
