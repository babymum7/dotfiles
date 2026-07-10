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

# Resolve flake directory path
DOTFILES_DIR="$HOME/.dotfiles"
CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [ -d "$DOTFILES_DIR" ]; then
  FLAKE_DIR="$DOTFILES_DIR"
else
  FLAKE_DIR="$CURRENT_DIR"
fi

# Detect OS and run switch command
OS_TYPE=$(uname -s)
if [ "$OS_TYPE" = "Darwin" ]; then
  echo "Detected macOS. Rebuilding nix-darwin configuration..."
  REBUILD_CMD="darwin-rebuild switch --flake $FLAKE_DIR#macos"
elif [ "$OS_TYPE" = "Linux" ]; then
  echo "Detected Linux. Rebuilding Home Manager configuration..."
  REBUILD_CMD="home-manager switch --flake $FLAKE_DIR#linux"
else
  echo "Unsupported OS: $OS_TYPE" >&2
  exit 1
fi

echo "Executing: $REBUILD_CMD"
if [ "$DRY_RUN" = true ]; then
  echo "[Dry Run] Would execute rebuild command."
else
  eval "$REBUILD_CMD"
fi

echo "Rebuild complete!"
