---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
description: Generate a pull request description following the team's template
---
## Prompt
You are helping to create a pull request description. The argument (if any) is: `$ARGUMENTS`.

Interpret `$ARGUMENTS` as follows:
- **Empty** → base branch is `develop`, no ticket prefix.
- **A bare number** (e.g. `4029`) → base branch is `develop`, and the PR title MUST be prefixed with `[WORK-4029] `.
- **A branch name containing a WORK ticket** (e.g. `feature/WORK-4029-foo` or `WORK-4029`) → base branch is `develop`, ticket number is extracted from the argument, and the PR title MUST be prefixed with `[WORK-<num>] `.
- **A plain branch name like `main` / `master` / `develop` / `release/*`** with no embedded number → use it as the base branch, no ticket prefix.
- **A branch name plus a number** (space-separated, e.g. `main 4029`) → first token is base branch, second is ticket number for the prefix.

If no ticket number was provided via `$ARGUMENTS`, also inspect the current branch name (`git branch --show-current`) for a `WORK-<digits>` pattern (case-insensitive) and, if found, use it as the ticket prefix automatically.

### Task link

`$ARGUMENTS` may contain a `task <url>` token (case-insensitive `task` keyword followed by a URL, e.g. `task https://pancakework.vn/messages/w4/c2818/m071aa5f0-...`). It is independent of the base-branch / ticket / platform tokens — strip the `task` keyword and its URL out before interpreting the rest, and treat the remaining tokens with the rules above. When a task URL is present, the generated **Insights** section MUST include the task link as a bullet, e.g. `- Task: <url>`. If `task` is given without a following URL, ignore it.

### Platform labels

**Platform labels apply ONLY in the `pancake-work-client` repo.** First check the repo name (e.g. `gh repo view --json name -q .name`, or from the `origin` remote URL). If the repo is NOT `pancake-work-client`, do NOT apply any platform label — strip any platform token from `$ARGUMENTS` (so the remaining tokens are still interpreted with the rules above), ignore it, and skip every label-related step below.

In `pancake-work-client` only: `$ARGUMENTS` may contain a platform token (case-insensitive): `mobile`, `desktop`, or `both`. It is independent of the base-branch / ticket tokens — strip it out before interpreting the rest, and treat the remaining tokens with the rules above. Determine the labels to apply to the PR:

- **No platform token** (default) → label `desktop`.
- **`desktop`** → label `desktop`.
- **`mobile`** → label `mobile`.
- **`both`** → labels `mobile` AND `desktop`.

In `pancake-work-client`, always apply at least one platform label.

Title format when a ticket is present: `[WORK-<number>] <concise summary>` — keep the bracket, hyphen, and space exactly. The summary part should still be a concise description of the changes drawn from "What happened?".

Now analyze the git changes in this repository and generate a comprehensive PR description following this exact template:

## What happened?
What this PR fixes or changes. REQUIRED.

## Insights
Only what a reviewer actually needs. OPTIONAL.

## Proof of Work
How to verify it. OPTIONAL.

Instructions:
1. Parse `$ARGUMENTS` per the rules above to determine the base branch and the optional ticket number. If no ticket was found in `$ARGUMENTS`, also try to extract one from the current branch name.
2. First, fetch the latest changes from origin: `git fetch origin`
3. Run `git diff origin/<base-branch>` to see the changes between current branch and origin/<base-branch>
4. Also run `git log origin/<base-branch>..HEAD --oneline` to see commits that are in current branch but not in origin/<base-branch>
5. Analyze the changes and create a clear, concise summary

### Writing the three sections

Keep the whole description short. Every section is **1-2 lines** (a line = one short bullet or one sentence). The three sections must be coherent with each other: Insights and Proof of Work must be about the same change described in "What happened?" — never introduce a topic that section didn't mention.

- **What happened?** — state what is being fixed or changed, and where. 1-2 bullets. No restating the diff file by file, no listing every renamed symbol.
- **Insights** — 1-2 bullets, only if there is something a reviewer would not see from the diff itself: a trade-off, a breaking change, a dependency, a spot that needs attention. If a `task <url>` token was given, the `- Task: <url>` bullet goes here (it does not count toward the 1-2 lines). If there is nothing genuinely useful, leave the section empty rather than padding it.
- **Proof of Work** — 1-2 lines of concrete repro/verification steps for the change above (the exact command, endpoint, or UI path, plus the expected result). If the change cannot be meaningfully demonstrated (pure refactor, comment/doc change), leave the section empty. Do not write vague filler like "tested locally".

Generate the PR description and output it in a clean format ready to copy-paste.

After generating the PR description:
1. Save the description to a temporary file
2. Get the current branch name using `git branch --show-current`
3. Check if a PR already exists for this branch using: `gh pr view --json number 2>/dev/null`
4. If PR exists:
   - Extract the PR number from the response
   - Update the PR description using: `gh pr edit <pr-number> --body-file <description-file>`
   - **Only in `pancake-work-client`:** apply the platform label(s) determined above using: `gh pr edit <pr-number> --add-label "<label>"` (pass each `--add-label` for every label, e.g. `--add-label "mobile" --add-label "desktop"` for `both`). In any other repo, skip this step entirely.
   - Display message: "PR #<number> description updated successfully"
   - Show the PR URL using: `gh pr view --web`
5. If PR does NOT exist:
   - Create PR automatically against the specified base branch, applying the platform label(s) determined above **only if the repo is `pancake-work-client`**
   - Use GitHub CLI to create a PR: `gh pr create --base <base-branch> --head <current-branch> --title "<PR title>" --body-file <description-file>` — in `pancake-work-client`, also pass a `--label` flag for every platform label (e.g. `--label "mobile" --label "desktop"` for `both`); in any other repo, pass no `--label` flags
   - The PR title should be a concise summary of the changes (extract from the "What happened?" section)
   - After successful PR creation, display the PR URL
   - If a label does not exist on the repo, `gh` will error — report it to the user rather than dropping the label silently

Usage:
- `pr-description` - Creates/updates PR against origin/develop (default); in `pancake-work-client` also adds label `desktop`
- `pr-description main` - Creates/updates PR against origin/main
- `pr-description master` - Creates/updates PR against origin/master
- `pr-description mobile` - label `mobile` only (pancake-work-client only)
- `pr-description both` - labels `mobile` and `desktop` (pancake-work-client only)
- `pr-description task <url>` - adds `- Task: <url>` to the Insights section
- Platform token combines with the others, e.g. `pr-description main 4029 both`, or `pr-description task <url> 4029 both`
- In any repo other than `pancake-work-client`, no platform label is ever applied
