import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import ".."

PanelWindow {
    id: root
    screen: ScreenHelper.focusedScreen()
    anchors { top: true; left: true; right: false; bottom: false }
    implicitWidth: 12
    implicitHeight: 12
    color: "transparent"
    visible: {
        var win = Hyprland.activeToplevel
        if (!win) return false
        return win.monitor?.focused === true &&
            win.workspace.focused === true
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Connections {
        target: Hyprland
        function onActiveToplevelChanged() { Hyprland.refreshToplevels() }
    }

    margins {
        top: indicatorTop()
        left: indicatorLeft()
    }

    Rectangle {
        implicitWidth: 12
        implicitHeight: 12
        radius: 6
        color: Theme.accent.content
    }

    function indicatorTop(): real {
        var win = Hyprland.activeToplevel
        var mon = Hyprland.focusedMonitor
        if (!win || !mon) return 0
        var obj = win.lastIpcObject
        if (!obj || !obj.at) return 0
        return obj.at[1] - mon.y - 48
    }

    function indicatorLeft(): real {
        var win = Hyprland.activeToplevel
        var mon = Hyprland.focusedMonitor
        if (!win || !mon) return 0
        var obj = win.lastIpcObject
        if (!obj || !obj.at || !obj.size) return 0
        return obj.at[0] - mon.x + obj.size[0] - 6
    }
}