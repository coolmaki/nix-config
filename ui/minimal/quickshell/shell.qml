import Quickshell
import QtQuick

Variants {
  model: Quickshell.screens

  PanelWindow {
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true }
    margins { left: 16; right: 16 }
    implicitHeight: 24
    color: "transparent"

    Rectangle {
      anchors.fill: parent
      bottomLeftRadius: 8
      bottomRightRadius: 8
      color: "#aa595959"

      Rectangle {
        anchors.fill: parent
	anchors.leftMargin: 1
	anchors.rightMargin: 1
	anchors.bottomMargin: 1
        bottomLeftRadius: 8
        bottomRightRadius: 8
        color: "#1a1b26"
      }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Text {
      anchors.centerIn: parent
      color: "#c0caf5"
      text: Qt.formatDateTime(clock.date, "ddd d MMM HH:mm")
    }
  }
}
