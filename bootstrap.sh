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

# Validate username to prevent injection/path vulnerabilities
if [[ ! "$USER_NAME" =~ ^[a-zA-Z0-9_][a-zA-Z0-9._-]{0,31}$ ]]; then
  echo "Error: Invalid username '$USER_NAME'. Usernames must start with an alphanumeric character or underscore, and contain only alphanumeric characters, dots, hyphens, and underscores (1-32 chars)." >&2
  exit 1
fi

# Check OS support
OS_TYPE=$(uname -s)
if [ "$OS_TYPE" != "Darwin" ] && [ "$OS_TYPE" != "Linux" ]; then
  echo "Error: Unsupported OS: $OS_TYPE" >&2
  exit 1
fi

echo "=== Nix Dotfiles Bootstrap ==="
echo "Target User: $USER_NAME"
if [ "$DRY_RUN" = true ]; then
  echo "[Dry Run Mode] No changes will be applied."
fi

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

# Ensure Nix environment is sourced if Nix is not currently in PATH (skip during dry-run to avoid arbitrary execution)
if [ "$DRY_RUN" = false ]; then
  source_nix
fi

# 1. Check if Nix is installed
if ! command -v nix &> /dev/null; then
  echo "Nix not found. Installing Determinate Nix..."
  if [ "$DRY_RUN" = true ]; then
    echo "[Dry Run] Would run: curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
  else
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    source_nix
    if ! command -v nix &> /dev/null; then
      echo "Error: Nix installation succeeded but 'nix' command is still not found in PATH." >&2
      exit 1
    fi
  fi
else
  echo "Nix is already installed."
fi
# 2. Symlink current directory to ~/.dotfiles
DOTFILES_DIR="$HOME/.dotfiles"
CURRENT_DIR=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Prevent nested directory loop/relocation error
DOTFILES_PHYSICAL=$(cd -P "$DOTFILES_DIR" &>/dev/null && pwd || echo "")
if [ -n "$DOTFILES_PHYSICAL" ] && [ "$CURRENT_DIR" != "$DOTFILES_PHYSICAL" ]; then
  case "$CURRENT_DIR" in
    "$DOTFILES_PHYSICAL"/*)
      echo "Error: The repository directory ($CURRENT_DIR) is located inside $DOTFILES_DIR ($DOTFILES_PHYSICAL)." >&2
      echo "Please move the repository outside of $DOTFILES_DIR before running bootstrap." >&2
      exit 1
      ;;
  esac
fi

if [ "$CURRENT_DIR" != "$DOTFILES_DIR" ]; then
  DOTFILES_EXISTS=false
  if [ -e "$DOTFILES_DIR" ] || [ -L "$DOTFILES_DIR" ]; then
    DOTFILES_EXISTS=true
  fi

  TARGET_PATH=""
  if [ "$DOTFILES_EXISTS" = true ]; then
    TARGET_PATH=$(cd -P "$DOTFILES_DIR" &>/dev/null && pwd || echo "")
  fi

  if [ "$TARGET_PATH" != "$CURRENT_DIR" ]; then
    echo "Symlinking $CURRENT_DIR to $DOTFILES_DIR..."
    if [ "$DRY_RUN" = true ]; then
      echo "[Dry Run] Would create symlink: ln -sfn $CURRENT_DIR $DOTFILES_DIR"
    else
      if [ "$DOTFILES_EXISTS" = true ]; then
        BACKUP_SUFFIX=$(date +%Y%m%d%H%M%S)
        BACKUP_PATH="${DOTFILES_DIR}.bak.${BACKUP_SUFFIX}"
        COUNTER=1
        while [ -e "$BACKUP_PATH" ] || [ -L "$BACKUP_PATH" ]; do
          BACKUP_PATH="${DOTFILES_DIR}.bak.${BACKUP_SUFFIX}.${COUNTER}"
          COUNTER=$((COUNTER + 1))
        done
        echo "Backing up existing $DOTFILES_DIR to $BACKUP_PATH"
        mv "$DOTFILES_DIR" "$BACKUP_PATH"
      fi
      ln -sfn "$CURRENT_DIR" "$DOTFILES_DIR"
    fi
  else
    echo "$DOTFILES_DIR is already correctly symlinked to $CURRENT_DIR."
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
    SAFE_USER=$(printf '%s\n' "$USER_NAME" | sed 's/\\/\\\\/g; s/\//\\\//g; s/\&/\\\&/g')
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' -E 's/user = "[^"]*";/user = "'"$SAFE_USER"'";/' "$FLAKE_PATH"
    else
      sed -i -E 's/user = "[^"]*";/user = "'"$SAFE_USER"'";/' "$FLAKE_PATH"
    fi
  fi
else
  echo "Warning: $FLAKE_PATH not found, skipping username update."
fi
# 4. Run initial Nix switch based on OS
if [ "$OS_TYPE" = "Darwin" ]; then
  echo "Detected macOS."
  cmd=(nix run github:nix-darwin/nix-darwin/master#darwin-rebuild -- switch --flake "$DOTFILES_DIR#macos")
else
  echo "Detected Linux."
  cmd=(nix run github:nix-community/home-manager -- switch --flake "$DOTFILES_DIR#linux")
fi

echo "Running initial configuration switch..."
if [ "$DRY_RUN" = true ]; then
  printf "[Dry Run] Would run: "
  printf '%q ' "${cmd[@]}"
  echo ""
else
  "${cmd[@]}"
fi
