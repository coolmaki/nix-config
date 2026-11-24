import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import ".."

Scope {
    id: root
    property bool shown: false

    // ------------------------------------------------------------
    // State machine
    // ------------------------------------------------------------

    PowerMenuStateMachine {
        id: fsm

        onExecRequested: (command) => {
            powerProcess.command = command
            powerProcess.running = true
        }
        onHideRequested: hide()
    }

    readonly property bool isLeftSelected: (fsm.mode === PowerMenuStateMachine.Menu && fsm.selected === PowerMenuTile.Shutdown) ||
        (fsm.mode === PowerMenuTile.Reboot && fsm.selected === PowerMenuTile.Back) ||
        (fsm.mode === PowerMenuTile.Shutdown && fsm.selected === PowerMenuTile.Shutdown)

    readonly property int selectionMargin: isLeftSelected ? 8 : 8 + 64

    // ------------------------------------------------------------
    // Event object (reused)
    // ------------------------------------------------------------

    PowerMenuEvent {
        id: pev
        type: PowerMenuEvent.Open
    }

    // ------------------------------------------------------------
    // IPC
    // ------------------------------------------------------------

    IpcHandler {
        target: "power"
        function toggle(): void { shown ? hide() : show() }
        function open(): void { show() }
        function close(): void { hide() }
    }

    // ------------------------------------------------------------
    // Show / hide
    // ------------------------------------------------------------

    function show(): void {
        window.screen = ScreenHelper.focusedScreen()
        pev.type = PowerMenuEvent.Open
        fsm.dispatch(pev)
        shown = true
    }

    function hide(): void {
        shown = false
    }

    // ------------------------------------------------------------
    // Window
    // ------------------------------------------------------------

    PanelWindow {
        id: window
        anchors { top: true; left: true; right: true; bottom: true }
        color: "transparent"
        visible: root.shown
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            Rectangle {
                id: card
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 32 }
                width: 128 + 16
                height: 80
                color: Theme.bg
                radius: 40
                focus: true

                Rectangle {
                    implicitWidth: 64
                    implicitHeight: 64
                    radius: 32
                    color: Theme.selected
                    anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: root.selectionMargin }

                    Behavior on anchors.leftMargin {
                        NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
                    }
                }

                Row {
                    anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: 8 }

                    PowerMenuTile { type: fsm.mode === PowerMenuStateMachine.Reboot ? PowerMenuTile.Back : PowerMenuTile.Shutdown; state: fsm }
                    PowerMenuTile { type: fsm.mode === PowerMenuStateMachine.Shutdown ? PowerMenuTile.Back : PowerMenuTile.Reboot; state: fsm }
                }

                Keys.onEscapePressed: {
                    pev.type = PowerMenuEvent.Dismiss
                    fsm.dispatch(pev)
                }
                Keys.onLeftPressed: {
                    pev.type = PowerMenuEvent.NavLeft
                    fsm.dispatch(pev)
                }
                Keys.onRightPressed: {
                    pev.type = PowerMenuEvent.NavRight
                    fsm.dispatch(pev)
                }
                Keys.onReturnPressed: {
                    pev.type = PowerMenuEvent.Select
                    fsm.dispatch(pev)
                    console.log("mode: " + fsm.mode)
                    console.log("selected: " + fsm.selected)
                }
            }

            Shadow { element: card }
        }
    }

    // ------------------------------------------------------------
    // Process execution
    // ------------------------------------------------------------

    Process {
        id: powerProcess
        command: ["true"]

        onExited: (exitCode, exitStatus) => {
            pev.type = PowerMenuEvent.ProcessExited
            pev.exitCode = exitCode
            pev.stderr = ""
            if (powerProcess.stderr) {
                var collector = powerProcess.stderr
                if (collector.text) pev.stderr = collector.text.trim()
            }
            fsm.dispatch(pev)
        }

        stderr: StdioCollector {}
    }
}
