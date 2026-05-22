---
name: va-commit
description: >-
  Review git diff, stage changes, and commit non-interactively with a conventional
  subject plus a detailed imperative bullet body. Use when the user asks to commit,
  write a commit message, or summarize changes before committing.
disable-model-invocation: true
---

# va-commit

Diff, `git add`, then **`git commit`** non-interactively (HEREDOC or multiple `-m` flags). Do not open an editor and do not wait on the user to edit a message file.

Do NOT write `COMMIT_MSG.md`, `PR_REVIEW.md`, or any other commit-message scratch file.
Do NOT run bare `git commit` without `-m` (that opens an interactive editor).
Only commit; do NOT push.

## Commit message format

Write the full message yourself from the diff. Use this structure:

```
<type>(<scope>): <summary>

- <imperative bullet describing a concrete change>
- <another bullet; go deep — behavior, files, rationale where useful>
```

**Subject (first line)**

- `type` REQUIRED: feat, fix, docs, refactor, chore, test, perf, etc.
- `scope` OPTIONAL: short area noun (e.g. api, parser, ui).
- `summary` REQUIRED: imperative, <= 72 chars, no trailing period.

**Body (required — never skip)**

- Blank line after the subject, then bullet list only (no paragraphs required, but bullets must carry the detail).
- Each bullet starts with `- ` and uses **imperative mood** (e.g. "Add validation for empty input", not "Added" or "Adds").
- Cover **what changed in depth** — enough that the body can serve as the PR description without extra prose.
- Include multiple bullets when the diff touches several behaviors, files, or decisions; prefer substance over brevity.
- Do NOT include breaking-change markers, footers, or sign-offs (no Signed-off-by).

If it is unclear whether a file should be included, ask the user which files to commit before staging.

Treat caller-provided arguments as commit guidance: freeform text shapes scope, summary, and bullets; paths/globs limit what to `git add` unless the user says otherwise.

## Steps

Infer from the prompt if the user provided specific file paths/globs and/or additional instructions.

### Prepare

1. Review `git status` and `git --no-pager diff` (limit to argument-specified files if provided).
2. (Optional) Run `git log -n 50 --pretty=format:%s` to match existing scopes.
3. If ambiguous extra files would be committed, ask the user before staging.

### Stage and commit

4. From the **repository root**, `git add` only files that belong in this commit.
5. Commit with the full subject + body in one message. Prefer a HEREDOC so bullets and wrapping stay correct:

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <summary>

- <imperative bullet>
- <imperative bullet>
EOF
)"
```

6. If `git commit` fails, report the error and stop (do not amend unless user rules allow it).

### Confirm

7. Run `git status` to confirm the commit succeeded.

## Working directory

If the user says to commit from a specific repo or to avoid the Cursor workspace root, run all git commands from that directory — not the default project folder unless that is the intended repo.
