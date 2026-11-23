import Quickshell
import Quickshell.Hyprland
import QtQuick
import ".."

Row {
    id: workspaceRow
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