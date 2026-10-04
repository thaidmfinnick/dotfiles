# Apps

Everything I use that is **not** installed with Homebrew (Homebrew packages are in
[`Brewfile`](Brewfile)). Install these by hand on a new Mac.

## Terminal, keyboard & window management

| App | Purpose | Get it |
|---|---|---|
| kitty | Terminal (config: `kitty/`) | https://sw.kovidgoyal.net/kitty/ |
| Karabiner-Elements | Key remapping (config: `karabiner/`) | https://karabiner-elements.pqrs.org |
| Hammerspoon | Automation (config: `hammerspoon/`) | https://www.hammerspoon.org |
| Raycast | Launcher | https://www.raycast.com |
| Rectangle | Window snapping | https://rectangleapp.com |
| OpenKey | Vietnamese input | https://github.com/tuyenvm/OpenKey |

## Development

| App | Purpose | Get it |
|---|---|---|
| Xcode, TestFlight, Transporter | iOS / macOS builds | App Store |
| Android Studio | Android builds | https://developer.android.com/studio |
| Visual Studio Code | Editor (extensions via Settings Sync) | https://code.visualstudio.com |
| Docker Desktop | Containers (also provides `docker`, `kubectl`) | https://www.docker.com/products/docker-desktop |
| Postman | API client | https://www.postman.com/downloads |
| Dash | Offline docs | https://kapeli.com/dash |
| TablePro | Database client | https://tablepro.app |
| Livebook | Elixir notebooks | https://livebook.dev |
| Teleport Connect | Infra access | https://goteleport.com/download |
| Claude | Claude desktop app | https://claude.ai/download |

## Command-line tools (not from Homebrew)

| Tool | Installed via | Location |
|---|---|---|
| mise | `curl https://mise.run \| sh` | `~/.local/bin/mise` |
| Language runtimes (node, erlang, elixir, ruby, flutter, ...) | mise (`mise/.config/mise/config.toml`) | `~/.local/share/mise` |
| zoxide | install script | `~/.local/bin/zoxide` |
| uv / uvx | `curl -LsSf https://astral.sh/uv/install.sh \| sh` | `~/.local/bin` |
| Claude Code | `curl -fsSL https://claude.ai/install.sh \| bash` | `~/.local/bin/claude` |
| herdr | https://herdr.dev (config: `herdr/`, update with `herdr update`) | `~/.local/bin/herdr` |
| Neovim | release tarball (config: [nvim-dotfiles](https://github.com/thaidmfinnick/nvim-dotfiles)) | `/usr/local/nvim` |
| 1Password CLI (`op`) | pkg installer | `/usr/local/bin/op` |
| Go | pkg installer | `/usr/local/go` |
| Python 3.12 | python.org installer | `/Library/Frameworks/Python.framework` |
| MacTeX | pkg installer | `/Library/TeX` |
| oh-my-zsh | install script | `~/.oh-my-zsh` |

## Everyday

| App | Purpose | Get it |
|---|---|---|
| 1Password | Passwords | https://1password.com/downloads |
| Google Chrome | Browser | https://www.google.com/chrome |
| Obsidian | Notes | https://obsidian.md |
| Figma | Design | https://www.figma.com/downloads |
| Shottr | Screenshots | https://shottr.cc |
| Microsoft Word / Excel / PowerPoint | Office | Microsoft 365 |
| Tunnelblick | VPN | https://tunnelblick.net |
| AnyDesk | Remote desktop | https://anydesk.com |
| Windows App | Remote Windows | App Store |
| Horizon | Virtual desktop | Omnissa Horizon Client |

## Work

| App | Get it |
|---|---|
| Pancake Work, Pancake Work 2 | Company |

## After installing, sign in to

1Password (then `op signin`), `gh auth login`, Raycast, Chrome, VS Code Settings Sync.
