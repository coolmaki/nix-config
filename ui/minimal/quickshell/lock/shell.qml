import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick

Scope {
    id: root

    property string state: "ready"
    property string pendingPassword: ""
    property string password: ""
    property int attempts: 0
    property int dotCount: 0
    property bool authError: false

    readonly property color bg: "#1a1b26"
    readonly property color fg: "#c0caf5"
    readonly property color muted: "#565f89"
    readonly property color error: "#f7768e"
    readonly property color warn: "#e0af68"

    readonly property int retryDelayMs: {
        if (attempts < 5) return 1000
        return Math.min(30000, Math.pow(2, attempts - 4) * 1000)
    }

    WlSessionLock {
        id: lock

        WlSessionLockSurface {
            Rectangle {
                anchors.fill: parent
                color: root.bg
                focus: true

                SystemClock { id: clock; precision: SystemClock.Minutes }

                Text {
                    id: clockText
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 80 }
                    color: root.fg
                    font.pixelSize: 48
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                }

                Text {
                    anchors { horizontalCenter: parent.horizontalCenter; top: clockText.bottom; topMargin: 4 }
                    color: root.muted
                    font.pixelSize: 18
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                }

                Text {
                    id: passwordDisplay
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.verticalCenter
                        topMargin: -30
                    }
                    color: root.state === "backoff" || root.state === "unavailable" ? root.error : root.fg
                    font.pixelSize: 24
                    text: "●".repeat(Array.from(root.password).length)
                }

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
                        if (root.state === "backoff") return root.error
                        if (root.state === "unavailable") return root.error
                        if (root.state === "checking") return root.warn
                        return root.muted
                    }
                }

                Text {
                    id: statusText
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: inputLine.bottom
                        topMargin: 10
                    }
                    color: root.state === "backoff" || root.state === "unavailable" ? root.error : root.muted
                    font.pixelSize: 13
                    text: {
                        if (root.state === "unavailable") return "Authentication unavailable"
                        if (root.state === "backoff") {
                            if (root.authError) return "Authentication error"
                            var msg = "Wrong password (" + root.attempts + " attempt" + (root.attempts > 1 ? "s" : "") + ")"
                            if (root.attempts >= 5)
                                msg += " — wait " + (root.retryDelayMs / 1000) + "s"
                            return msg
                        }
                        if (root.state === "checking")
                            return "Checking" + ".".repeat(root.dotCount)
                        return ""
                    }
                }

                Keys.onPressed: (event) => {
                    if (event.modifiers & (Qt.ControlModifier | Qt.MetaModifier))
                        return

                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if ((root.state === "ready" || root.state === "unavailable") && root.password.length > 0) {
                            root.pendingPassword = root.password
                            root.password = ""
                            root.state = "checking"
                            var ok = pam.start()
                            if (!ok) {
                                root.state = "unavailable"
                                root.pendingPassword = ""
                                console.error("PAM start failed — config missing?")
                            }
                        }
                        return
                    }

                    if (event.key === Qt.Key_Backspace) {
                        if (root.password.length > 0) {
                            root.password = Array.from(root.password).slice(0, -1).join("")
                        }
                        return
                    }

                    if (/[\u0000-\u001f\u007f]/.test(event.text))
                        return

                    if (event.text.length > 0 && (root.state === "ready" || root.state === "backoff" || root.state === "checking" || root.state === "unavailable")) {
                        root.password += event.text
                    }
                }
            }
        }

        Component.onCompleted: locked = true

        onLockedChanged: {
            if (!locked) Qt.quit()
        }
    }

    Timer {
        id: retryTimer
        interval: root.retryDelayMs
        onTriggered: {
            root.state = "ready"
        }
    }

    Timer {
        id: dotTimer
        interval: 400
        running: root.state === "checking"
        repeat: true
        onTriggered: root.dotCount = (root.dotCount + 1) % 4
    }

    PamContext {
        id: pam
        config: "qslock"

        onPamMessage: {
            if (pam.responseRequired && root.pendingPassword.length > 0) {
                pam.respond(root.pendingPassword)
                root.pendingPassword = ""
            }
        }

        onCompleted: (result) => {
            root.pendingPassword = ""
            if (result === PamResult.Success) {
                lock.locked = false
                Qt.quit()
            } else if (result === PamResult.Failed) {
                root.authError = false
                root.attempts++
                root.state = "backoff"
                retryTimer.start()
            } else {
                root.authError = true
                root.state = "backoff"
                retryTimer.start()
            }
        }

        onError: (error) => {
            console.error("PAM error:", PamError.toString(error))
        }
    }
}