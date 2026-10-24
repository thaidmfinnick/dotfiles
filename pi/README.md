# pi coding agent

Config for the [pi](https://pi.dev) coding agent. Stows to `~/.pi/agent/`.

```bash
stow --adopt --no-folding --target="$HOME" pi
git diff   # expect empty; investigate anything that shows up
```

`--adopt` is required the first time because a real `~/.pi/agent/` already
exists on a machine where pi has run. It absorbs the live files into this repo
and replaces them with symlinks. Always `git diff` afterwards to confirm the
machine's files matched what is committed here.

## What is tracked

| Path | Contents |
| --- | --- |
| `.pi/agent/settings.json` | Installed packages, powerline layout, extension toggles |
| `.pi/agent/extensions/*.ts` | Personal single-file extensions (e.g. `context-bar.ts`) |

Nothing else. Extensions installed with `pi install npm:<pkg>` are recorded in
`settings.json` and restored by rerunning that command, so `npm/node_modules/`
is never committed.

## Credentials are machine-local and never committed

pi writes secrets into the same directory tree as its config:

| File | Why it stays local |
| --- | --- |
| `.pi/agent/auth.json` | OAuth access/refresh tokens for every provider |
| `.pi/agent/claude-account-source.txt` | Account identity |
| `.pi/agent/sessions/` | Full conversation history, may quote secrets |
| `.pi/agent/memory/` | Agent memory, may quote secrets |
| `.pi/agent/models-store.json`, `mcp-onboarding.json`, `missions/` | Machine state |

`.gitignore` therefore uses an **allowlist**, not a denylist:

```gitignore
pi/.pi/**
!pi/.pi/agent/
!pi/.pi/agent/settings.json
!pi/.pi/agent/extensions/
!pi/.pi/agent/extensions/*.ts
```

Everything under `pi/.pi/` is ignored by default and only the two entries above
are re-admitted. A denylist would silently leak any new secret file a future pi
version starts writing; the allowlist fails closed instead.

On a new machine, authenticate with `pi` directly — `/login anthropic`. Do not
copy `auth.json` between machines.

Verify before committing:

```bash
git add -An pi/   # must list only settings.json and extensions/*.ts
```
