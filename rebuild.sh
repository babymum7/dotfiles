#!/usr/bin/env bash
set -euo pipefail

# Default values
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Helper to source Nix daemon profile and add default binary path to PATH
source_nix() {
  if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
    . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  fi
  if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi
  if [ -d "/nix/var/nix/profiles/default/bin" ]; then
    export PATH="/nix/var/nix/profiles/default/bin:$PATH"
  fi
  if [ -d "$HOME/.nix-profile/bin" ]; then
    export PATH="$HOME/.nix-profile/bin:$PATH"
  fi
}

# Check OS support
OS_TYPE=$(uname -s)
if [ "$OS_TYPE" != "Darwin" ] && [ "$OS_TYPE" != "Linux" ]; then
  echo "Error: Unsupported OS: $OS_TYPE" >&2
  exit 1
fi

# Sourcing profile scripts is skipped in dry-run mode to prevent arbitrary shell executions
if [ "$DRY_RUN" = false ]; then
  source_nix
fi

ensure_nix_command() {
  if ! command -v nix &> /dev/null; then
    echo "Error: Nix is not installed or not found in PATH." >&2
    echo "Please run ./bootstrap.sh first, open a new shell, or source the Nix profile manually." >&2
    exit 1
  fi
}

# Resolve flake directory path
DOTFILES_DIR="$HOME/.dotfiles"
CURRENT_DIR=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Check if ~/.dotfiles points to CURRENT_DIR
IS_LINKED=false
if [ -L "$DOTFILES_DIR" ] || [ -e "$DOTFILES_DIR" ]; then
  TARGET_PATH=$(cd -P "$DOTFILES_DIR" &>/dev/null && pwd || echo "")
  if [ "$TARGET_PATH" = "$CURRENT_DIR" ]; then
    IS_LINKED=true
  fi
fi

PHYSICAL_PWD=$(pwd -P)
if [ "$PHYSICAL_PWD" = "$CURRENT_DIR" ]; then
  FLAKE_DIR="."
elif [ "$IS_LINKED" = true ]; then
  FLAKE_DIR="$DOTFILES_DIR"
else
  FLAKE_DIR="$CURRENT_DIR"
fi

# Detect OS and run switch command
OS_TYPE=$(uname -s)
# Rebuild based on OS
if [ "$OS_TYPE" = "Darwin" ]; then
  echo "Detected macOS. Rebuilding nix-darwin configuration..."
  FLAKE_URI="$FLAKE_DIR#macos"
  if [ "$DRY_RUN" = true ]; then
    echo "darwin-rebuild switch --flake $FLAKE_URI"
  else
    if command -v darwin-rebuild &> /dev/null; then
      darwin-rebuild switch --flake "$FLAKE_URI"
    else
      echo "darwin-rebuild not found in PATH. Falling back to nix run..."
      ensure_nix_command
      nix run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake "$FLAKE_URI"
    fi
  fi
else
  echo "Detected Linux. Rebuilding Home Manager configuration..."
  FLAKE_URI="$FLAKE_DIR#linux"
  if [ "$DRY_RUN" = true ]; then
    echo "home-manager switch --flake $FLAKE_URI"
  else
    if command -v home-manager &> /dev/null; then
      home-manager switch --flake "$FLAKE_URI"
    else
      echo "home-manager not found in PATH. Falling back to nix run..."
      ensure_nix_command
      nix run github:nix-community/home-manager/release-26.05 -- switch --flake "$FLAKE_URI"
    fi
  fi
fi
