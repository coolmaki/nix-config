import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import ".."

Scope {

    // ------------------------------------------------------------
    // State machine
    // ------------------------------------------------------------

    LockScreenStateMachine {
        id: fsm

        onSubmitRequested: {
            var ok = pam.start()
            if (!ok) {
                lev.type = LockScreenEvent.Type.PamUnavailable
                fsm.dispatch(lev)
            }
        }

        onUnlockRequested: lock.locked = false
    }

    // ------------------------------------------------------------
    // Event object (reused)
    // ------------------------------------------------------------

    LockScreenEvent {
        id: lev
        type: LockScreenEvent.Type.Open
    }

    // ------------------------------------------------------------
    // Misc
    // ------------------------------------------------------------

    property int dotCount: 0

    // ------------------------------------------------------------
    // IPC
    // ------------------------------------------------------------

    IpcHandler {
        target: "lock"
        function lock(): void { activate() }
        function unlock(): void { lock.locked = false }
    }

    function activate(): void {
        LockScreenEvent.Type.Open
        fsm.dispatch(lev)
        lock.locked = true
    }

    // ------------------------------------------------------------
    // Timers
    // ------------------------------------------------------------

    Timer {
        id: retryTimer
        interval: fsm.retryDelayMs
        onTriggered: {
            lev.type = LockScreenEvent.Type.RetryReady
            fsm.dispatch(lev)
        }
    }

    Timer {
        id: dotTimer
        interval: 400
        running: fsm.state === fsm.checking
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
                lev.type = LockScreenEvent.Type.PamSuccess
                fsm.dispatch(lev)
            } else if (result === PamResult.Failed) {
                lev.type = LockScreenEvent.Type.PamFailed
                fsm.dispatch(lev)
                retryTimer.start()
            } else {
                lev.type = LockScreenEvent.Type.PamError
                fsm.dispatch(lev)
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
            if (!locked) {
                LockScreenEvent.Type.Open
                fsm.dispatch(lev)
            }
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
                    color: Theme.primary
                    font.pixelSize: 48
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                }

                Text {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: clockText.bottom
                        topMargin: 4
                    }
                    color: Theme.secondary
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
                    color: fsm.state === fsm.backoff || fsm.state === fsm.unavailable
                        ? Theme.error.content : Theme.primary
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
                        if (fsm.state === fsm.backoff) return Theme.error.content
                        if (fsm.state === fsm.unavailable) return Theme.error.content
                        if (fsm.state === fsm.checking) return Theme.warn.content
                        return Theme.secondary
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
                    color: fsm.state === fsm.backoff || fsm.state === fsm.unavailable
                        ? Theme.error.content : Theme.secondary
                    font.pixelSize: 13
                    text: {
                        if (fsm.state === fsm.unavailable)
                            return "Authentication unavailable"
                        if (fsm.state === fsm.backoff) {
                            if (fsm.authError) return "Authentication error"
                            var msg = "Wrong password (" + fsm.attempts + " attempt"
                                + (fsm.attempts > 1 ? "s" : "") + ")"
                            if (fsm.attempts >= 5)
                                msg += " — wait " + (fsm.retryDelayMs / 1000) + "s"
                            return msg
                        }
                        if (fsm.state === fsm.checking)
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
                        lev.type = LockScreenEvent.Type.Submit
                        fsm.dispatch(lev)
                        return
                    }

                    if (event.key === Qt.Key_Backspace) {
                        lev.type = LockScreenEvent.Type.Backspace
                        fsm.dispatch(lev)
                        return
                    }

                    if (/[\u0000-\u001f\u007f]/.test(event.text))
                        return

                    if (event.text.length > 0) {
                        lev.type = LockScreenEvent.Type.Input
                        lev.text = event.text
                        fsm.dispatch(lev)
                    }
                }
            }
        }
    }
}