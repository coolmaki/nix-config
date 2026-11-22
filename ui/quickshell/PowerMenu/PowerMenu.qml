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

    // ------------------------------------------------------------
    // Event object (reused)
    // ------------------------------------------------------------

    PowerMenuEvent {
        id: pev
        type: PowerMenuEvent.Type.Open
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
        PowerMenuEvent.Type.Open
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
                anchors.centerIn: parent
                width: 240
                height: column.height + 16
                color: Theme.bg
                radius: 8
                focus: true

                Keys.onEscapePressed: {
                    pev.type = PowerMenuEvent.Type.Back
                    fsm.dispatch(pev)
                }
                Keys.onUpPressed: {
                    pev.type = PowerMenuEvent.Type.NavUp
                    fsm.dispatch(pev)
                }
                Keys.onDownPressed: {
                    pev.type = PowerMenuEvent.Type.NavDown
                    fsm.dispatch(pev)
                }
                Keys.onLeftPressed: {
                    pev.type = PowerMenuEvent.Type.NavLeft
                    fsm.dispatch(pev)
                }
                Keys.onRightPressed: {
                    pev.type = PowerMenuEvent.Type.NavRight
                    fsm.dispatch(pev)
                }
                Keys.onReturnPressed: {
                    pev.type = PowerMenuEvent.Type.Select
                    fsm.dispatch(pev)
                }

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
                            height: (fsm.mode === fsm.menu && !powerProcess.running) ? 40 : 0
                            visible: fsm.mode === fsm.menu && !powerProcess.running

                            Rectangle {
                                anchors.fill: parent
                                color: fsm.idx === index ? Theme.selected : "transparent"
                                radius: 6
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: Theme.primary
                                font.pixelSize: 15
                            }
                        }
                    }

                    // ------------------------------------------------------------
                    // Confirmation
                    // ------------------------------------------------------------

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.error.content
                        font.pixelSize: 14
                        text: fsm.action === "reboot" ? "Reboot?" : "Shut down?"
                        visible: fsm.mode === fsm.reboot || fsm.mode === fsm.shutdown
                        height: (fsm.mode === fsm.reboot || fsm.mode === fsm.shutdown) ? 36 : 0
                        verticalAlignment: Text.AlignVCenter
                    }

                    Row {
                        width: parent.width
                        height: (fsm.mode === fsm.reboot || fsm.mode === fsm.shutdown) ? 40 : 0
                        visible: fsm.mode === fsm.reboot || fsm.mode === fsm.shutdown
                        spacing: 4

                        Rectangle {
                            width: (parent.width - 4) / 2
                            height: 40
                            color: fsm.idx === 0 ? (mouseYes.containsMouse ? "#3a2b36" : Theme.selected) : Theme.neutral
                            radius: 6

                            Text {
                                anchors.centerIn: parent
                                text: "Yes"
                                color: Theme.error.content
                                font.pixelSize: 14
                            }

                            MouseArea {
                                id: mouseYes
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    pev.type = PowerMenuEvent.Type.Select
                                    fsm.dispatch(pev)
                                }
                            }
                        }

                        Rectangle {
                            width: (parent.width - 4) / 2
                            height: 40
                            color: fsm.idx === 1 ? (mouseNo.containsMouse ? "#3a2b36" : Theme.selected) : Theme.neutral
                            radius: 6

                            Text {
                                anchors.centerIn: parent
                                text: "No"
                                color: Theme.secondary
                                font.pixelSize: 14
                            }

                            MouseArea {
                                id: mouseNo
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    pev.type = PowerMenuEvent.Type.Back
                                    fsm.dispatch(pev)
                                }
                            }
                        }
                    }

                    // ------------------------------------------------------------
                    // Running
                    // ------------------------------------------------------------

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.secondary
                        font.pixelSize: 14
                        text: "Executing..."
                        visible: fsm.mode === fsm.running
                        height: fsm.mode === fsm.running ? 36 : 0
                        verticalAlignment: Text.AlignVCenter
                    }

                    // ------------------------------------------------------------
                    // Error
                    // ------------------------------------------------------------

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.error.content
                        font.pixelSize: 14
                        text: (fsm.action || "") + " failed (exit " + (fsm.exitCode || "?") + ")"
                        visible: fsm.mode === fsm.error
                        height: fsm.mode === fsm.error ? 30 : 0
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.secondary
                        font.pixelSize: 12
                        text: fsm.stderr || ""
                        visible: fsm.mode === fsm.error && (fsm.stderr || "").length > 0
                        height: fsm.mode === fsm.error && (fsm.stderr || "").length > 0 ? 20 : 0
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: {
                    pev.type = PowerMenuEvent.Type.Dismiss
                    fsm.dispatch(pev)
                }
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
            pev.type = PowerMenuEvent.Type.ProcessExited
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