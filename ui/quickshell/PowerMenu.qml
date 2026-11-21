import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    property bool shown: false

    property var machine: ({
        mode: "menu", index: 0, action: "", exitCode: 0, stderr: ""
    })

    PowerMachine { id: pm }

    IpcHandler {
        target: "power"
        function toggle(): void { shown ? hide() : show() }
        function open(): void { show() }
        function close(): void { hide() }
    }

    function apply(effects) {
        root.machine = Object.assign({}, root.machine)
        if (effects) {
            for (var i = 0; i < effects.length; i++) {
                var e = effects[i]
                if (e.type === "exec") {
                    powerProcess.command = e.command
                    powerProcess.running = true
                } else if (e.type === "hide") {
                    hide()
                }
            }
        }
    }

    function show() {
        window.screen = ScreenHelper.focusedScreen()
        effects.length = 0
        pm.dispatch(machine, { type: "open" }, effects)
        apply(effects)
        shown = true
    }

    function hide() {
        shown = false
    }

    property var effects: []

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

                Keys.onEscapePressed: { effects.length = 0; pm.dispatch(root.machine, { type: "back" }, effects); apply(effects) }
                Keys.onUpPressed: { effects.length = 0; pm.dispatch(root.machine, { type: "nav:up" }, effects); apply(effects) }
                Keys.onDownPressed: { effects.length = 0; pm.dispatch(root.machine, { type: "nav:down" }, effects); apply(effects) }
                Keys.onLeftPressed: { effects.length = 0; pm.dispatch(root.machine, { type: "nav:left" }, effects); apply(effects) }
                Keys.onRightPressed: { effects.length = 0; pm.dispatch(root.machine, { type: "nav:right" }, effects); apply(effects) }
                Keys.onReturnPressed: { effects.length = 0; pm.dispatch(root.machine, { type: "select" }, effects); apply(effects) }

                Column {
                    id: column
                    anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
                    spacing: 4

                    Repeater {
                        model: [
                            { label: "Reboot", action: "reboot" },
                            { label: "Shut Down", action: "shutdown" }
                        ]

                        Item {
                            width: column.width
                            height: (root.machine.mode === "menu" && !powerProcess.running) ? 40 : 0
                            visible: root.machine.mode === "menu" && !powerProcess.running

                            Rectangle {
                                anchors.fill: parent
                                color: root.machine.index === index ? Theme.selected : "transparent"
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

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.error
                        font.pixelSize: 14
                        text: root.machine.action === "reboot" ? "Reboot?" : "Shut down?"
                        visible: root.machine.mode === "reboot" || root.machine.mode === "shutdown"
                        height: (root.machine.mode === "reboot" || root.machine.mode === "shutdown") ? 36 : 0
                        verticalAlignment: Text.AlignVCenter
                    }

                    Row {
                        width: parent.width
                        height: (root.machine.mode === "reboot" || root.machine.mode === "shutdown") ? 40 : 0
                        visible: root.machine.mode === "reboot" || root.machine.mode === "shutdown"
                        spacing: 4

                        Rectangle {
                            width: (parent.width - 4) / 2
                            height: 40
                            color: root.machine.index === 0 ? (mouseYes.containsMouse ? "#3a2b36" : Theme.selected) : Theme.surface
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
                                onClicked: { effects.length = 0; pm.dispatch(root.machine, { type: "select" }, effects); apply(effects) }
                            }
                        }

                        Rectangle {
                            width: (parent.width - 4) / 2
                            height: 40
                            color: root.machine.index === 1 ? (mouseNo.containsMouse ? "#3a2b36" : Theme.selected) : Theme.surface
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
                                onClicked: { effects.length = 0; pm.dispatch(root.machine, { type: "back" }, effects); apply(effects) }
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.muted
                        font.pixelSize: 14
                        text: "Executing..."
                        visible: root.machine.mode === "running"
                        height: root.machine.mode === "running" ? 36 : 0
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.error
                        font.pixelSize: 14
                        text: (root.machine.action || "") + " failed (exit " + (root.machine.exitCode || "?") + ")"
                        visible: root.machine.mode === "error"
                        height: root.machine.mode === "error" ? 30 : 0
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.muted
                        font.pixelSize: 12
                        text: root.machine.stderr || ""
                        visible: root.machine.mode === "error" && (root.machine.stderr || "").length > 0
                        height: root.machine.mode === "error" && (root.machine.stderr || "").length > 0 ? 20 : 0
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: { effects.length = 0; pm.dispatch(root.machine, { type: "dismiss" }, effects); apply(effects) }
            }
        }
    }

    Process {
        id: powerProcess
        command: ["true"]

        onExited: (exitCode, exitStatus) => {
            var event = { type: "process:exited", exitCode: exitCode, stderr: "" }
            if (powerProcess.stderr) {
                var collector = powerProcess.stderr
                if (collector.text) event.stderr = collector.text.trim()
            }
            effects.length = 0
            pm.dispatch(root.machine, event, effects)
            apply(effects)
        }

        stderr: StdioCollector {}
    }
}