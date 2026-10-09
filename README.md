# dotfiles

My macOS, Linux/WSL2 and Windows (Git Bash) setup, organized by topic (inspired by [holman/dotfiles](https://github.com/holman/dotfiles))
and symlinked with [GNU Stow](https://www.gnu.org/software/stow/).

## Install

```sh
git clone <this-repo> ~/Data/projects/personal/dotfiles
cd ~/Data/projects/personal/dotfiles
./install.sh            # add --macos to also apply macos/defaults.sh
```

**Windows (Git Bash):** turn on Developer Mode (needed for symlinks), then run `./install.sh`
from Git Bash. It shows a checklist of the apps in `Winfile` (space toggles, enter installs
them with winget), links `git claude lazygit mise` without Stow, adds a block to `~/.bashrc`
and clones the nvim config to `%LOCALAPPDATA%\nvim`. `dot add <winget id>` installs one more
app and adds it to `Winfile`.

**WSL2 instead:** install WSL2 with Ubuntu (`wsl --install -d Ubuntu`), clone the repo inside
WSL and run the same `./install.sh`. It detects Linux, installs the `Aptfile`, mise, zoxide,
uv, Claude Code and Neovim, and skips the macOS-only packages (`karabiner`, `hammerspoon`,
`kitty`). Use Windows Terminal as the terminal.

`install.sh` is safe to re-run. On every OS it shows a checklist of the `Brewfile` / `Aptfile` /
`Winfile` packages that are not installed yet (space toggles, enter installs). Add a `# note` after
a package line and it shows up as the description. It installs Homebrew and the `Brewfile`, links every
package with Stow, clones the nvim config and runs `mise install`.

## Day to day

```sh
dot          # pull, re-run install.sh, upgrade mise tools
dot dump     # brew packages installed by hand that aren't in the Brewfile yet
dot add jq   # install a package and record it in Brewfile (macOS) / Aptfile (Linux)
dot add --cask raycast   # macOS app
dot list     # packages tracked for this OS
dot macos    # re-apply macOS defaults
dot edit     # open this repo in $EDITOR
```

Language runtimes are in `mise/.config/mise/config.toml`.

## Layout

Each top-level directory is a **stow package**: its contents mirror `$HOME`.

```
git/.gitconfig                 -> ~/.gitconfig
kitty/.config/kitty/kitty.conf -> ~/.config/kitty/kitty.conf
```

| Path       | Purpose                                          |
|------------|--------------------------------------------------|
| `bin/`     | Personal scripts, added to `$PATH` (not stowed)  |
| `macos/`   | `defaults write` system settings (not stowed)    |
| `Brewfile` | Homebrew packages, casks and fonts (macOS)       |
| `Aptfile`  | apt packages (Linux / WSL2)                      |
| `*/`       | Any other directory is a stow package            |

Stow options (target `~`, ignored `*.zsh` and `omz/`) live in `.stowrc`.
`karabiner/` is linked as a whole directory, because Karabiner replaces its config
file instead of editing it in place. Neovim config is a separate repo
([nvim-dotfiles](https://github.com/thaidmfinnick/nvim-dotfiles)) cloned by `install.sh`.

### Zsh conventions

- `zsh/path.zsh` loads first and sets `$PATH`
- other `*.zsh` files in the repo load next
- `completion.zsh` loads last

### Secrets and machine-specific settings

Never commit them. Put them in `~/.zshrc.local` (or any `*.local` file), which is
sourced if present and ignored by git. Prefer `op read op://...` for API keys.

## Adding a new config

The folder inside the repo copies the file's path relative to your home folder:

```sh
cd ~/Data/projects/personal/dotfiles
mkdir -p <app>/<path relative to ~>
mv ~/<path>/<file> <app>/<path relative to ~>/
stow --no-folding <app>
```

For example:

| Live file | In the repo |
|---|---|
| `~/.config/foo/config.toml` | `foo/.config/foo/config.toml` |
| `~/Library/Application Support/lazygit/config.yml` | `lazygit/Library/Application Support/lazygit/config.yml` |

Leave out files the app writes on its own, like state or cache. `install.sh` picks
up the new folder automatically on the next run.

## Apps

`Brewfile` holds only what Homebrew manages. Everything installed another way
(App Store, direct downloads, curl installers) is listed in [APPS.md](APPS.md).
