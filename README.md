# omarchy-agent-gemini 🌟

> **Google Gemini / Antigravity usage, token collector, and rate limits plugin for Omarchy Linux.**

Integrates Google Gemini and Antigravity CLI (`agy`) tracking into Omarchy's official **Agents** (`omarchy.agents`) bar widget and dashboard.

---

## ✨ Features

- 📊 **Daily Token Consumption:** Displays 7-day token bar charts directly in the Omarchy panel.
- ⏱️ **Rate Limits & Quotas:** Tracks both 5-hour session and 7-day weekly rate limit meters and reset countdowns.
- 🤖 **Model Breakdown:** Shows token metrics grouped by model (e.g. `gemini-3.7-flash`, `gemini-2.5-pro`, `gemini-2.5-flash`).
- ⚡ **Antigravity CLI Support:** Reads sessions, prompt history, transcripts, and active account from `~/.gemini/antigravity-cli/`.
- 🔌 **Multi-Harness Scans:** Automatically aggregates Gemini sessions run through `opencode`, `pi`, and `omp`.
- 🎨 **Official Logos:** Includes Google Gemini sparkle icons for dark and light surfaces in Omarchy.
- 🔒 **Zero-Config & Seamless:** Works alongside Omarchy's built-in Claude, Codex, and Fireworks collectors.

---

## 🚀 Installation

### Quick Install (Recommended)

Clone the repository and run the installer:

```bash
git clone https://github.com/Chispes/omarchy-agent-gemini.git
cd omarchy-agent-gemini
sudo ./install.sh
```

### Requirements

- Omarchy (the installer needs `$OMARCHY_PATH/bin`, default `/usr/share/omarchy/bin`)
- `python3` — the only runtime dependency; the collector uses the standard library alone.

### What the installer does:

1. Installs `/usr/bin/omarchy-agent-usage-gemini` (executable collector script).
2. Symlinks `$OMARCHY_PATH/bin/omarchy-agent-usage-gemini` -> `/usr/bin/omarchy-agent-usage-gemini`.
   This is the discovery path; the install fails loudly if the directory is absent.
3. Copies `gemini.svg` and `gemini-light.svg` into `$OMARCHY_PATH/shell/plugins/agents/assets/`.
   Optional — without them the panel falls back to its own bar glyph.
4. Triggers `omarchy agent usage-update gemini` to refresh data in the bar.

It requires `sudo` for steps 1–3 and writes nowhere else; no user configuration is
read or modified. `uninstall.sh` removes exactly those three paths plus the generated
record in `~/.local/state/omarchy/agents/usage/gemini.json`.

---

## 🔍 How it Works

`omarchy-agent-usage-update` discovers collectors by globbing
`$OMARCHY_PATH/bin/omarchy-agent-usage-*` (`/usr/share/omarchy/bin/` by default) — that
symlink is what makes the collector run, which is why the installer treats a missing
`$OMARCHY_PATH/bin` as a hard error rather than skipping it. The binary itself lives in
`/usr/bin`, mirroring how Omarchy ships its own `claude`, `codex`, and `fireworks`
collectors.

When `omarchy-agent-usage-update` runs (periodically or on demand), it calls `omarchy-agent-usage-gemini`, which:

1. Probes active Gemini & Antigravity rate limit quotas and reset timestamps.
2. Analyzes local Antigravity history (`~/.gemini/antigravity-cli/history.jsonl` & `conversation_summaries.db`).
3. Checks transcripts in `~/.gemini/antigravity-cli/brain/` for step and token metrics.
4. Queries `~/.local/share/opencode/opencode.db` and `~/.pi/agent/sessions/` for Gemini sessions.
5. Detects the signed-in Google account from `~/.gemini/google_accounts.json`.
6. Outputs a standardized JSON record to `~/.local/state/omarchy/agents/usage/gemini.json`.

The Omarchy QML UI automatically watches this file, creates a Gemini tab/chip, and displays usage in the dashboard.

---

## 🛡 Resource bounds

The collector reads local history that the user's own tooling produces, so its
cost is bounded on every axis rather than left to grow with that history. All
limits are constants at the top of `bin/omarchy-agent-usage-gemini`:

| Bound | Value | What it protects |
|---|---|---|
| `HISTORY_CUTOFF_DAYS` | 30 | Work scales with a fixed window, not with total history |
| `MAX_DIR_ENTRIES_SCANNED` | 200000 | Global scan-work budget for one traversal |
| `MAX_ENTRIES_PER_DIR` | 4000 | One directory cannot spend the whole global budget |
| `MAX_DIRS_TO_SCAN` / `MAX_PENDING_DIRS` | 300 / 1000 | Directories visited, and pending paths retained |
| `MAX_TRANSCRIPT_FILES` | 100 | Files opened per scan |
| `MAX_FILE_SIZE_BYTES` | 4 MB | Per-file read budget, enforced on the open descriptor |
| `MAX_LINE_BYTES` | 256 KB | One line cannot be buffered without limit |
| `MAX_TAIL_BYTES` | 256 KB | `history.jsonl` is read as a seeked tail, never whole |
| `MAX_SESSIONS_RECORDED` / `MAX_MODELS_RECORDED` | 500 / 15 | Bounds the in-memory maps and the emitted JSON |

Directory traversal is a priority walk ordered by mtime (newest directories
first), so the budget is spent on recently active sessions before anything else:
what a truncated walk drops is the least recently touched material, which the
30-day cutoff would discard anyway.

File size is checked with `os.fstat()` on the descriptor being read, not with
`stat()` on the path, so a file swapped or grown between check and read cannot
escape the cap; opens use `O_NOFOLLOW`. Reads are chunked, so a file containing
no newlines is not pulled into memory as one enormous line.

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
sudo ./uninstall.sh
```

---

## 📄 License

MIT © [Chispes](https://github.com/Chispes)
