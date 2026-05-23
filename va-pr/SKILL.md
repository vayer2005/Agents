---
name: va-pr
description: >-
  Read only the latest commit on the current branch, write a detailed draft PR
  title and body, and open or update a GitHub draft pull request. Use when the
  user asks to create a PR, draft PR, or generate a PR description.
disable-model-invocation: true
---

# va-pr

Build or **amend** a **draft** pull request for the **current branch** from the **latest commit**.

Do NOT compare against `main`, `master`, or any other base branch to gather context (no `git diff main...HEAD`, no `git merge-base`, no default-branch detection for the write-up).
Do NOT write `COMMIT_MSG.md` or other scratch files in the repo.
Use **`gh`** for all GitHub PR operations.

## Terminal budget

Use **at most 2 shell invocations** total. Do not run separate `git branch`, `git log`, `git show --stat`, and `git show` calls.

### 1. Read (one command)

Branch, **existing PR** (if any), latest commit message, patch, and optional working-tree hint in a single invocation:

```bash
BR=$(git branch --show-current) && echo "branch:$BR" && \
echo '---existing-pr---' && gh pr view --json title,body,url,state,isDraft 2>/dev/null || true && \
git --no-pager log -1 --format='%s%n%n%b' && echo '---patch---' && git --no-pager show HEAD --stat && echo '---' && git --no-pager show HEAD && echo '---status---' && git status -sb
```

If `BR` is empty (detached HEAD), stop. If `HEAD` has no changes, stop and tell the user to commit first.

**Reading large patches:** use `--stat` for file list and scope. For huge data files (dictionaries, lockfiles, generated assets), read the diff header and a few lines only — do not ingest the full file contents. Describe data files by role, format, and approximate size instead.

Use this output for the PR write-up:

- **No existing PR** (`---existing-pr---` empty or `gh` errors): write body from the **latest commit only** (see [New PR body](#new-pr-body)).
- **Existing PR** (JSON under `---existing-pr---`): **amend** — merge the latest commit into the existing `title` and `body`; do **not** replace the PR with latest-commit-only content.

Mention uncommitted work from `status -sb` if present; do **not** fold uncommitted diffs into Summary unless the user explicitly asks.

### 2. Publish (one command)

Inspect existing PR, push only if needed, then create or **amend** — no follow-up `gh pr view` for the URL:

```bash
BR=$(git branch --show-current) && \
HAS_PR=$(gh pr view --json url 2>/dev/null) && \
UPSTREAM=$(git rev-parse --abbrev-ref '@{u}' 2>/dev/null || true) && \
if [ -z "$UPSTREAM" ] || [ -n "$(git rev-list '@{u}..HEAD' 2>/dev/null)" ]; then git push -u origin HEAD; fi && \
if [ -n "$HAS_PR" ]; then \
  gh pr edit --body "$(cat <<'EOF'
<merged body — see Amend existing PR>
EOF
)"; \
else \
  gh pr create --draft --head "$BR" --title "<title>" --body "$(cat <<'EOF'
<new PR body — see New PR body>
EOF
)"; \
fi
```

- **Existing PR:** pass **`--body` only** — do **not** pass `--title` unless the user gave an explicit new title. This prevents wiping a multi-commit PR title.
- **New PR:** pass `--title` and `--body` as today.
- Do not pass `--base` unless the user explicitly names a merge target.
- Use the URL printed by `gh pr create` or `gh pr edit`; do not run another command to fetch it.
- Only push when there is no upstream or local commits are not on the remote; do not push otherwise unless the user asks.

If the existing PR is not a draft and the user wanted a draft, add `--draft` to `gh pr edit` only when supported; otherwise note it in the response.

## PR title

| Situation | Title |
|-----------|--------|
| **New PR** | Default: subject line from `git log -1` first line. |
| **Amend existing PR** | **Keep** the existing PR `title` from `---existing-pr---`. Override only if the user gives an explicit title (then pass `--title` on `gh pr edit`). |

Do not retitle an open PR to match only the latest commit unless the user asks.

## Writing depth

PR bodies should help a reviewer understand **what** changed, **how** it works, and **why** it matters — not just a commit subject restated as bullets.

Before writing, walk the patch and note:

1. **Purpose** — what problem or feature does this commit address?
2. **Surface area** — which files/modules; new vs modified vs deleted.
3. **Behavior** — public API, CLI, user-visible flows, state transitions, persistence, error handling.
4. **Implementation choices** — non-obvious algorithms, data structures, defaults, constants, edge cases handled.
5. **Dependencies & data** — new assets, config, fixtures; what was intentionally excluded (e.g. runtime files, `__pycache__`).
6. **Risk / scope** — breaking changes, migrations, follow-ups; call out if none.

Use complete sentences in **Overview** and **Changes**; bullets there should carry real detail (file names, function/class names, validation rules, limits). Avoid vague bullets like "add tests" or "update logic" without saying what is tested or how logic behaves.

For **Test plan**, tie each checkbox to a concrete command or scenario implied by the diff — include happy path, at least one failure/validation path when the code handles errors, and persistence or side effects when relevant.

## New PR body

Write from the **latest commit patch and message** only. Use this structure (omit a section only when the diff truly has nothing to say for it):

```markdown
## Overview

<2–4 sentences: what this commit delivers, who it is for, and the main outcome. State motivation when inferable from the diff.>

## Changes

### <Component, file, or area name>
- <Concrete change: class/function added or modified, with behavior — inputs, outputs, limits, defaults>
- <Another substantive detail from the patch>

### <Next component or file>
- ...

## Notes

- <Non-obvious design choice, excluded files, follow-up work, or "none" if nothing to call out>

## Test plan

- [ ] <Exact command or manual step; expected result>
- [ ] <Edge case or error path to verify>
- [ ] <Integration or persistence check when applicable>
```

**Minimum bar:** at least one **Changes** subsection per meaningful source file (group tiny related files if needed). Data-only files get one bullet describing format and purpose, not a line-by-line dump.

## Amend existing PR

**Never** replace the full PR body with content derived from only the latest commit.

1. Start from the existing `body` in the `---existing-pr---` JSON.
2. Parse `## Overview`, `## Changes`, `## Notes`, and `## Test plan` if present; preserve all other sections and prose verbatim.
3. **Overview:** lightly revise only if the latest commit shifts the PR's overall purpose; otherwise leave intact.
4. **Changes:** keep every existing subsection and bullet; **append** new subsections or bullets for the latest commit. Group under the same subsection when the commit extends an existing area. Skip bullets that are substantively duplicate.
5. **Notes:** append new callouts for the latest commit; keep existing notes.
6. **Test plan:** keep every existing `- [ ]` item; **append** new items for the latest commit only. Skip duplicates.
7. If the existing body uses the old short format (`## Summary` only), **upgrade** it: move existing summary bullets under **Changes** (split into subsections as needed), add **Overview** and **Notes** if missing, rename **Summary** → **Changes** only when you can preserve all original bullets.
8. Optional: after amending, add a one-line note under **Changes** with the latest commit subject (e.g. `Latest: refactor(robot): …`) — only if it helps; do not remove older content.

Apply the same [Writing depth](#writing-depth) standards when appending; new bullets should be as detailed as the template above, not one-line stubs.

## Working directory

If the user says to run from a specific repo or to avoid the Cursor workspace root, run all git and `gh` commands from that directory.

## Caller arguments

- Freeform text shapes Overview/Changes/Notes/Test plan emphasis (e.g. "call out breaking API change").
- Optional `--base <branch>` only if the user **explicitly** names a merge target; never infer `main`/`master` for content or for `--base`.
