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
    readonly property string batteryIcon: UPower.displayDevice.state == UPowerDeviceState.Charging ? batteryChargingIconFor(battery) : batteryIconFor(battery)
    readonly property color batteryColor: batteryColorFor(battery)

    function batteryIconFor(pct: int): string {
        if (pct > 95) return "\udb80\udc79"
        if (pct > 85) return "\udb80\udc82"
        if (pct > 75) return "\udb80\udc81"
        if (pct > 65) return "\udb80\udc80"
        if (pct > 55) return "\udb80\udc7f"
        if (pct > 45) return "\udb80\udc7e"
        if (pct > 35) return "\udb80\udc7d"
        if (pct > 25) return "\udb80\udc7c"
        if (pct > 15) return "\udb80\udc7b"
        if (pct > 5) return "\udb80\udc7a"
        return "\udb80\udc8e"
    }

    function batteryChargingIconFor(pct: int): string {
        if (pct > 95) return "\udb80\udc85"
        if (pct > 85) return "\udb80\udc8b"
        if (pct > 75) return "\udb80\udc8a"
        if (pct > 65) return "\udb82\udc9e"
        if (pct > 55) return "\udb80\udc89"
        if (pct > 45) return "\udb82\udc9d"
        if (pct > 35) return "\udb80\udc88"
        if (pct > 25) return "\udb80\udc87"
        if (pct > 15) return "\udb80\udc86"
        if (pct > 5) return "\udb82\udc9c"
        return "\udb82\udc9f"
    }

    function batteryColorFor(pct: int): color {
        if (pct > 30) return Theme.success.content
        if (pct > 15) return Theme.warn.content
        return Theme.error.content
    }
}
