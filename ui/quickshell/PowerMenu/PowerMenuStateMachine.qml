import QtQml

QtObject {
    readonly property int menu: 0
    readonly property int reboot: 1
    readonly property int shutdown: 2
    readonly property int running: 3
    readonly property int error: 4

    // ------------------------------------------------------------
    // Properties
    // ------------------------------------------------------------

    property int mode: menu
    property int idx: 0
    property string action: ""
    property int exitCode: 0
    property string stderr: ""

    // ------------------------------------------------------------
    // Signals
    // ------------------------------------------------------------

    signal execRequested(command: list<string>)
    signal hideRequested()

    // ------------------------------------------------------------
    // Dispatch
    // ------------------------------------------------------------

    function dispatch(event: var): void {
        switch (event.type) {

        case PowerMenuEvent.Type.NavUp:
            if (mode !== menu) return
            idx = Math.max(0, idx - 1)
            break

        case PowerMenuEvent.Type.NavDown:
            if (mode !== menu) return
            idx = Math.min(1, idx + 1)
            break

        case PowerMenuEvent.Type.NavLeft:
            if (mode !== reboot && mode !== shutdown) return
            idx = Math.max(0, idx - 1)
            break

        case PowerMenuEvent.Type.NavRight:
            if (mode !== reboot && mode !== shutdown) return
            idx = Math.min(1, idx + 1)
            break

        case PowerMenuEvent.Type.Select:
            if (mode === menu) {
                action = idx === 0 ? "reboot" : "shutdown"
                mode = idx === 0 ? reboot : shutdown
                idx = 0
            } else if (mode === reboot || mode === shutdown) {
                if (idx === 0) {
                    exitCode = 0
                    stderr = ""
                    mode = running
                    execRequested(action === "reboot" ? ["systemctl", "reboot"] : ["systemctl", "poweroff"])
                } else {
                    mode = menu
                    action = ""
                    idx = 0
                }
            }
            break

        case PowerMenuEvent.Type.Back:
            if (mode === reboot || mode === shutdown) {
                mode = menu
                action = ""
                idx = 0
            } else {
                hideRequested()
            }
            break

        case PowerMenuEvent.Type.Dismiss:
            hideRequested()
            break

        case PowerMenuEvent.Type.Open:
            mode = menu
            idx = 0
            action = ""
            exitCode = 0
            stderr = ""
            break

        case PowerMenuEvent.Type.ProcessExited:
            if (mode !== running) return
            if (event.exitCode === 0) return
            mode = error
            exitCode = event.exitCode
            stderr = event.stderr
            break
        }
    }
}