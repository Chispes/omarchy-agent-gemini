#!/usr/bin/env bash
set -e

# ==============================================================================
# Uninstaller for the Omarchy Gemini / Antigravity Agent Collector
# https://github.com/Chispes/omarchy-agent-gemini
#
# Removes everything outside the plugin directory, each part only if present,
# so it is equally correct after `install.sh`, after `install.sh --icons-only`,
# and after no install at all:
#
#   /usr/bin/omarchy-agent-usage-gemini and the $OMARCHY_PATH/bin symlink
#   $OMARCHY_PATH/shell/plugins/agents/assets/gemini*.svg
#   the generated record in ~/.local/state/omarchy/agents/usage/gemini.json
#
# The record is removed because nothing else will: the panel draws every record
# in that directory whoever wrote it, so a leftover gemini.json keeps the tab on
# screen, frozen at its last values, long after the plugin is gone.
#
# Run this while the plugin directory still exists -- this script lives in it --
# and remove the plugin afterwards:
#   omarchy plugin remove chispes.agent-gemini
#
# If the plugin stays enabled, its service simply writes the record again at the
# next refresh; only the root-owned paths are gone for good.
# ==============================================================================

OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
BIN_DEST="/usr/bin/omarchy-agent-usage-gemini"
OMARCHY_BIN_LINK="$OMARCHY_PATH/bin/omarchy-agent-usage-gemini"
ASSETS_DEST="$OMARCHY_PATH/shell/plugins/agents/assets"
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

# Passed through explicitly: run under sudo the environment is reset, and the
# update would then glob /bin instead of Omarchy's own bin and refresh nothing.
echo "--> Refreshing Omarchy agents..."
if command -v omarchy-agent-usage-update >/dev/null 2>&1; then
    OMARCHY_PATH="$OMARCHY_PATH" omarchy-agent-usage-update --force || true
fi

echo ""
echo "✅ System-wide Gemini Agent collector removed."
echo "The plugin itself, if still enabled, keeps its own tab:"
echo "  omarchy plugin remove chispes.agent-gemini"
