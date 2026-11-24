import Quickshell
import QtQuick
import ".."

Rectangle {
    enum Type {
        Back,
        Reboot,
        Shutdown
    }

    id: tile
    implicitWidth: 64
    implicitHeight: 64
    color: "transparent"
    visible: show

    required property int type
    required property PowerMenuStateMachine state

    readonly property bool show: {
        if (type === PowerMenuTile.Back && (state.mode === PowerMenuStateMachine.Reboot || state.mode === PowerMenuStateMachine.Shutdown)) {
            return true
        } 

        if (type === PowerMenuTile.Reboot && (state.mode === PowerMenuStateMachine.Menu || state.mode === PowerMenuStateMachine.Reboot)) {
            return true
        } 

        if (type === PowerMenuTile.Shutdown && (state.mode === PowerMenuStateMachine.Menu || state.mode === PowerMenuStateMachine.Shutdown)) {
            return true
        } 

        return false
    }

    readonly property string tileIcon: {
        switch (type) {
            case PowerMenuTile.Back: return "\uf060";
            case PowerMenuTile.Reboot: return "\u23fc";
            case PowerMenuTile.Shutdown: return "\u23fb";
            default: "\uf128";
        }
    }

    readonly property string tileColor: {
        if (type === PowerMenuTile.Reboot && state.selected === PowerMenuTile.Reboot) {
            return Theme.warn.content
        }

        if (type === PowerMenuTile.Shutdown && state.selected === PowerMenuTile.Shutdown) {
            return Theme.error.content
        }

        return Theme.secondary;
    }

    Text {
        anchors.centerIn: tile
        text: tile.tileIcon
        color: tile.tileColor
        font.pixelSize: 20

        Behavior on color {
            ColorAnimation { duration: 500; easing.type: Easing.InOutCubic }
        }
    }
}
