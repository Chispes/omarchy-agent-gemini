#!/usr/bin/env bash
set -e

# ==============================================================================
# Uninstaller for Omarchy Gemini / Antigravity Agent Collector
# https://github.com/Chispes/omarchy-agent-gemini
# ==============================================================================

BIN_DEST="/usr/bin/omarchy-agent-usage-gemini"
OMARCHY_BIN_LINK="/usr/share/omarchy/bin/omarchy-agent-usage-gemini"
ASSETS_DEST="/usr/share/omarchy/shell/plugins/agents/assets"
STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/agents/usage/gemini.json"

echo "==> Uninstalling Omarchy Gemini Usage Collector..."

# Remove binaries and symlinks
if [ -f "$BIN_DEST" ]; then
    echo "--> Removing $BIN_DEST..."
    sudo rm -f "$BIN_DEST"
fi

if [ -L "$OMARCHY_BIN_LINK" ] || [ -f "$OMARCHY_BIN_LINK" ]; then
    echo "--> Removing $OMARCHY_BIN_LINK..."
    sudo rm -f "$OMARCHY_BIN_LINK"
fi

# Remove assets
if [ -f "$ASSETS_DEST/gemini.svg" ]; then
    echo "--> Removing $ASSETS_DEST/gemini.svg..."
    sudo rm -f "$ASSETS_DEST/gemini.svg"
fi

if [ -f "$ASSETS_DEST/gemini-light.svg" ]; then
    echo "--> Removing $ASSETS_DEST/gemini-light.svg..."
    sudo rm -f "$ASSETS_DEST/gemini-light.svg"
fi

# Remove generated usage state
if [ -f "$STATE_FILE" ]; then
    echo "--> Removing state file $STATE_FILE..."
    rm -f "$STATE_FILE"
fi

echo "--> Refreshing Omarchy agents..."
if command -v omarchy-agent-usage-update >/dev/null 2>&1; then
    omarchy-agent-usage-update --force || true
fi

echo ""
echo "✅ Gemini Agent collector uninstalled successfully."
