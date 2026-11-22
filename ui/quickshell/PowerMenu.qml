import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

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

    function show() {
        window.screen = ScreenHelper.focusedScreen()
        fsm.dispatch({ type: "open" })
        shown = true
    }

    function hide() {
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
                anchors.centerIn: parent
                width: 240
                height: column.height + 16
                color: Theme.bg
                radius: 8
                border { color: Theme.muted; width: 1 }
                focus: true

                Keys.onEscapePressed: fsm.dispatch({ type: "back" })
                Keys.onUpPressed: fsm.dispatch({ type: "nav:up" })
                Keys.onDownPressed: fsm.dispatch({ type: "nav:down" })
                Keys.onLeftPressed: fsm.dispatch({ type: "nav:left" })
                Keys.onRightPressed: fsm.dispatch({ type: "nav:right" })
                Keys.onReturnPressed: fsm.dispatch({ type: "select" })

                Column {
                    id: column
                    anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
                    spacing: 4

                    // ------------------------------------------------------------
                    // Menu items
                    // ------------------------------------------------------------

                    Repeater {
                        model: [
                            { label: "Reboot", action: "reboot" },
                            { label: "Shut Down", action: "shutdown" }
                        ]

                        Item {
                            width: column.width
                            height: (fsm.mode === "menu" && !powerProcess.running) ? 40 : 0
                            visible: fsm.mode === "menu" && !powerProcess.running

                            Rectangle {
                                anchors.fill: parent
                                color: fsm.idx === index ? Theme.selected : "transparent"
                                radius: 6
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: Theme.fg
                                font.pixelSize: 15
                            }
                        }
                    }

                    // ------------------------------------------------------------
                    // Confirmation
                    // ------------------------------------------------------------

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.error
                        font.pixelSize: 14
                        text: fsm.action === "reboot" ? "Reboot?" : "Shut down?"
                        visible: fsm.mode === "reboot" || fsm.mode === "shutdown"
                        height: (fsm.mode === "reboot" || fsm.mode === "shutdown") ? 36 : 0
                        verticalAlignment: Text.AlignVCenter
                    }

                    Row {
                        width: parent.width
                        height: (fsm.mode === "reboot" || fsm.mode === "shutdown") ? 40 : 0
                        visible: fsm.mode === "reboot" || fsm.mode === "shutdown"
                        spacing: 4

                        Rectangle {
                            width: (parent.width - 4) / 2
                            height: 40
                            color: fsm.idx === 0 ? (mouseYes.containsMouse ? "#3a2b36" : Theme.selected) : Theme.surface
                            radius: 6

                            Text {
                                anchors.centerIn: parent
                                text: "Yes"
                                color: Theme.error
                                font.pixelSize: 14
                            }

                            MouseArea {
                                id: mouseYes
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: fsm.dispatch({ type: "select" })
                            }
                        }

                        Rectangle {
                            width: (parent.width - 4) / 2
                            height: 40
                            color: fsm.idx === 1 ? (mouseNo.containsMouse ? "#3a2b36" : Theme.selected) : Theme.surface
                            radius: 6

                            Text {
                                anchors.centerIn: parent
                                text: "No"
                                color: Theme.muted
                                font.pixelSize: 14
                            }

                            MouseArea {
                                id: mouseNo
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: fsm.dispatch({ type: "back" })
                            }
                        }
                    }

                    // ------------------------------------------------------------
                    // Running
                    // ------------------------------------------------------------

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.muted
                        font.pixelSize: 14
                        text: "Executing..."
                        visible: fsm.mode === "running"
                        height: fsm.mode === "running" ? 36 : 0
                        verticalAlignment: Text.AlignVCenter
                    }

                    // ------------------------------------------------------------
                    // Error
                    // ------------------------------------------------------------

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.error
                        font.pixelSize: 14
                        text: (fsm.action || "") + " failed (exit " + (fsm.exitCode || "?") + ")"
                        visible: fsm.mode === "error"
                        height: fsm.mode === "error" ? 30 : 0
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.muted
                        font.pixelSize: 12
                        text: fsm.stderr || ""
                        visible: fsm.mode === "error" && (fsm.stderr || "").length > 0
                        height: fsm.mode === "error" && (fsm.stderr || "").length > 0 ? 20 : 0
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: fsm.dispatch({ type: "dismiss" })
            }
        }
    }

    // ------------------------------------------------------------
    // Process execution
    // ------------------------------------------------------------

    Process {
        id: powerProcess
        command: ["true"]

        onExited: (exitCode, exitStatus) => {
            var event = { type: "process:exited", exitCode: exitCode, stderr: "" }
            if (powerProcess.stderr) {
                var collector = powerProcess.stderr
                if (collector.text) event.stderr = collector.text.trim()
            }
            fsm.dispatch(event)
        }

        stderr: StdioCollector {}
    }
}