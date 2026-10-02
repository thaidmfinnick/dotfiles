#!/usr/bin/env bash
# Bootstrap a Mac from this repo. Safe to re-run.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES"

# Top-level directories that are not stow packages
NOT_PACKAGES=(bin macos script)
# Linked as a whole directory: Karabiner replaces karabiner.json instead of editing it
FOLD_PACKAGES=(karabiner)

info() { printf '\033[34m==>\033[0m %s\n' "$*"; }

# 1. Homebrew
if ! command -v brew >/dev/null 2>&1; then
  info "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 2. Packages
if [[ -f Brewfile ]]; then
  info "Installing Brewfile packages"
  brew bundle --no-upgrade --file=Brewfile  # install missing only, never upgrade
fi
command -v stow >/dev/null 2>&1 || brew install stow

# 3. Symlink every topic directory into $HOME (target and ignores live in .stowrc)
for dir in */; do
  pkg="${dir%/}"
  [[ " ${NOT_PACKAGES[*]} " == *" $pkg "* ]] && continue
  [[ " ${FOLD_PACKAGES[*]} " == *" $pkg "* ]] && fold=() || fold=(--no-folding)
  info "Linking $pkg"
  stow "${fold[@]}" --restow "$pkg"
done

# 4. Neovim config lives in its own repo
if [[ ! -e "$HOME/.config/nvim" ]]; then
  info "Cloning nvim config"
  git clone https://github.com/thaidmfinnick/nvim-dotfiles.git "$HOME/.config/nvim"
fi

# 5. Language runtimes and global npm packages
if command -v mise >/dev/null 2>&1; then
  info "Installing mise tools"
  mise install
fi

# 6. macOS preferences (opt-in: ./install.sh --macos)
if [[ "${1:-}" == "--macos" ]]; then
  info "Applying macOS defaults"
  "$DOTFILES/macos/defaults.sh"
fi

info "Done. Open a new shell to pick up changes."
