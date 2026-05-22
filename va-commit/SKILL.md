---
name: va-commit
description: >-
  Review git diff, stage changes, write a draft commit message to COMMIT_MSG.md,
  and open that file in the IDE for the user to edit before committing. Use when
  the user asks to commit, write a commit message, or summarize changes before
  committing.
disable-model-invocation: true
---

# va-commit

Diff, stage, write a draft commit message to `COMMIT_MSG.md`, open it in the IDE, **block until the user saves and closes the tab**, then commit using that file.

Do NOT write `PR_REVIEW.md` or any other review file.
Do NOT use `git commit -e`, vim, or terminal editors.
Do NOT run `git commit -m` (that bypasses the file the user edits).

## One-time setup (user)

Run once so `git commit` from the terminal uses the same IDE flow:

```bash
chmod +x ~/.cursor/skills/va-commit/scripts/git-msg-editor.sh
git config --global core.editor ~/.cursor/skills/va-commit/scripts/git-msg-editor.sh
```

Add `COMMIT_MSG.md` to a global gitignore so it is never committed:

```bash
echo COMMIT_MSG.md >> ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global
```

Optional: install the `cursor` shell command (Cursor → Command Palette → “Shell Command: Install 'cursor' command in PATH”) so the script works outside the app bundle path.

## Commit message format

Draft the message in `COMMIT_MSG.md` at the **repository root** using this format:

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

### Prepare (always do this first)

1. Review `git status` and `git --no-pager diff` (limit to argument-specified files if provided).
2. (Optional) Run `git log -n 50 --pretty=format:%s` to match existing scopes.
3. If there are ambiguous extra files, ask the user for clarification before staging.

### Stage

4. `git add` only the files that belong in this commit (respect path/glob arguments from the user).

### Draft message file

5. Write or overwrite `COMMIT_MSG.md` at the repo root with the drafted message (conventional format above). Do not leave placeholder scope/summary unless the user must fill them in.

### Wait for user (required — do not skip)

6. From the **repository root**, run the wait script and **do not continue until it exits** (user saved and closed the tab):

```bash
~/.cursor/skills/va-commit/scripts/git-msg-editor.sh --wait-only
```

Use a long shell timeout (e.g. 30+ minutes). The script runs `cursor --wait` on `COMMIT_MSG.md`; exiting means the user closed the editor tab.

7. After the script exits, read `COMMIT_MSG.md`. If there is no non-empty, non-`#` subject line, stop and tell the user the commit was aborted.

### Commit

8. Commit using the edited file (not `-m`):

```bash
git commit -F COMMIT_MSG.md
```

9. Run `git status` to confirm the commit succeeded.

## CLI `git commit` (without the agent)

When `core.editor` points at `git-msg-editor.sh`, a normal `git commit` (no `-m`) will:

1. Let Git create `.git/COMMIT_EDITMSG`
2. Open `COMMIT_MSG.md` in Cursor via `cursor --wait`
3. On tab close, copy `COMMIT_MSG.md` back and finish the commit

Same file and same save-and-close behavior as this skill.
