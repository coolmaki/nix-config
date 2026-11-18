import Quickshell
import QtQuick

Variants {
  model: Quickshell.screens

  PanelWindow {
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true }
    implicitHeight: 30
    color: "#1a1b26"

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Text {
      anchors.centerIn: parent
      color: "#c0caf5"
      text: Qt.formatDateTime(clock.date, "ddd d MMM HH:mm")
    }
  }
}
