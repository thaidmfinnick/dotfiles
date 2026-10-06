---
description: Commit changes on the current branch using Conventional Commits format, without a Co-Authored-By trailer. Commits staged files only if any are staged; otherwise stages everything. Pass "push" to also push, "pr" to push and create the PR, a PR/ticket number to push and create the PR with that number, or "task <url>" to push and create the PR with that task link in the Insights section and then post the PR link back to the task on Panchat in the background — PRs are created via the /pr-description command.
argument-hint: "[push | pr | <PR/ticket number> | task <url>]"
---

# Commit Changes

Commit changes on the **current branch** using the Conventional Commits format. By default, do NOT push — only push when the `push` argument, the `pr` argument, or a PR/ticket number is given (see "Arguments").

## Arguments

This command takes an optional argument via `$ARGUMENTS`:

- **No argument** → commit only; do not push.
- **`push`** → after the commit succeeds, push the current branch to its remote. Use `git push` if the branch already has an upstream; otherwise `git push -u origin <current-branch>`. If the push fails (e.g. non-fast-forward), report the error to the user — do NOT force-push or retry with `--force`. Do NOT create a PR.
- **`pr`** → commit, then push (exactly as `push` does), then create/update the pull request via the `/pr-description` command with **no** number argument (no ticket prefix). `pr` implies `push`. See "Creating the PR" below.
- **A PR/ticket number** (e.g. `4029`) → commit, then push (exactly as `push` does), then create/update the pull request via the `/pr-description` command, passing the number through (so the title gets the `[WORK-4029]` prefix). A number implies `push`. See "Creating the PR" below.
- **`task <url>`** (e.g. `task https://pancakework.vn/messages/w4/c2818/m071aa5f0-...`) → run **two separate steps**:
  1. **Foreground** — commit, then push (exactly as `push` does), then create/update the pull request via the `/pr-description` command, passing the task URL through so it is included in the PR's **Insights** section. Report the PR URL. See "Creating the PR" below.
  2. **Background** — once the PR URL exists, reply to the task thread on Panchat with the PR link. See "Notifying the task (background)" below.

  `task` implies `push` (and a PR). The `task` token may be combined with the other PR tokens (e.g. `task <url> 4029` to also get the `[WORK-4029]` prefix).

## Staging rule

- If the user **already has staged files** (`git diff --cached` is non-empty): commit ONLY the staged files. Do NOT add anything else. Do NOT include unstaged changes.
- If the user has **nothing staged**: stage all changes (`git add -A`) and commit them.

## Steps

1. Run these in parallel to understand state:
   - `git status` (no `-uall`)
   - `git diff --cached` — to detect whether anything is already staged
   - `git diff` — to preview unstaged changes (used only if nothing is staged yet)
   - `git log -n 10 --oneline` — match the repo's commit message style

2. Decide what to commit based on the staging rule above:
   - **Something staged** → skip `git add`. Commit as-is.
   - **Nothing staged** → run `git add -A`, then commit. Before adding, scan `git status` for files that look like secrets (`.env`, `credentials.*`, key files, tokens). If any are present, stop and warn the user instead of adding them.

3. If there are no changes at all (nothing staged AND nothing unstaged/untracked), stop and tell the user there is nothing to commit.

