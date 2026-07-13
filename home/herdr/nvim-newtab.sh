#!/bin/bash
# herdr new tab nvim launcher script
# Creates a new tab in the current workspace and launches standard Neovim instantly via Nushell integration

HERDR_BIN=$(command -v herdr) || { echo "Error: herdr binary not found in PATH." >&2; exit 1; }

# Ensure socket path is set
if [ -z "$HERDR_SOCKET_PATH" ]; then
    export HERDR_SOCKET_PATH="$HOME/.config/herdr/herdr.sock"
fi

# Create a new tab in the current workspace, inherit working directory and trigger instant exec in Nushell
TAB_CWD="${HERDR_ACTIVE_PANE_CWD:-$HOME}"
$HERDR_BIN tab create ${HERDR_ACTIVE_WORKSPACE_ID:+--workspace "$HERDR_ACTIVE_WORKSPACE_ID"} --cwd "$TAB_CWD" --env NU_NVIM_EXPLORER=2 --focus
