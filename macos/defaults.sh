#!/usr/bin/env bash
# macOS system preferences. Safe to re-run. Some changes need a logout.
set -euo pipefail

# Dock: autohide, small icons, keep Spaces in a fixed order
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 42
defaults write com.apple.dock mru-spaces -bool false

# Finder: list view by default
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Trackpad: tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Screenshots go to ~/Desktop/Screenshots
mkdir -p "$HOME/Desktop/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Desktop/Screenshots"

# --- Common extras, not applied yet. Uncomment what you want. ---
# Fast key repeat (needs logout)
# defaults write NSGlobalDomain KeyRepeat -int 2
# defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Key repeat instead of the accent popup (nice for vim)
# defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# Finder: show hidden files, all extensions, path bar
# defaults write com.apple.finder AppleShowAllFiles -bool true
# defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# defaults write com.apple.finder ShowPathbar -bool true
# Dock: hide recent apps
# defaults write com.apple.dock show-recents -bool false

killall Dock Finder SystemUIServer 2>/dev/null || true
echo "macOS defaults applied."
