---
allowed-tools: Read, mcp__panchat__list_tasks, mcp__panchat__get_task, mcp__panchat__get_task_comments, mcp__panchat__send_channel_message
description: Build my daily Panchat work digest (open tasks I've commented on) and post it to my digest channel.
argument-hint: "[dry-run]"
---

# Panchat Daily Digest

Generate **{{USER_NAME}}'s** daily Panchat digest and post it to the digest channel.

If `$ARGUMENTS` is `dry-run` / `preview`, build the digest and show it inline but **skip** the `send_channel_message` call.

## 0. Load local config (required)

All `{{PLACEHOLDER}}` values in this command come from **`~/.claude/panchat-daily.local.md`** (a local-only file, never committed). Read it first and substitute every `{{KEY}}` below with its value.

Expected keys: `USER_NAME`, `USER_ID`, `WORKSPACE_ID`, `WORKSPACE_NAME`, `TASK_CHANNEL_NAME`, `TASK_CHANNEL_ID`, `POST_CHANNEL_ID`, `APP_BASE_URL`, `GITHUB_CLIENT_REPO`, `GITHUB_API_REPO`.

If the file is missing or any key is absent, **stop** and tell the user which keys are missing — never guess or invent IDs.

## Identity & scope (from local config)

- User: **{{USER_NAME}}** — user_id `{{USER_ID}}`
- Workspace: **{{WORKSPACE_ID}}** ({{WORKSPACE_NAME}})
- Task channel: **`{{TASK_CHANNEL_NAME}}`** (channel_id `{{TASK_CHANNEL_ID}}`)
- **Post target: channel `{{POST_CHANNEL_ID}}`** (workspace {{WORKSPACE_ID}}) — posted as a **top-level channel message** via `send_channel_message` (NOT a thread reply).

The panchat MCP is **local-only** (not a cloud connector), so this command only works in an interactive session that has the panchat MCP — not in remote/cron runs.

## Output — one section only

1. **↩️ Tasks I'm in** — open tasks in `{{TASK_CHANNEL_NAME}}` that **I have commented on** (I authored at least one reply).

(The old "pending tasks summary" and the whole issues section were dropped — the user reads this as a personal action list of tasks.)

## Steps

### 1. Gather data (run in parallel)

- `list_tasks` → `{workspace_id: {{WORKSPACE_ID}}, channel: "{{TASK_CHANNEL_NAME}}", is_completed: false, max_results: 200}` — **all open channel tasks**. This is the candidate set.
- For **every** candidate task, call `get_task_comments` (batch the calls in parallel) and **keep only tasks where my user_id (`{{USER_ID}}`) appears as a comment author** — i.e. tasks I've replied on. Tasks I never commented on are dropped, even if I'm `@`-mentioned or assigned. (Membership is decided by comment authorship, not assignment/mention.)
- **Tasks: open only — never include a closed task.** The list call passes `is_completed: false`, but verify before including: a task is open ONLY if `is_completed == false` AND the most recent task system message in `get_task_comments` (`type:"task"` with `data.action`) is **not** `closed` (a later `reopened` makes it open again). Drop any task that is completed/closed.

### 2. Tasks I'm in (tasks I commented on)

A task belongs in the digest if **I authored at least one comment on it** and it is **still open** — regardless of assignment, mention, or whether the reporter already said thanks. This is the kept set from step 1.

Read my **last reply** on each kept task to classify into four buckets:
- **Đang điều tra / chờ mình xử lý** — open, still investigating / waiting on me to act.
- **Mình đã hứa báo lại** — I promised to investigate / báo lại and haven't.
- **PR-fix chờ xác nhận** — I posted a PR/commit; reporter hasn't confirmed resolved.
- **Đã hướng dẫn, chờ user thử lại** — I gave the reporter steps/workaround and am waiting for them to retry.

**Only open tasks belong here.** A closed task (`is_completed == true`, or last task system message action is `closed` with no later `reopened`) is NEVER included, regardless of bucket — verify open status per the guard in step 1 before placing a task in any bucket.

Don't drop an *open* task just because the reporter sent thanks / "works now" — keep it under **Đã hướng dẫn, chờ user thử lại** until the task is actually closed (it won't appear once `is_completed`). Only an explicit close removes it.

For each task capture: task number · short desc · **last-reply state/progress** (this is bolded in the output) · creator. Creator = task `author_id` → name; resolve unknown IDs from the thread's mentions (or `user_name` on the parent message via `get_thread_messages`). Fetch `message_id` via `get_task` for the clickable link.

### 3. Build the message as a `v1/standard` rich-text document

Post rich text (NOT markdown, NOT bare URLs) so `#<num>` renders as **tappable chips** that open in-app. The payload is one document:

```json
{"type":"v1/standard","text":[ ...blocks... ],"attachments":[],"link_previews":[]}
```

Each block has `type`, `content` (the visible text) and optional `spans` (0-indexed, half-open `from`/`to` over `content`).

**Every list item is a real list node, never a fake bullet in a paragraph.** Use `unordered_list_item` with `metadata.level` (0-based indentation, verified in `rich_text_node.dart`) so the renderer draws the bullet and the indent:

```json
{"type":"unordered_list_item","content":"…","spans":[…],"metadata":{"level":0}}
```

Do NOT hand-write `• ` or `  - ` prefixes into `content` — the level does the nesting. Consecutive `unordered_list_item` nodes are grouped into one visual list by the renderer, so keep the items of a group adjacent.

