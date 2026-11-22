import QtQml

QtObject {

    // ------------------------------------------------------------
    // Properties
    // ------------------------------------------------------------

    property string state: "ready"
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

    signal submitRequested
    signal unlockRequested

    // ------------------------------------------------------------
    // Input helpers
    // ------------------------------------------------------------

    function appendChar(text) {
        if (state !== "ready" && state !== "backoff" && state !== "checking" && state !== "unavailable") return
        password += text
    }

    function backspace() {
        if (password.length > 0)
            password = Array.from(password).slice(0, -1).join("")
    }

    // ------------------------------------------------------------
    // Dispatch
    // ------------------------------------------------------------

    function dispatch(event) {
        switch (event.type) {

        // ------------------------------------------------------------
        // User input
        // ------------------------------------------------------------

        case "input":
            appendChar(event.text)
            break

        case "backspace":
            backspace()
            break

        case "submit":
            if (state !== "ready" && state !== "unavailable") return
            if (password.length === 0) return
            pendingPassword = password
            password = ""
            state = "checking"
            submitRequested()
            break

        // ------------------------------------------------------------
        // PAM results
        // ------------------------------------------------------------

        case "pam:success":
            unlockRequested()
            break

        case "pam:failed":
            pendingPassword = ""
            authError = false
            attempts++
            state = "backoff"
            break

        case "pam:error":
            pendingPassword = ""
            authError = true
            state = "backoff"
            break

        case "pam:unavailable":
            pendingPassword = ""
            state = "unavailable"
            break

        // ------------------------------------------------------------
        // Timer expiry
        // ------------------------------------------------------------

        case "retry:ready":
            if (state === "backoff")
                state = "ready"
            break

        // ------------------------------------------------------------
        // Lifecycle
        // ------------------------------------------------------------

        case "open":
            state = "ready"
            password = ""
            pendingPassword = ""
            attempts = 0
            authError = false
            break
        }
    }
}