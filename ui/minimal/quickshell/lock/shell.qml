import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick

Scope {
    id: root

    property bool pamActive: false
    property bool failed: false
    property int attempts: 0
    property string password: ""
    property int escapeCount: 0
    property int dotCount: 0

    WlSessionLock {
        id: lock

        WlSessionLockSurface {
            Rectangle {
                id: lockScreen
                anchors.fill: parent
                color: "#1a1b26"
                focus: true

                SystemClock { id: clock; precision: SystemClock.Minutes }

                Text {
                    id: clockText
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 80 }
                    color: "#c0caf5"
                    font.pixelSize: 48
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                }

                Text {
                    anchors { horizontalCenter: parent.horizontalCenter; top: clockText.bottom; topMargin: 4 }
                    color: "#565f89"
                    font.pixelSize: 18
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                }

                // Password dots
                Text {
                    id: passwordDisplay
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.verticalCenter
                        topMargin: -30
                    }
                    color: root.failed ? "#f7768e" : "#c0caf5"
                    font.pixelSize: 24
                    text: ""
                }

                // Input line
                Rectangle {
                    id: inputLine
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: passwordDisplay.bottom
                        topMargin: 8
                    }
                    width: 280
                    height: 2
                    color: {
                        if (root.failed) return "#f7768e"
                        if (!root.pamActive) return "#e0af68"
                        return "#565f89"
                    }
                }

                // Status text
                Text {
                    id: statusText
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: inputLine.bottom
                        topMargin: 10
                    }
                    color: root.failed ? "#f7768e" : "#565f89"
                    font.pixelSize: 13
                    text: {
                        if (root.failed) {
                            var msg = "Wrong password"
                            if (root.attempts > 0)
                                msg += " (" + root.attempts + " attempt" + (root.attempts > 1 ? "s" : "") + ")"
                            if (root.attempts >= 5) {
                                var wait = Math.pow(2, root.attempts - 4)
                                msg += " — wait " + wait + "s"
                            }
                            return msg
                        }
                        if (!root.pamActive) {
                            if (retryTimer.running) {
                                var wait = Math.pow(2, root.attempts - 4)
                                return "Too many attempts — wait " + wait + "s"
                            }
                            var dots = ".".repeat(root.dotCount)
                            return "Checking" + dots
                        }
                        return ""
                    }
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        root.escapeCount++
                        if (root.escapeCount >= 3) {
                            lock.locked = false
                            Qt.quit()
                            return
                        }
                        escapeTimer.restart()
                        return
                    }

                    root.escapeCount = 0

                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (root.pamActive && pam.responseRequired && root.password.length > 0) {
                            root.pamActive = false
                            pam.respond(root.password)
                            root.password = ""
                            passwordDisplay.text = ""
                        }
                        return
                    }

                    if (event.key === Qt.Key_Backspace) {
                        if (root.password.length > 0) {
                            root.password = root.password.slice(0, -1)
                            passwordDisplay.text = "●".repeat(root.password.length)
                        }
                        return
                    }

                    if (event.text.length === 1 && root.pamActive) {
                        root.password += event.text
                        passwordDisplay.text = "●".repeat(root.password.length)
                    }
                }

                Timer {
                    id: escapeTimer
                    interval: 1000
                    onTriggered: root.escapeCount = 0
                }
            }
        }

        Component.onCompleted: locked = true

        onSecureChanged: {
            if (secure && !root.pamActive) {
                root.pamActive = true
                pamStartTimer.start()
            }
        }
    }

    Timer {
        id: pamStartTimer
        interval: 200
        onTriggered: pam.start()
    }

    Timer {
        id: retryTimer
        interval: 1000
        onTriggered: {
            root.failed = false
            root.pamActive = true
            pam.start()
        }
    }

    Timer {
        id: dotTimer
        interval: 400
        running: !root.pamActive && !root.failed && !retryTimer.running
        repeat: true
        onTriggered: root.dotCount = (root.dotCount + 1) % 4
    }

    PamContext {
        id: pam
        config: "qslock"

        onCompleted: (result) => {
            if (result === PamResult.Success) {
                lock.locked = false
                Qt.quit()
            } else {
                root.failed = true
                root.attempts++
                root.pamActive = false

                var delay = 1000
                if (root.attempts >= 5) {
                    delay = Math.pow(2, root.attempts - 4) * 1000
                }
                retryTimer.interval = delay
                retryTimer.start()
            }
        }
    }
}