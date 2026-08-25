import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root
  visible: false

  // Ensures Gemini usage data is periodically collected and kept fresh
  Timer {
    interval: 900000 // 15 minutes
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!collectorProcess.running) {
        collectorProcess.running = true
      }
    }
  }

  Process {
    id: collectorProcess
    running: false
    command: ["omarchy-agent-usage-update", "gemini"]
  }
}
