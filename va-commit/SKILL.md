---
name: va-commit
description: >-
  Review git diff, stage changes, and commit non-interactively with a short
  conventional subject line only. Use when the user asks to commit or summarize
  changes before committing.
disable-model-invocation: true
---

# va-commit

Diff, `git add`, then **`git commit`** non-interactively with a **single-line** message (`-m` only).

Do NOT write `COMMIT_MSG.md`, `PR_REVIEW.md`, or any other scratch file.
Do NOT add a commit body (no blank line, no bullets, no paragraphs).
Do NOT run bare `git commit` without `-m` (that opens an interactive editor).
Only commit; do NOT push.

## Terminal budget

Use **at most 2 shell invocations** total. Do not run `git status`, `git diff`, and `git log` as separate parallel calls.

1. **Read** (one command) — inspect working tree and diff; optional recent subjects only if scope is unclear:

```bash
git status -sb && echo '---' && git --no-pager diff && echo '---' && git --no-pager diff --cached
```

If the user limited paths, append ` -- <paths>` to both `diff` commands. Add `git log -n 20 --pretty=format:%s` to this same command only when you need scope/style hints.

2. **Write** (one command) — stage, commit, confirm in one shot:

```bash
git add <paths> && git commit -m "<type>(<scope>): <summary>" && git status -sb
```

If ambiguous files would be committed, **stop before write** and ask the user — do not run extra exploratory commands.

## Commit message format

**Subject only** — one line:

```
<type>(<scope>): <summary>
```

- `type` REQUIRED: feat, fix, docs, refactor, chore, test, perf, etc.
- `scope` OPTIONAL: short area noun (e.g. api, parser, ui).
- `summary` REQUIRED: imperative, <= 72 chars, no trailing period.

Write the subject from the staged diff. Keep it specific but short; put detail in `/va-pr`, not here.

Treat caller-provided arguments as commit guidance: freeform text shapes type, scope, and summary; paths/globs limit what to `git add` unless the user says otherwise.

## Working directory

If the user says to commit from a specific repo or to avoid the Cursor workspace root, run all git commands from that directory — not the default project folder unless that is the intended repo.
