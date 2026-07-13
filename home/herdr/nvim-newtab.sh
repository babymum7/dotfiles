#!/bin/bash
# herdr new tab nvim launcher script
# Creates a new tab in the current workspace and launches standard Neovim instantly via Nushell integration

HERDR_BIN=$(command -v herdr) || { echo "Error: herdr binary not found in PATH." >&2; exit 1; }

# Ensure socket path is set
if [ -z "$HERDR_SOCKET_PATH" ]; then
    export HERDR_SOCKET_PATH="$HOME/.config/herdr/herdr.sock"
fi

# Create a new tab in the current workspace, get the new tab's root pane ID
TAB_CWD="${HERDR_ACTIVE_PANE_CWD:-$HOME}"
NEW_TAB_JSON=$($HERDR_BIN tab create ${HERDR_ACTIVE_WORKSPACE_ID:+--workspace "$HERDR_ACTIVE_WORKSPACE_ID"} --cwd "$TAB_CWD" --focus)
NEW_PANE_ID=$(echo "$NEW_TAB_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["result"]["root_pane"]["pane_id"])')

# Run nvim with Oil on the new tab's root pane, then exit to close the tab
$HERDR_BIN pane run "$NEW_PANE_ID" "nvim -c Oil; exit"
