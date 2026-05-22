---
name: va-commit
description: >-
  Review git changes, write PR review and commit message files, and create a
  formatted commit. Use when the user asks to commit, write a commit message,
  prepare a PR review, or summarize changes before committing.
disable-model-invocation: true
---

# va-commit

Review changes, write review and commit message files, then commit.

## Review and output files

Run `git --no-pager diff` and create a code review that uses imperative verbs (add instead of added), (delete instead of deleted). for the changes in the request. make the commit message be in a file such that I can make edits on it in the IDE. have a testing done section with a comment that the user should manually fill out the tests done (if part of the review is adding tests then list out all the tests a user added and breif descriptions of what they do).

Write `PR_REVIEW.md` in the project root:

```markdown
# Code Review

[Review using imperative verbs throughout.]

## Testing Done

<!-- User: manually fill out the tests you ran -->

[If new or modified tests are part of the changes, list each test with a brief description.]

- `test_name_or_path` — what the test checks
```

Write `COMMIT_MSG.md` in the project root using the commit message format below so the user can edit it in the IDE before committing.

## Commit message format

Format
<type>(<scope>): <summary>

type REQUIRED. Use feat for new features, fix for bug fixes. Other common types: docs, refactor, chore, test, perf.
scope OPTIONAL. Short noun in parentheses for the affected area (e.g., api, parser, ui).
summary REQUIRED. Short, imperative, <= 72 chars, no trailing period.
Notes
Body is OPTIONAL. If needed, add a blank line after the subject and write short paragraphs.
Do NOT include breaking-change markers or footers.
Do NOT add sign-offs (no Signed-off-by).
Only commit; do NOT push.
If it is unclear whether a file should be included, ask the user which files to commit.
Treat any caller-provided arguments as additional commit guidance. Common patterns:
Freeform instructions should influence scope, summary, and body.
File paths or globs should limit which files to commit. If files are specified, only stage/commit those unless the user explicitly asks otherwise.
If arguments combine files and instructions, honor both.

## Steps

Infer from the prompt if the user provided specific file paths/globs and/or additional instructions.
Review git status and git diff to understand the current changes (limit to argument-specified files if provided).
(Optional) Run git log -n 50 --pretty=format:%s to see commonly used scopes.
If there are ambiguous extra files, ask the user for clarification before committing.
Stage only the intended files (all changes if no files specified).
Run git commit -m "<subject>" (and -m "<body>" if needed).

Use the subject and body from `COMMIT_MSG.md` when committing.
