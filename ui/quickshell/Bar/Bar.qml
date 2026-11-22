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
    margins { left: 16; right: 16 }
    implicitHeight: 40
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        bottomLeftRadius: 8
        bottomRightRadius: 8
        color: Theme.bg
    }

    // ------------------------------------------------------------
    // Left — workspaces
    // ------------------------------------------------------------

    Row {
        id: workspaceRow
        anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
        spacing: 16

        Repeater {
            model: ListModel { id: workspaceModel }

            Text {
                required property int wsId
                required property string wsName
                required property bool wsActive

                text: wsActive ? "\uebb4" : "\ueb8a"
                color: wsActive ? Theme.accent.content : Theme.secondary
                font.pixelSize: 16
            }
        }
    }

    function rebuildWorkspaces(): void {
        workspaceModel.clear()
        var mon = Hyprland.focusedMonitor
        if (!mon) return

        var list = []
        for (var i = 0; i < Hyprland.workspaces.values.length; i++) {
            var ws = Hyprland.workspaces.values[i]
            if (ws.monitor === mon) {
                list.push({id: ws.id, name: ws.name || String(ws.id)})
            }
        }
        list.sort(function(a, b) { return a.id - b.id })

        var activeId = mon.activeWorkspace ? mon.activeWorkspace.id : -1
        for (var j = 0; j < list.length; j++) {
            workspaceModel.append({
                wsId: list[j].id,
                wsName: list[j].name,
                wsActive: list[j].id === activeId
            })
        }
    }

    function updateActiveWorkspace(): void {
        var mon = Hyprland.focusedMonitor
        if (!mon) return
        var activeId = mon.activeWorkspace ? mon.activeWorkspace.id : -1
        for (var j = 0; j < workspaceModel.count; j++) {
            var item = workspaceModel.get(j)
            workspaceModel.set(j, {
                wsId: item.wsId,
                wsName: item.wsName,
                wsActive: item.wsId === activeId
            })
        }
    }

    Component.onCompleted: rebuildWorkspaces()

    Connections {
        target: Hyprland
        function onFocusedMonitorChanged() { rebuildWorkspaces() }
    }

    Connections {
        target: Hyprland.focusedMonitor
        function onActiveWorkspaceChanged() { updateActiveWorkspace() }
    }

    // Right — status + clock

    Text {
        id: networkIndicator
        anchors { right: batteryIndicator.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
        color: Theme.secondary
        font.pixelSize: 16
        text: "\uf1eb"
        visible: isNetworkConnected
    }

    Text {
        id: batteryIndicator
        anchors { right: timeIndicator.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
        color: batteryColor
        font.pixelSize: 20
        text: batteryIcon
    }

    Text {
        id: timeIndicator
        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
        color: Theme.primary
        font.pixelSize: 16
        text: Qt.formatDateTime(clock.date, "HH:mm")
    }

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