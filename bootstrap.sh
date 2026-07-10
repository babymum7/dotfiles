#!/usr/bin/env bash
set -euo pipefail

# Default values
DRY_RUN=false
USER_NAME=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --user)
      if [ -z "${2:-}" ]; then
        echo "Error: --user requires an argument" >&2
        exit 1
      fi
      USER_NAME="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# If user is not specified, detect using whoami
if [ -z "$USER_NAME" ]; then
  USER_NAME=$(whoami)
fi

echo "=== Nix Dotfiles Bootstrap ==="
echo "Target User: $USER_NAME"
if [ "$DRY_RUN" = true ]; then
  echo "[Dry Run Mode] No changes will be applied."
fi

# 1. Check if Nix is installed
if ! command -v nix &> /dev/null && [ ! -d /nix ]; then
  echo "Nix not found. Installing Determinate Nix..."
  if [ "$DRY_RUN" = true ]; then
    echo "[Dry Run] Would run: curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
  else
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  fi
else
  echo "Nix is already installed."
fi

# 2. Symlink current directory to ~/.dotfiles
DOTFILES_DIR="$HOME/.dotfiles"
CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [ "$CURRENT_DIR" != "$DOTFILES_DIR" ]; then
  echo "Symlinking $CURRENT_DIR to $DOTFILES_DIR..."
  if [ "$DRY_RUN" = true ]; then
    echo "[Dry Run] Would create symlink: ln -sfn $CURRENT_DIR $DOTFILES_DIR"
  else
    if [ -L "$DOTFILES_DIR" ] || [ -e "$DOTFILES_DIR" ]; then
      TARGET_PATH=$(readlink -f "$DOTFILES_DIR" || echo "")
      if [ "$TARGET_PATH" != "$CURRENT_DIR" ]; then
        echo "Backing up existing $DOTFILES_DIR to ${DOTFILES_DIR}.bak"
        mv "$DOTFILES_DIR" "${DOTFILES_DIR}.bak"
        ln -sfn "$CURRENT_DIR" "$DOTFILES_DIR"
      fi
    else
      ln -sfn "$CURRENT_DIR" "$DOTFILES_DIR"
    fi
  fi
else
  echo "Repo is already at $DOTFILES_DIR."
fi

# 3. Update username in flake.nix
FLAKE_PATH="$CURRENT_DIR/flake.nix"
if [ -f "$FLAKE_PATH" ]; then
  echo "Updating username in $FLAKE_PATH to '$USER_NAME'..."
  if [ "$DRY_RUN" = true ]; then
    echo "[Dry Run] Would update user variable in $FLAKE_PATH"
  else
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' -E 's/user = "[^"]*";/user = "'"$USER_NAME"'";/' "$FLAKE_PATH"
    else
      sed -i -E 's/user = "[^"]*";/user = "'"$USER_NAME"'";/' "$FLAKE_PATH"
    fi
  fi
else
  echo "Warning: $FLAKE_PATH not found, skipping username update."
fi

# 4. Detect OS and run initial Nix switch
OS_TYPE=$(uname -s)
if [ "$OS_TYPE" = "Darwin" ]; then
  echo "Detected macOS."
  BUILD_CMD="nix run github:nix-darwin/nix-darwin/master#darwin-rebuild -- switch --flake $DOTFILES_DIR#macos"
elif [ "$OS_TYPE" = "Linux" ]; then
  echo "Detected Linux."
  BUILD_CMD="nix run github:nix-community/home-manager -- switch --flake $DOTFILES_DIR#linux"
else
  echo "Unsupported OS: $OS_TYPE" >&2
  exit 1
fi

echo "Running initial configuration switch..."
if [ "$DRY_RUN" = true ]; then
  echo "[Dry Run] Would run: $BUILD_CMD"
else
  eval "$BUILD_CMD"
fi

echo "Bootstrap process complete!"
