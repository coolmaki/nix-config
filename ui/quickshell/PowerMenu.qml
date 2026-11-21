import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    property bool shown: false
    property int selectedIndex: 0
    property string mode: ""  // "" = menu, "reboot" = confirm, "shutdown" = confirm, "running" = executing

    IpcHandler {
        target: "power"
        function toggle(): void { shown ? hide() : show() }
        function open(): void { show() }
        function close(): void { hide() }
    }

    function show() {
        window.screen = ScreenHelper.focusedScreen()
        selectedIndex = 0
        mode = ""
        shown = true
    }

    function hide() {
        shown = false
    }

    function selectAction() {
        if (mode === "") {
            if (selectedIndex === 0) mode = "reboot"
            else if (selectedIndex === 1) mode = "shutdown"
            selectedIndex = 0
        } else if (mode !== "running") {
            if (selectedIndex === 0) execute()
            else back()
        }
    }

    function execute() {
        var cmd = mode === "reboot" ? ["systemctl", "reboot"] : ["systemctl", "poweroff"]
        mode = "running"
        powerProcess.command = cmd
        powerProcess.running = true
    }

    function back() {
        if (mode !== "" && mode !== "running") {
            mode = ""
            selectedIndex = 0
        } else {
            hide()
        }
    }

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

                Keys.onEscapePressed: root.back()
                Keys.onUpPressed: { if (mode === "") root.selectedIndex = Math.max(0, root.selectedIndex - 1) }
                Keys.onDownPressed: { if (mode === "") root.selectedIndex = Math.min(1, root.selectedIndex + 1) }
                Keys.onLeftPressed: { if (mode !== "" && mode !== "running") root.selectedIndex = Math.max(0, root.selectedIndex - 1) }
                Keys.onRightPressed: { if (mode !== "" && mode !== "running") root.selectedIndex = Math.min(1, root.selectedIndex + 1) }
                Keys.onReturnPressed: root.selectAction()

                Column {
                    id: column
                    anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
                    spacing: 4

                    // ── Menu ─────────────────────────

                    Item {
                        width: parent.width
                        height: (mode === "" && !powerProcess.running) ? 40 : 0
                        visible: mode === "" && !powerProcess.running

                        Rectangle {
                            anchors.fill: parent
                            color: root.selectedIndex === 0 ? Theme.selected : "transparent"
                            radius: 6
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "Reboot"
                            color: Theme.fg
                            font.pixelSize: 15
                        }
                    }

                    Item {
                        width: parent.width
                        height: (mode === "" && !powerProcess.running) ? 40 : 0
                        visible: mode === "" && !powerProcess.running

                        Rectangle {
                            anchors.fill: parent
                            color: root.selectedIndex === 1 ? Theme.selected : "transparent"
                            radius: 6
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "Shut Down"
                            color: Theme.fg
                            font.pixelSize: 15
                        }
                    }

                    // ── Confirmation ──────────────────

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.error
                        font.pixelSize: 14
                        text: mode === "reboot" ? "Reboot?" : "Shut down?"
                        visible: mode === "reboot" || mode === "shutdown"
                        height: (mode === "reboot" || mode === "shutdown") ? 36 : 0
                        verticalAlignment: Text.AlignVCenter
                    }

                    Row {
                        width: parent.width
                        height: (mode === "reboot" || mode === "shutdown") ? 40 : 0
                        visible: mode === "reboot" || mode === "shutdown"
                        spacing: 4

                        Rectangle {
                            width: (parent.width - 4) / 2
                            height: 40
                            color: root.selectedIndex === 0 ? (mouseYes.containsMouse ? "#3a2b36" : Theme.selected) : Theme.surface
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
                                onClicked: root.execute()
                            }
                        }

                        Rectangle {
                            width: (parent.width - 4) / 2
                            height: 40
                            color: root.selectedIndex === 1 ? (mouseNo.containsMouse ? "#3a2b36" : Theme.selected) : Theme.surface
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
                                onClicked: root.back()
                            }
                        }
                    }

                    // ── Running ────────────────────────

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.muted
                        font.pixelSize: 14
                        text: "Executing..."
                        visible: mode === "running"
                        height: mode === "running" ? 36 : 0
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: root.hide()
            }
        }
    }

    Process {
        id: powerProcess
        command: ["true"]

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.mode = "error"
            }
        }
    }
}