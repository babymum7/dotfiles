#!/bin/bash
# herdr nvim explorer helper script
# Splits current pane vertically (right) and launches fullscreen Snacks explorer instantly via Nushell integration

HERDR_BIN=$(command -v herdr) || { echo "Error: herdr binary not found in PATH." >&2; exit 1; }

# Ensure socket path is set
if [ -z "$HERDR_SOCKET_PATH" ]; then
    export HERDR_SOCKET_PATH="$HOME/.config/herdr/herdr.sock"
fi

# Split current pane and pass env to trigger instant exec in Nushell
SPLIT_CWD="${HERDR_ACTIVE_PANE_CWD:-$HOME}"
$HERDR_BIN pane split ${HERDR_ACTIVE_PANE_ID:+--pane "$HERDR_ACTIVE_PANE_ID"} --direction right --cwd "$SPLIT_CWD" --env NU_NVIM_EXPLORER=1 --focus
