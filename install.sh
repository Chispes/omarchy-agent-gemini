#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# System-wide installer for the Omarchy Gemini / Antigravity Agent Collector
# https://github.com/Chispes/omarchy-agent-gemini
#
# OPTIONAL. Installed as a plugin (`omarchy plugin add ... --enable`), the
# Gemini tab already appears: the plugin's own service runs the bundled
# collector and writes the usage record, no root involved. This script is for
# the two things that genuinely need root, and nothing else:
#
#   /usr/bin/omarchy-agent-usage-gemini                    the collector, so it
#   $OMARCHY_PATH/bin/omarchy-agent-usage-gemini           refreshes alongside
#                                                          Omarchy's own agents
#   $OMARCHY_PATH/shell/plugins/agents/assets/gemini*.svg  the Gemini mark, in
#                                                          place of the bar glyph
#
# The mark is the half most people are actually here for, and it is the half
# with no plugin-side workaround: Panel.qml resolves a provider's icon as
# Qt.resolvedUrl("assets/<id>.svg") against its own root-owned directory, so a
# plugin that cannot write there gets the generic glyph no matter what it ships.
# `--icons-only` installs just that, and touches nothing else.
#
# No user configuration is read or written.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_SRC="$SCRIPT_DIR/bin/omarchy-agent-usage-gemini"
ASSETS_SRC="$SCRIPT_DIR/assets"

OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
BIN_DEST="/usr/bin/omarchy-agent-usage-gemini"
OMARCHY_BIN_DIR="$OMARCHY_PATH/bin"
ASSETS_DEST="$OMARCHY_PATH/shell/plugins/agents/assets"

ICONS_ONLY=0

fail() {
  echo "install.sh: $*" >&2
  exit 1
}

usage() {
  cat <<USAGE
Usage: install.sh [--icons-only]

  (no options)  Install the collector system-wide and the Gemini mark.
  --icons-only  Install only gemini.svg / gemini-light.svg into
                $ASSETS_DEST, so the Agents panel draws the Gemini mark
                instead of its generic glyph. Nothing else is touched.
USAGE
}

while (( $# > 0 )); do
  case "$1" in
  --icons-only)
    ICONS_ONLY=1
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    fail "unknown option: $1"
    ;;
  esac
done

# The mark is the only reason to run this script with --icons-only, so a
# missing assets directory is an error there and a skippable extra otherwise.
install_icons() {
  if [ ! -d "$ASSETS_DEST" ]; then
    if (( ICONS_ONLY )); then
      fail "$ASSETS_DEST not found -- is Omarchy installed?"
    fi
    echo "--> Icons skipped ($ASSETS_DEST not found); the panel will use its bar glyph."
    return 0
  fi

  echo "--> Installing icons to $ASSETS_DEST..."
  for icon in gemini.svg gemini-light.svg; do
    if [ -f "$ASSETS_SRC/$icon" ]; then
      sudo install -m 644 "$ASSETS_SRC/$icon" "$ASSETS_DEST/$icon"
    fi
  done
}

if (( ICONS_ONLY )); then
  echo "==> Installing the Gemini mark for the Omarchy Agents panel..."
  install_icons
  echo ""
  echo "✅ Gemini mark installed."
  echo "The panel picks it up on the next shell start: omarchy restart shell"
  exit 0
fi

echo "==> Installing Omarchy Gemini Usage Collector system-wide..."

[ -f "$BIN_SRC" ] || fail "collector missing at $BIN_SRC"
command -v python3 >/dev/null 2>&1 || fail "python3 is required to run the collector"

# omarchy-agent-usage-update discovers collectors by globbing
# "$OMARCHY_PATH"/bin/omarchy-agent-usage-* and nothing else, so without that
# directory the collector would install and then never be run by anything.
# Skipping the link quietly is how an install "succeeds" and does nothing.
[ -d "$OMARCHY_BIN_DIR" ] || fail "$OMARCHY_BIN_DIR not found -- is Omarchy installed?"

chmod +x "$BIN_SRC"

echo "--> Installing $BIN_DEST..."
sudo install -m 755 "$BIN_SRC" "$BIN_DEST"

echo "--> Linking $OMARCHY_BIN_DIR/omarchy-agent-usage-gemini..."
sudo ln -sf "$BIN_DEST" "$OMARCHY_BIN_DIR/omarchy-agent-usage-gemini"

install_icons

# Refresh as the invoking user: the record belongs under their XDG state dir,
# and running the collector as root would write it into root's.
#
# OMARCHY_PATH is passed through explicitly because sudo resets the
# environment. Without it the update globs /bin/omarchy-agent-usage-* instead
# of Omarchy's own bin, finds no collectors at all, and still exits 0 -- an
# install that reports success and refreshes nothing.
echo "--> Updating agent usage data..."
RUN_USER="${SUDO_USER:-$USER}"
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
  sudo -u "$RUN_USER" env OMARCHY_PATH="$OMARCHY_PATH" \
    omarchy-agent-usage-update gemini --force || true
else
  OMARCHY_PATH="$OMARCHY_PATH" omarchy-agent-usage-update gemini --force || true
fi

echo ""
echo "✅ Gemini Agent collector installed system-wide!"
echo "Open the agents panel or refresh with: omarchy agent usage-update"
