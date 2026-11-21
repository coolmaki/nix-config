import Quickshell
import QtQuick

FloatingWindow {
    id: dialog
    title: "Power"
    implicitWidth: 280
    implicitHeight: actionColumn.height + 16
    color: "#1a1b26"
    visible: true

    property string mode: ""  // "" = menu, "reboot" = confirm, "shutdown" = confirm

    Column {
        id: actionColumn
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
        spacing: 4

        // ── Menu mode ──────────────────────────────────

        Item {
            width: parent.width
            height: mode === "" ? 40 : 0
            visible: mode === ""

            Rectangle {
                anchors.fill: parent
                color: mouseLogout.containsMouse ? "#2a2b36" : "transparent"
                radius: 6
            }

            Text {
                anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                text: "Log Out"
                color: "#c0caf5"
                font.pixelSize: 15
            }

            MouseArea {
                id: mouseLogout
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    Quickshell.execDetached({ command: ["hyprctl", "dispatch", "exit"] })
                    Qt.quit()
                }
            }
        }

        Item {
            width: parent.width
            height: mode === "" ? 40 : 0
            visible: mode === ""

            Rectangle {
                anchors.fill: parent
                color: mouseReboot.containsMouse ? "#2a2b36" : "transparent"
                radius: 6
            }

            Text {
                anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                text: "Reboot"
                color: "#c0caf5"
                font.pixelSize: 15
            }

            MouseArea {
                id: mouseReboot
                anchors.fill: parent
                hoverEnabled: true
                onClicked: mode = "reboot"
            }
        }

        Item {
            width: parent.width
            height: mode === "" ? 40 : 0
            visible: mode === ""

            Rectangle {
                anchors.fill: parent
                color: mouseShutdown.containsMouse ? "#2a2b36" : "transparent"
                radius: 6
            }

            Text {
                anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                text: "Shut Down"
                color: "#c0caf5"
                font.pixelSize: 15
            }

            MouseArea {
                id: mouseShutdown
                anchors.fill: parent
                hoverEnabled: true
                onClicked: mode = "shutdown"
            }
        }

        // ── Confirmation mode ──────────────────────────

        Item {
            width: parent.width
            height: mode !== "" ? 40 : 0
            visible: mode !== ""

            Text {
                anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                text: mode === "reboot" ? "Reboot?" : "Shut down?"
                color: "#f7768e"
                font.pixelSize: 15
            }
        }

        Row {
            width: parent.width
            height: mode !== "" ? 40 : 0
            visible: mode !== ""
            spacing: 4

            Item {
                width: (parent.width - 4) / 2
                height: 40

                Rectangle {
                    anchors.fill: parent
                    color: mouseYes.containsMouse ? "#3a2b36" : "#2a2b36"
                    radius: 6
                }

                Text {
                    anchors.centerIn: parent
                    text: "Yes"
                    color: "#f7768e"
                    font.pixelSize: 14
                }

                MouseArea {
                    id: mouseYes
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (mode === "reboot") {
                            Quickshell.execDetached({ command: ["systemctl", "reboot"] })
                        } else {
                            Quickshell.execDetached({ command: ["systemctl", "poweroff"] })
                        }
                        Qt.quit()
                    }
                }
            }

            Item {
                width: (parent.width - 4) / 2
                height: 40

                Rectangle {
                    anchors.fill: parent
                    color: mouseNo.containsMouse ? "#2a2b36" : "#222330"
                    radius: 6
                }

                Text {
                    anchors.centerIn: parent
                    text: "No"
                    color: "#565f89"
                    font.pixelSize: 14
                }

                MouseArea {
                    id: mouseNo
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: mode = ""
                }
            }
        }
    }

    // Keyboard: Esc to go back/close, Enter to logout from menu
    Keys.onEscapePressed: {
        if (mode !== "") {
            mode = ""
        } else {
            Qt.quit()
        }
    }
    Keys.onReturnPressed: {
        if (mode === "") {
            Quickshell.execDetached({ command: ["hyprctl", "dispatch", "exit"] })
            Qt.quit()
        }
    }
}