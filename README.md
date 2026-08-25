# omarchy-agent-gemini 🌟

> **Google Gemini / Antigravity usage and token collector for Omarchy Linux.**

Integrates Google Gemini and Antigravity CLI (`agy`) tracking into Omarchy's official **Agents** (`omarchy.agents`) bar widget and panel.

---

## ✨ Features

- 📊 **Daily Token Consumption:** Displays 7-day token bar charts directly in the Omarchy panel.
- 🤖 **Model Breakdown:** Shows token metrics grouped by model (e.g. `gemini-3.7-flash`, `gemini-2.5-pro`, `gemini-2.5-flash`).
- ⚡ **Antigravity CLI Support:** Reads sessions, prompt history, transcripts, and active account from `~/.gemini/antigravity-cli/`.
- 🔌 **Multi-Harness Scans:** Automatically aggregates Gemini sessions run through `opencode`, `pi`, and `omp`.
- 🎨 **Native Icons:** Includes official Gemini sparkle icons for dark and light surfaces in Omarchy.
- 🔒 **Zero-Config & Seamless:** Works alongside Omarchy's built-in Claude, Codex, and Fireworks collectors.

---

## 🚀 Installation

### Quick Install

Clone the repository and run the installer:

```bash
git clone https://github.com/Chispes/omarchy-agent-gemini.git
cd omarchy-agent-gemini
./install.sh
```

### What the installer does:

1. Installs `/usr/bin/omarchy-agent-usage-gemini` (executable collector script).
2. Symlinks `/usr/share/omarchy/bin/omarchy-agent-usage-gemini` -> `/usr/bin/omarchy-agent-usage-gemini`.
3. Copies `gemini.svg` and `gemini-light.svg` into `/usr/share/omarchy/shell/plugins/agents/assets/`.
4. Triggers `omarchy agent usage-update` to immediately refresh data in the bar.

---

## 🔍 How it Works

Omarchy's `omarchy.agents` plugin discovers any collector script matching `/usr/bin/omarchy-agent-usage-*`.

When `omarchy-agent-usage-update` runs (periodically or on demand), it calls `omarchy-agent-usage-gemini`, which:

1. Analyzes local Antigravity history (`~/.gemini/antigravity-cli/history.jsonl` & `conversation_summaries.db`).
2. Checks transcripts in `~/.gemini/antigravity-cli/brain/` for step and token metrics.
3. Queries `~/.local/share/opencode/opencode.db` and `~/.pi/agent/sessions/` for Gemini sessions.
4. Detects the signed-in Google account from `~/.gemini/google_accounts.json`.
5. Outputs a standardized JSON record to `~/.local/state/omarchy/agents/usage/gemini.json`.

The Omarchy QML UI automatically watches this file, creates a Gemini tab/chip, and displays usage in the dashboard.

---

## 🛠 Manual Usage & Testing

You can run the collector manually at any time:

```bash
omarchy-agent-usage-gemini
```

Or force an update across all Omarchy agents:

```bash
omarchy agent usage-update --force
```

To toggle the Agents panel from the terminal:

```bash
omarchy-shell omarchy.agents toggle
```

---

## 🗑 Uninstallation

To remove the collector and assets:

```bash
./uninstall.sh
```

---

## 📄 License

MIT © [Chispes](https://github.com/Chispes)