4. Draft a commit message following [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/):

   ```
   <type>(<optional scope>): <short summary in imperative mood>

   <optional body explaining the why, wrapped at ~72 chars>
   ```

   - **type** — one of: `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `build`, `ci`, `chore`, `style`, `revert`.
   - **scope** — optional, lowercase, derived from the area of the codebase touched (e.g. `threads`, `dm`, `fcm`). Look at recent commits with `git log --oneline` to match existing scope conventions. Always prefer underscores over hyphens in multi-word scopes (e.g. `feat(message_composer)`, not `feat(message-composer)`).
   - **summary** — imperative, lowercase, no trailing period, under ~72 chars.
   - **breaking changes** — if applicable, add `!` after type/scope (e.g. `feat(api)!: ...`) and include a `BREAKING CHANGE:` footer.
   - **body** — include a body ONLY when the change needs explanation that the diff and summary don't already convey (the "why", a non-obvious tradeoff, a linked issue, migration notes). Skip the body for trivial or self-explanatory changes. Separate body from summary with a blank line.

5. Create the commit using a HEREDOC to preserve formatting:

   ```bash
   git commit -m "$(cat <<'EOF'
   <type>(<scope>): <summary>

   <optional body>
   EOF
   )"
   ```

   - Do **NOT** include a `Co-Authored-By:` trailer.
   - Do **NOT** use `--no-verify`, `--amend`, or `--no-gpg-sign` unless the user explicitly asks.
   - Do **NOT** use `-a` / `--all` on `git commit` (use the staging rule above instead).

6. If a pre-commit hook fails, fix the underlying issue, re-stage the same set of files, and create a NEW commit. Do not amend.

7. After the commit, run `git status` to confirm success and report the new commit hash and subject to the user.

8. **Only if the `push`, `pr`, a PR/ticket number, or the `task <url>` argument was given**, push the current branch (see "Arguments") and report the result (and PR/remote URL if printed by git).

9. **Only if the `pr` argument, a PR/ticket number, or the `task <url>` argument was given**, create/update the PR — see "Creating the PR".

## Creating the PR

When the `pr` argument, a PR/ticket number, or the `task <url>` argument is provided, after the commit and push succeed:

1. Run the **`/pr-description` command** (the slash command at `~/.claude/commands/pr-description.md`):
   - For a **PR/ticket number** → pass the number through as its argument (e.g. `/pr-description 4029`).
   - For **`pr`** → run it with **no** argument (e.g. `/pr-description`); no ticket prefix is applied.
   - For **`task <url>`** → pass the task URL through as a `task <url>` argument (e.g. `/pr-description task https://pancakework.vn/...`). If a PR/ticket number was also given, include it too (e.g. `/pr-description task https://pancakework.vn/... 4029`). `/pr-description` adds the task link to the PR's **Insights** section.
2. That command owns the whole PR step: it follows the team's template, derives the `[WORK-<number>]` title prefix when a number is given, fetches origin, diffs against the base branch, and then creates the PR or updates the existing one for the current branch via `gh`. Do NOT hand-roll your own `gh pr create`/`gh pr edit` — let the command do it so the description stays on-template.
3. Report the resulting PR URL (the command prints it) to the user.

## Notifying the task (background)

**Only when a `task <url>` argument was given**, and only after the PR URL exists. This is a *separate* step from the commit/PR step — never let it block or delay reporting the PR URL, and never let a Panchat failure be treated as a PR failure.

Run it in the background with the Agent tool (a single `general-purpose` agent, `run_in_background: true`) so the user gets the PR URL immediately. Give the agent the task URL and the PR URL and these instructions:

1. Call `mcp__panchat__reply_to_thread` with `thread_url` set to the task URL exactly as the user pasted it (it already encodes workspace/channel/message — do not re-derive the IDs).
2. Send Vietnamese content via `rich_text` (NOT `message`), one `paragraph` block whose `content` is:

   ```
   note pr fix
   ```

   with `pr fix` rendered as a link to the PR:

   ```json
   [{"type":"paragraph","content":"note pr fix","spans":[{"type":"link","from":5,"to":11,"url":"<PR URL>"}]}]
   ```

   Offsets are 0-indexed, half-open, UTF-16 — compute them from the actual `content` string rather than copying the numbers blindly if the wording changes.
3. If the reply succeeds (`{success: true}`), report the reply confirmation. If the MCP build renders the rich text verbatim / rejects `rich_text`, fall back to `message: "note pr fix: <PR URL>"` and say the chip form was unavailable.

Report the outcome of this step to the user when the background agent finishes — including failures.

## Hard rules

- **Never push unless the `push`, `pr`, or a PR/ticket number argument was explicitly given.** With no argument, no `git push` under any circumstance.
- **Never force-push.** No `--force` / `--force-with-lease`, even when `push` is given.
- Never commit files that look like secrets.
- Never modify git config.
- Never switch branches.
