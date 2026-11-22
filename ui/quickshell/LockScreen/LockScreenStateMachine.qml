import QtQml

QtObject {
    readonly property int ready: 0
    readonly property int checking: 1
    readonly property int backoff: 2
    readonly property int unavailable: 3

    // ------------------------------------------------------------
    // Properties
    // ------------------------------------------------------------

    property int state: ready
    property string password: ""
    property string pendingPassword: ""
    property int attempts: 0
    property bool authError: false

    readonly property int retryDelayMs: {
        if (attempts < 5) return 1000
        return Math.min(30000, Math.pow(2, attempts - 4) * 1000)
    }

    // ------------------------------------------------------------
    // Signals
    // ------------------------------------------------------------

    signal submitRequested()
    signal unlockRequested()

    // ------------------------------------------------------------
    // Input helpers
    // ------------------------------------------------------------

    function appendChar(text: string): void {
        if (state !== ready && state !== backoff
            && state !== checking && state !== unavailable) return
        password += text
    }

    function backspace(): void {
        if (password.length > 0)
            password = Array.from(password).slice(0, -1).join("")
    }

    // ------------------------------------------------------------
    // Dispatch
    // ------------------------------------------------------------

    function dispatch(event: var): void {
        switch (event.type) {

        case LockScreenEvent.Type.Input:
            appendChar(event.text)
            break

        case LockScreenEvent.Type.Backspace:
            backspace()
            break

        case LockScreenEvent.Type.Submit:
            if (state !== ready && state !== unavailable) return
            if (password.length === 0) return
            pendingPassword = password
            password = ""
            state = checking
            submitRequested()
            break

        case LockScreenEvent.Type.PamSuccess:
            unlockRequested()
            break

        case LockScreenEvent.Type.PamFailed:
            pendingPassword = ""
            authError = false
            attempts++
            state = backoff
            break

        case LockScreenEvent.Type.PamError:
            pendingPassword = ""
            authError = true
            state = backoff
            break

        case LockScreenEvent.Type.PamUnavailable:
            pendingPassword = ""
            state = unavailable
            break

        case LockScreenEvent.Type.RetryReady:
            if (state === backoff)
                state = ready
            break

        case LockScreenEvent.Type.Open:
            state = ready
            password = ""
            pendingPassword = ""
            attempts = 0
            authError = false
            break
        }
    }
}