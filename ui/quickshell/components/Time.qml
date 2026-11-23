import Quickshell
import QtQuick
import ".."

Text {
    id: timeIndicator
    color: Theme.primary
    font.pixelSize: 16
    text: Qt.formatDateTime(clock.date, "HH:mm")

    SystemClock { id: clock; precision: SystemClock.Minutes }
}