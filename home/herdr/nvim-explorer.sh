#!/bin/bash
# herdr nvim explorer helper script
# Splits current pane vertically (right) and launches fullscreen Snacks explorer instantly via Nushell integration

HERDR_BIN=$(command -v herdr) || { echo "Error: herdr binary not found in PATH." >&2; exit 1; }

# Ensure socket path is set
if [ -z "$HERDR_SOCKET_PATH" ]; then
    export HERDR_SOCKET_PATH="$HOME/.config/herdr/herdr.sock"
fi

# Split current pane and get the new pane ID
SPLIT_CWD="${HERDR_ACTIVE_PANE_CWD:-$HOME}"
NEW_PANE_JSON=$($HERDR_BIN pane split ${HERDR_ACTIVE_PANE_ID:+--pane "$HERDR_ACTIVE_PANE_ID"} --direction right --cwd "$SPLIT_CWD")
NEW_PANE_ID=$(echo "$NEW_PANE_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["result"]["pane"]["pane_id"])')

# Run nvim with Oil on the new pane, then exit to close the pane
$HERDR_BIN pane run "$NEW_PANE_ID" "nvim -c Oil; exit"