Block rules:

- **Section title** (`↩️ Tasks I'm in`) → `paragraph`, fully **bold** (`{"type":"bold","from":0,"to":<len>}`).
- **Bucket sub-header** → `unordered_list_item`, `level: 0`, fully **bold**, content is the bare bucket name with no `• ` prefix. One per non-empty bucket, in order: `Đang điều tra / chờ mình xử lý`, `Mình đã hứa báo lại`, `PR-fix chờ xác nhận`, `Đã hướng dẫn, chờ user thử lại`.
- **Task line** → `unordered_list_item`, **`level: 1`** (nested under its bucket header), content `#<num> — <desc> · <state> · <creator>`:
  - **App-link chip** on leading `#<num>` → a `link` span to the task message **carrying `metadata`** (incl. `task_id`) so it renders as an in-app chip:
    ```json
    {"type":"link","from":0,"to":<len("#<num>")>,"url":"{{APP_BASE_URL}}/messages/w{{WORKSPACE_ID}}/c{{TASK_CHANNEL_ID}}/m<message_id>","metadata":{"name":"{{TASK_CHANNEL_NAME}}","type":"channel_message","task_id":<task id>}}
    ```
    `<task id>` is the numeric `id` from `list_tasks`, NOT the `#<num>` shown in the title.
  - **PR chip** on any `#<n>` → a `link` span → `https://github.com/{{GITHUB_CLIENT_REPO}}/pull/<n>` (api-repo PRs use `https://github.com/{{GITHUB_API_REPO}}/pull/<n>`).
  - **bold** span on the state phrase (e.g. *chờ phản hồi*, *fix đã lên stable 6.36.0*). Keep bold/link spans non-overlapping — if the state phrase ends with a PR chip, stop the bold before the `#<n>` and trim the trailing space.

#### Span offsets — compute in UTF-16, never by hand

Compute every span `from/to` **programmatically** — never count by hand (Vietnamese diacritics make manual offsets error-prone). **The renderer measures offsets in UTF-16 code units, not Unicode codepoints.** Python's `len()` / `str.find()` return codepoints, which match UTF-16 **only for BMP characters**. BMP punctuation/emoji are fine (`—` U+2014, `·` U+00B7, `↩️` = `↩`+VS16, all 1 unit each). But **astral-plane emoji are 2 UTF-16 units** while `len()` counts them as 1 — e.g. `🧩` (U+1F9E9) shifts every following offset by 1 and silently corrupts the span (this is the bug that left only the last char bold).

Two safe options:
1. **Avoid astral emoji in any text that carries a span** (the current heading uses plain text + the BMP `↩️` only). Simplest; then `str.find` offsets are correct as-is.
2. If you must include an astral emoji before/inside a span, compute offsets as UTF-16 units: `to = len(s[:idx].encode('utf-16-le'))//2`.

Always validate before sending: for each node assert every span's `to ≤ len(content.encode('utf-16-le'))//2`.

### 4. Post to the channel

Submit the `v1/standard` document to **channel {{POST_CHANNEL_ID}}** (workspace {{WORKSPACE_ID}}) as a top-level `send_channel_message`.

⚠️ **Capability check — MCP build matters (verified 2026-07-08).** Some panchat MCP builds expose `send_channel_message` / `reply_to_thread` with **only a plain `message` string that is stored verbatim** — passing markdown `[label](url)` OR the `v1/standard` JSON just prints the literal text (no chips). Rich-text-capable builds instead accept a structured `rich_text` field: `send_channel_message → { workspace_id: {{WORKSPACE_ID}}, channel_id: {{POST_CHANNEL_ID}}, rich_text: [ ...nodes ] }`.

So, at post time:
1. If the send tool advertises a `rich_text`/structured field → pass the document's blocks there.
2. Else, before trusting spans: send once and **read it back** with `get_thread_messages`; if the parent's attachments show resolved `link`/`mention` spans, the build parses spans — proceed.
3. If spans are NOT resolved (verbatim string) → **fall back** to plain text with bare task URLs on their own lines (still tap-to-open in-app, just no `#num` chip label) and tell the user the chip form needs a rich-text-capable panchat MCP build.

Success returns `{ success: true, message_id/url }`.

### 5. Confirm

Print the digest inline here too, and report it was posted. If `send_channel_message` fails, show the digest inline and report the error — do not silently drop it.

## Notes

- This **posts to a shared channel ({{POST_CHANNEL_ID}})** — that is the intended behavior, so post without re-confirming each time. If the user asks for a "dry run" / "preview" (or passes `dry-run` as the argument), build the digest and show it inline but skip the `send_channel_message` call.
- Task app-links use `metadata:{name:"{{TASK_CHANNEL_NAME}}", type:"channel_message", task_id:<id>}`. See step 3.
- **Structure with list nodes, not text prefixes** (asked for 2026-07-21): bucket headers are `unordered_list_item` at `level: 0`; task lines are `unordered_list_item` at `level: 1`. Never emit `• ` / `  - ` inside `content` — that renders as literal text instead of a real indented bullet.
- **Tappable chips require a rich-text-capable MCP build.** Confirmed 2026-07-08 that the build in use exposed `send_channel_message` with only a verbatim `message` string — markdown and `v1/standard` JSON both printed as literal text. When that's the case, don't post JSON (it shows raw); fall back to bare URLs per step 4 and flag it.
