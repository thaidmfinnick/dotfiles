#!/usr/bin/env bash
# Bootstrap a Mac, a Debian/Ubuntu (WSL2) box or Windows (Git Bash) from this repo.
# Safe to re-run.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES"

# Top-level directories that are not stow packages
NOT_PACKAGES=(bin macos script lib)
# Packages that only make sense on macOS (skipped on Linux / WSL / Windows)
MACOS_ONLY=(karabiner hammerspoon kitty)
# Packages linked on Windows (Git Bash): the rest assume zsh or macOS apps
WINDOWS_PACKAGES=(git claude lazygit mise)
# Linked as a whole directory: Karabiner replaces karabiner.json instead of editing it
FOLD_PACKAGES=(karabiner)

# shellcheck source=lib/menu.sh
source "$DOTFILES/lib/menu.sh"

info() { printf '\033[34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }

case "$(uname -s)" in
  Darwin) OS=mac ;;
  MINGW*|MSYS*|CYGWIN*) OS=windows ;;
  *) OS=linux ;;
esac

# Symlink a package without stow (Git Bash has none). Same rules as .stowrc.
# Needs Windows Developer Mode for real symlinks, otherwise falls back to copying.
link_pkg() {
  local pkg="$1" src rel dest
  export MSYS=winsymlinks:nativestrict
  while IFS= read -r -d '' src; do
    rel="${src#"$pkg"/}"
    case "$rel" in *.zsh|omz/*) continue ;; esac
    dest="$HOME/$rel"
    mkdir -p "$(dirname "$dest")"
    if [[ -L "$dest" ]]; then rm -f "$dest"
    elif [[ -e "$dest" ]]; then mv "$dest" "$dest.bak"; warn "backed up existing $dest"; fi
    if ! ln -s "$DOTFILES/$src" "$dest" 2>/dev/null; then
      cp "$DOTFILES/$src" "$dest"
      warn "symlink failed, copied $rel (enable Developer Mode to get symlinks)"
    fi
  done < <(find "$pkg" -type f -print0)
}

# 1+2. System packages
if [[ "$OS" == mac ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    info "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  command -v stow >/dev/null 2>&1 || brew install stow
  # Offer only what is missing; nothing is ever upgraded
  have="$( { brew list --formula -1; brew list --cask -1; } 2>/dev/null )"
  MENU_LABELS=(); MENU_SEL=(); PICKED=()
  re='^(brew|cask) "([^"]+)"[[:space:]]*(#[[:space:]]*(.*))?$'
  while IFS= read -r line; do
    [[ "$line" =~ $re ]] || continue
    kind="${BASH_REMATCH[1]}"; name="${BASH_REMATCH[2]}"; desc="${BASH_REMATCH[4]:-}"
    grep -qxF "${name##*/}" <<<"$have" && continue
    PICKED+=("$line")
    MENU_LABELS+=("$(printf '%-5s %-26s %s' "$kind" "$name" "$desc")")
    MENU_SEL+=(1)
  done < Brewfile
  if (( ${#PICKED[@]} )); then
    checklist "Homebrew packages to install"
    chosen=()
    for i in "${!PICKED[@]}"; do (( MENU_SEL[i] )) && chosen+=("${PICKED[i]}"); done
    if (( ${#chosen[@]} )); then
      info "Installing selected packages"
      printf '%s\n' "${chosen[@]}" | brew bundle --no-upgrade --file=-
    fi
  else
    info "All Brewfile packages already installed"
  fi

elif [[ "$OS" == windows ]]; then
  command -v winget >/dev/null 2>&1 || { echo "winget not found: update 'App Installer' from the Microsoft Store" >&2; exit 1; }
  MENU_LABELS=(); MENU_SEL=(); WIN_IDS=()
  while IFS='|' read -r id desc on; do
    id="${id//[[:space:]]/}"
    [[ -z "$id" || "$id" == \#* ]] && continue
    desc="${desc#"${desc%%[![:space:]]*}"}"; desc="${desc%"${desc##*[![:space:]]}"}"
    WIN_IDS+=("$id")
    MENU_LABELS+=("$(printf '%-28s %s' "$id" "$desc")")
    [[ "${on//[[:space:]]/}" == on ]] && MENU_SEL+=(1) || MENU_SEL+=(0)
  done < Winfile
  checklist "Apps to install with winget"
  for i in "${!WIN_IDS[@]}"; do
    (( MENU_SEL[i] )) || continue
    info "winget install ${WIN_IDS[i]}"
    winget install -e --id "${WIN_IDS[i]}" --silent \
      --accept-package-agreements --accept-source-agreements || warn "${WIN_IDS[i]}: not installed (already present, or see the error above)"
  done

else
  MENU_LABELS=(); MENU_SEL=(); PICKED=()
  while IFS= read -r line; do
    name="${line%%#*}"; name="${name//[[:space:]]/}"
    [[ -z "$name" ]] && continue
    dpkg -s "$name" >/dev/null 2>&1 && continue
    desc=""; [[ "$line" == *'#'* ]] && desc="${line#*#}"
    PICKED+=("$name")
    MENU_LABELS+=("$(printf '%-26s %s' "$name" "$desc")")
    MENU_SEL+=(1)
  done < Aptfile
  if (( ${#PICKED[@]} )); then
    checklist "apt packages to install"
    chosen=()
    for i in "${!PICKED[@]}"; do (( MENU_SEL[i] )) && chosen+=("${PICKED[i]}"); done
    if (( ${#chosen[@]} )); then
      info "Installing selected packages"
      sudo apt-get update -qq
      sudo apt-get install -y "${chosen[@]}"
    fi
  fi
  mkdir -p "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$PATH"

  command -v mise >/dev/null 2>&1 || { info "Installing mise"; curl -fsSL https://mise.run | sh; }
  command -v zoxide >/dev/null 2>&1 || { info "Installing zoxide"; curl -sSf https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; }
  command -v uv >/dev/null 2>&1 || { info "Installing uv"; curl -LsSf https://astral.sh/uv/install.sh | sh; }
  command -v claude >/dev/null 2>&1 || { info "Installing Claude Code"; curl -fsSL https://claude.ai/install.sh | bash; }
  if ! command -v nvim >/dev/null 2>&1; then
    info "Installing Neovim"   # apt's neovim is too old, use the release tarball
    arch="$(uname -m)"; [[ "$arch" == aarch64 ]] && arch=arm64
    curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$arch.tar.gz" \
      | tar -xz -C "$HOME/.local"
    ln -sf "$HOME/.local/nvim-linux-$arch/bin/nvim" "$HOME/.local/bin/nvim"
  fi
  if [[ ! -d "$HOME/.local/share/zsh-vi-mode" ]]; then
    git clone --depth 1 https://github.com/jeffreytse/zsh-vi-mode.git "$HOME/.local/share/zsh-vi-mode"
  fi
fi

# 3. Symlink every topic directory into $HOME (target and ignores live in .stowrc)
for dir in */; do
  pkg="${dir%/}"
  [[ " ${NOT_PACKAGES[*]} " == *" $pkg "* ]] && continue
  [[ "$OS" != mac && " ${MACOS_ONLY[*]} " == *" $pkg "* ]] && continue
  [[ "$OS" == windows && " ${WINDOWS_PACKAGES[*]} " != *" $pkg "* ]] && continue
  info "Linking $pkg"
  if [[ "$OS" == windows ]]; then
    link_pkg "$pkg"
  else
    # macOS bash 3.2 + set -u rejects "${empty[@]}", so pass the flag as a plain string
    [[ " ${FOLD_PACKAGES[*]} " == *" $pkg "* ]] && fold="" || fold="--no-folding"
    stow $fold --restow "$pkg"
  fi
done

# 3b. Windows: Git Bash reads ~/.bashrc, so add the few lines zsh/ would have provided
if [[ "$OS" == windows ]]; then
  marker="# >>> dotfiles >>>"
  if ! grep -qF "$marker" "$HOME/.bashrc" 2>/dev/null; then
    info "Adding dotfiles block to ~/.bashrc"
    cat >> "$HOME/.bashrc" <<BASHRC

$marker
export DOTFILES="$DOTFILES"
export PATH="\$DOTFILES/bin:\$HOME/.local/bin:\$PATH"
export EDITOR=nvim VISUAL=nvim
export LG_CONFIG_FILE="\$HOME/.config/lazygit/config.yml"
command -v mise >/dev/null 2>&1 && eval "\$(mise activate bash)"
command -v zoxide >/dev/null 2>&1 && eval "\$(zoxide init bash)"
# <<< dotfiles <<<
BASHRC
  fi
fi

# 4. oh-my-zsh (KEEP_ZSHRC: keep the .zshrc linked above)
if [[ "$OS" != windows && ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Installing oh-my-zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 5. Neovim config lives in its own repo (Neovim on Windows reads %LOCALAPPDATA%\nvim)
if [[ "$OS" == windows ]]; then nvim_dir="${LOCALAPPDATA:-$HOME/AppData/Local}/nvim"; else nvim_dir="$HOME/.config/nvim"; fi
if [[ ! -e "$nvim_dir" ]]; then
  info "Cloning nvim config"
  git clone https://github.com/thaidmfinnick/nvim-dotfiles.git "$nvim_dir"
fi

# 6. Language runtimes (mise)
if command -v mise >/dev/null 2>&1; then
  info "Installing mise tools"
  mise install
fi

# 7. macOS preferences (opt-in: ./install.sh --macos)
if [[ "${1:-}" == "--macos" && "$OS" == mac ]]; then
  info "Applying macOS defaults"
  "$DOTFILES/macos/defaults.sh"
fi

info "Done. Open a new shell to pick up changes."
