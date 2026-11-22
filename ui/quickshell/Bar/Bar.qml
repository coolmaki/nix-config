import Quickshell
import QtQuick
import ".."

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
                color: Theme.bg
            }
        }

        SystemClock { id: clock; precision: SystemClock.Minutes }

        Text {
            anchors.centerIn: parent
            color: Theme.fg
            text: Qt.formatDateTime(clock.date, "ddd d MMM HH:mm")
        }
    }
}