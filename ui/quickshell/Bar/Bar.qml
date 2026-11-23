import Quickshell
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.UPower
import QtQuick
import ".."

PanelWindow {
    id: root
    screen: ScreenHelper.focusedScreen()
    anchors { top: true; left: true; right: true }
    implicitHeight: 40
    color: "transparent"

    // Only the island is clickable; clicks anywhere else pass through
    // to whatever is behind the bar.
    mask: Region { item: content }

    Rectangle {
        id: content
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
        width: widgetsRow.implicitWidth + 32   // 16px padding on each side
        height: 40
        bottomLeftRadius: 16
        bottomRightRadius: 16
        color: Theme.bg

        Row {
            id: widgetsRow
            anchors.centerIn: parent
            spacing: 16

            // ------------------------------------------------------------
            // Workspaces
            // ------------------------------------------------------------

            Row {
                id: workspaceRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16

                // Always show this many workspaces (1..count), regardless
                // of which currently have windows open.
                readonly property int count: 4

                Repeater {
                    model: workspaceRow.count

                    Rectangle {
                        readonly property int wsId: index + 1

                        // Occupied: a workspace with this id exists on the
                        // focused monitor.
                        readonly property bool occupied: {
                            var mon = Hyprland.focusedMonitor
                            for (var i = 0; i < Hyprland.workspaces.values.length; i++) {
                                var ws = Hyprland.workspaces.values[i]
                                if (ws.id !== wsId) continue
                                if (!mon) return true
                                if (ws.monitor === mon) return true
                            }
                            return false
                        }

                        // Active: this workspace is the one currently focused.
                        readonly property bool active: {
                            var fw = Hyprland.focusedWorkspace
                            return fw !== null && fw.id === wsId
                        }

                        implicitWidth: active ? 40 : 10
                        implicitHeight: 10
                        radius: 5
                        color: active ? Theme.accent.content
                             : occupied ? Theme.secondary
                             : Theme.disabled

                        Behavior on implicitWidth {
                            NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
                        }
                    }
                }
            }

            // ------------------------------------------------------------
            // Networking
            // ------------------------------------------------------------

            Text {
                id: networkIndicator
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.secondary
                font.pixelSize: 16
                text: "\uf1eb"
                visible: isNetworkConnected
            }

            // ------------------------------------------------------------
            // Battery
            // ------------------------------------------------------------

            Text {
                id: batteryIndicator
                anchors.verticalCenter: parent.verticalCenter
                color: batteryColor
                font.pixelSize: 20
                text: batteryIcon
            }

            // ------------------------------------------------------------
            // Time
            // ------------------------------------------------------------

            Text {
                id: timeIndicator
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.primary
                font.pixelSize: 16
                text: Qt.formatDateTime(clock.date, "HH:mm")
            }
        }
    }

    Shadow { element: content }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // ------------------------------------------------------------
    // Network
    // ------------------------------------------------------------

    readonly property bool isNetworkConnected: Networking.connectivity == NetworkConnectivity.Full

    // ------------------------------------------------------------
    // Battery
    // ------------------------------------------------------------

    readonly property real battery: Math.ceil(UPower.displayDevice.percentage * 100)
    readonly property string batteryIcon: batteryIconFor(battery)
    readonly property color batteryColor: batteryColorFor(battery)

    function batteryIconFor(pct: int): string {
        if (pct >= 90) return "\uf240"
        if (pct >= 60) return "\uf241"
        if (pct >= 30) return "\uf242"
        if (pct >= 10) return "\uf243"
        return "\uf244"
    }

    function batteryColorFor(pct: int): color {
        if (pct >= 60) return Theme.success.content
        if (pct >= 30) return Theme.warn.content
        return Theme.error.content
    }
}
