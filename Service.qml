import QtQuick
import Quickshell
import Quickshell.Io

// Keeps the Gemini usage record fresh, and is what makes the plugin work from
// `omarchy plugin add` alone.
//
// The agents panel draws whatever JSON records sit in
// ~/.local/state/omarchy/agents/usage/, "regardless of who wrote it".
// omarchy-agent-usage-update, by contrast, only ever globs
// $OMARCHY_PATH/bin/omarchy-agent-usage-* -- a directory no plugin can write
// to without root. Routing the refresh through it would make adding this
// plugin a half-install that shows nothing until a sudo step is run by hand,
// which is exactly the trap this avoids: the collector ships in the plugin, so
// run it from here and let it write its own record.
//
// install.sh is still worth running, but only for what genuinely needs root:
// the system-wide collector, and the Gemini mark in the panel's own asset dir
// -- the one thing a plugin cannot supply, since Panel.qml resolves a
// provider's icon against its own root-owned directory and looks nowhere else.
// `install.sh --icons-only` installs just the mark.
Item {
  id: root
  visible: false

  // Injected by the shell when it instantiates a service plugin; carries the
  // plugin's absolute source directory in __sourceDir.
  property var manifest: null

  // Resolved against this file rather than assembled from the injected
  // manifest, because the first refresh is triggered on start -- before the
  // shell has had a chance to inject anything. __sourceDir is the fallback for
  // a host that resolves the component from somewhere other than its own file.
  function pluginPath(relative) {
    var url = String(Qt.resolvedUrl(relative))
    if (url.indexOf("file://") === 0) return url.substring(7)
    if (manifest && manifest.__sourceDir)
      return String(manifest.__sourceDir).replace(/\/$/, "") + "/" + relative
    return ""
  }

  readonly property string collector: pluginPath("bin/omarchy-agent-usage-gemini")
  readonly property string iconPrompt: pluginPath("bin/omarchy-agent-gemini-icon-prompt")

  // The icon offer is made once per shell session at most; the script itself
  // decides whether there is anything to offer, and never asks twice.
  property bool iconPromptRun: false

  // Matches the agents panel's own default refresh interval. The collector
  // caches its scan for 20s, so overlapping with a system-wide install costs
  // a process, not a rescan.
  Timer {
    interval: 900000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (root.collector !== "" && !collectorProcess.running) collectorProcess.running = true
    }
  }

  Process {
    id: collectorProcess
    running: false
    // python3 by name rather than the shebang: a clone that lost the exec bit
    // should still collect.
    command: ["python3", root.collector, "--write"]

    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (text.trim() !== "") console.warn("agent-gemini", text.trim())
    }

    // After the collect, not before: the offer is suppressed until there is a
    // record, since the panel draws no tab -- and so shows no wrong icon --
    // for an agent that has nothing to report yet.
    onExited: {
      if (!root.iconPromptRun && root.iconPrompt !== "") {
        root.iconPromptRun = true
        iconPromptProcess.running = true
      }
    }
  }

  // Offers to install the one thing the plugin cannot install for itself: the
  // Gemini mark, which lives in the Agents panel's own root-owned asset dir.
  Process {
    id: iconPromptProcess
    running: false
    command: ["bash", root.iconPrompt]

    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (text.trim() !== "") console.warn("agent-gemini/icon", text.trim())
    }
  }
}
