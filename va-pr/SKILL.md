---
name: va-pr
description: >-
  Read only the latest commit on the current branch, write a descriptive draft PR
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
git --no-pager log -1 --format='%s%n%n%b' && echo '---patch---' && git --no-pager show HEAD && echo '---status---' && git status -sb
```

If `BR` is empty (detached HEAD), stop. If `HEAD` has no changes, stop and tell the user to commit first.

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

## New PR body

Write from the **latest commit patch and message** only. Keep **Summary** as bullets only — no paragraphs or subsections.

```markdown
## Summary

- <imperative bullet: concrete change from this commit>
- <more bullets as needed>

## Test plan

- [ ] <verification step a reviewer can run>
- [ ] <another step, or note what was not tested and why>
```

**Summary bullets** — a bit more specific than the commit subject, still one line each:

- Name key files, classes, or functions when they clarify the change.
- Mention behavior reviewers care about: validation rules, limits, persistence, error cases — only when the patch shows them.
- For large data files, one bullet on purpose/format; do not restate the commit message or write prose.
- Avoid vague one-liners ("add tests", "update logic") without saying what is covered or how it behaves.

## Amend existing PR

**Never** replace the full PR body with content derived from only the latest commit.

1. Start from the existing `body` in the `---existing-pr---` JSON.
2. Parse `## Summary` and `## Test plan` if present; preserve all other sections and prose verbatim.
3. **Summary:** keep every existing bullet; **append** new bullet(s) for the latest commit only. Skip a new bullet if it is substantively the same as an existing one.
4. **Test plan:** keep every existing `- [ ]` item; **append** new items for the latest commit only. Skip duplicates.
5. If the existing body has no `## Summary` / `## Test plan`, keep the full original body and add those sections at the end with the new commit’s bullets/items (do not delete the original text).
6. Optional: after amending, you may add a one-line note under Summary with the latest commit subject (e.g. `Latest: refactor(robot): …`) — only if it helps; do not remove older bullets.

Apply the same Summary bullet bar when appending on amend. Test plan: realistic checklist with concrete commands; do not invent tests the diff does not imply.

## Working directory

If the user says to run from a specific repo or to avoid the Cursor workspace root, run all git and `gh` commands from that directory.

## Caller arguments

- Freeform text shapes Summary/Test plan emphasis (e.g. "call out breaking API change").
- Optional `--base <branch>` only if the user **explicitly** names a merge target; never infer `main`/`master` for content or for `--base`.
