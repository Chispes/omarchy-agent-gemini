#!/usr/bin/env bash
set -e

# ==============================================================================
# Installer for Omarchy Gemini / Antigravity Agent Collector
# https://github.com/Chispes/omarchy-agent-gemini
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_SRC="$SCRIPT_DIR/bin/omarchy-agent-usage-gemini"
ASSETS_SRC="$SCRIPT_DIR/assets"

BIN_DEST="/usr/bin/omarchy-agent-usage-gemini"
OMARCHY_BIN_DIR="/usr/share/omarchy/bin"
ASSETS_DEST="/usr/share/omarchy/shell/plugins/agents/assets"

echo "==> Installing Omarchy Gemini Usage Collector..."

# Ensure script is executable
chmod +x "$BIN_SRC"

# 1. Install binary to /usr/bin
echo "--> Installing $BIN_DEST..."
sudo install -m 755 "$BIN_SRC" "$BIN_DEST"

# 2. Symlink to /usr/share/omarchy/bin if directory exists
if [ -d "$OMARCHY_BIN_DIR" ]; then
    echo "--> Linking to $OMARCHY_BIN_DIR/omarchy-agent-usage-gemini..."
    sudo ln -sf "$BIN_DEST" "$OMARCHY_BIN_DIR/omarchy-agent-usage-gemini"
fi

# 3. Install Assets (Icons)
if [ -d "$ASSETS_DEST" ]; then
    echo "--> Installing icons to $ASSETS_DEST..."
    if [ -f "$ASSETS_SRC/gemini.svg" ]; then
        sudo install -m 644 "$ASSETS_SRC/gemini.svg" "$ASSETS_DEST/gemini.svg"
    fi
    if [ -f "$ASSETS_SRC/gemini-light.svg" ]; then
        sudo install -m 644 "$ASSETS_SRC/gemini-light.svg" "$ASSETS_DEST/gemini-light.svg"
    fi
fi

# 4. Trigger update as the invoking non-root user if sudo was used
echo "--> Updating agent usage data..."
RUN_USER="${SUDO_USER:-$USER}"

if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    if command -v omarchy-agent-usage-update >/dev/null 2>&1; then
        sudo -u "$RUN_USER" omarchy-agent-usage-update --force || true
    elif [ -x "$OMARCHY_BIN_DIR/omarchy-agent-usage-update" ]; then
        sudo -u "$RUN_USER" "$OMARCHY_BIN_DIR/omarchy-agent-usage-update" --force || true
    fi
else
    if command -v omarchy-agent-usage-update >/dev/null 2>&1; then
        omarchy-agent-usage-update --force || true
    elif [ -x "$OMARCHY_BIN_DIR/omarchy-agent-usage-update" ]; then
        "$OMARCHY_BIN_DIR/omarchy-agent-usage-update" --force || true
    fi
fi

echo ""
echo "✅ Gemini Agent collector installed successfully!"
echo "Open the agents panel or refresh with: omarchy agent usage-update"
