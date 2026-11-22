import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick

Scope {

    // ------------------------------------------------------------
    // State machine
    // ------------------------------------------------------------

    LockScreenStateMachine {
        id: fsm

        onSubmitRequested: {
            var ok = pam.start()
            if (!ok) fsm.dispatch({ type: "pam:unavailable" })
        }

        onUnlockRequested: lock.locked = false
    }

    property int dotCount: 0

    // ------------------------------------------------------------
    // IPC
    // ------------------------------------------------------------

    IpcHandler {
        target: "lock"
        function lock(): void { activate() }
        function unlock(): void { lock.locked = false }
    }

    function activate() {
        fsm.dispatch({ type: "open" })
        lock.locked = true
    }

    // ------------------------------------------------------------
    // Timers
    // ------------------------------------------------------------

    Timer {
        id: retryTimer
        interval: fsm.retryDelayMs
        onTriggered: fsm.dispatch({ type: "retry:ready" })
    }

    Timer {
        id: dotTimer
        interval: 400
        running: fsm.state === "checking"
        repeat: true
        onTriggered: dotCount = (dotCount + 1) % 4
    }

    // ------------------------------------------------------------
    // PAM
    // ------------------------------------------------------------

    PamContext {
        id: pam
        config: "qslock"

        onPamMessage: {
            if (pam.responseRequired && fsm.pendingPassword.length > 0) {
                pam.respond(fsm.pendingPassword)
                fsm.pendingPassword = ""
            }
        }

        onCompleted: (result) => {
            if (result === PamResult.Success) {
                fsm.dispatch({ type: "pam:success" })
            } else if (result === PamResult.Failed) {
                fsm.dispatch({ type: "pam:failed" })
                retryTimer.start()
            } else {
                fsm.dispatch({ type: "pam:error" })
                retryTimer.start()
            }
        }

        onError: (error) => {
            console.error("PAM error:", PamError.toString(error))
        }
    }

    // ------------------------------------------------------------
    // Lock surface
    // ------------------------------------------------------------

    WlSessionLock {
        id: lock

        onLockedChanged: {
            if (!locked) fsm.dispatch({ type: "open" })
        }

        WlSessionLockSurface {
            Rectangle {
                anchors.fill: parent
                color: Theme.bg
                focus: true

                SystemClock { id: clock; precision: SystemClock.Minutes }

                // ------------------------------------------------------------
                // Clock
                // ------------------------------------------------------------

                Text {
                    id: clockText
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        topMargin: 80
                    }
                    color: Theme.fg
                    font.pixelSize: 48
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                }

                Text {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: clockText.bottom
                        topMargin: 4
                    }
                    color: Theme.muted
                    font.pixelSize: 18
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                }

                // ------------------------------------------------------------
                // Password display
                // ------------------------------------------------------------

                Text {
                    id: passwordDisplay
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.verticalCenter
                        topMargin: -30
                    }
                    color: fsm.state === "backoff" || fsm.state === "unavailable"
                        ? Theme.error : Theme.fg
                    font.pixelSize: 24
                    text: "●".repeat(Array.from(fsm.password).length)
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
                        if (fsm.state === "backoff") return Theme.error
                        if (fsm.state === "unavailable") return Theme.error
                        if (fsm.state === "checking") return Theme.warn
                        return Theme.muted
                    }
                }

                // ------------------------------------------------------------
                // Status text
                // ------------------------------------------------------------

                Text {
                    id: statusText
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: inputLine.bottom
                        topMargin: 10
                    }
                    color: fsm.state === "backoff" || fsm.state === "unavailable"
                        ? Theme.error : Theme.muted
                    font.pixelSize: 13
                    text: {
                        if (fsm.state === "unavailable") return "Authentication unavailable"
                        if (fsm.state === "backoff") {
                            if (fsm.authError) return "Authentication error"
                            var msg = "Wrong password (" + fsm.attempts + " attempt"
                                + (fsm.attempts > 1 ? "s" : "") + ")"
                            if (fsm.attempts >= 5)
                                msg += " — wait " + (fsm.retryDelayMs / 1000) + "s"
                            return msg
                        }
                        if (fsm.state === "checking")
                            return "Checking" + ".".repeat(dotCount)
                        return ""
                    }
                }

                // ------------------------------------------------------------
                // Keyboard
                // ------------------------------------------------------------

                Keys.onPressed: (event) => {
                    if (event.modifiers & (Qt.ControlModifier | Qt.MetaModifier))
                        return

                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        fsm.dispatch({ type: "submit" })
                        return
                    }

                    if (event.key === Qt.Key_Backspace) {
                        fsm.dispatch({ type: "backspace" })
                        return
                    }

                    if (/[\u0000-\u001f\u007f]/.test(event.text))
                        return

                    if (event.text.length > 0)
                        fsm.dispatch({ type: "input", text: event.text })
                }
            }
        }
    }
}