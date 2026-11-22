import QtQml

QtObject {

    // ------------------------------------------------------------
    // Properties
    // ------------------------------------------------------------

    property string mode: "menu"
    property int idx: 0
    property string action: ""
    property int exitCode: 0
    property string stderr: ""

    // ------------------------------------------------------------
    // Signals
    // ------------------------------------------------------------

    signal execRequested(var command)
    signal hideRequested

    // ------------------------------------------------------------
    // Public
    // ------------------------------------------------------------

    function dispatch(event) {
        switch (event.type) {

        // ------------------------------------------------------------
        // Navigation
        // ------------------------------------------------------------

        case "nav:up":    if (mode !== "menu") return; idx = Math.max(0, idx - 1); break
        case "nav:down":  if (mode !== "menu") return; idx = Math.min(1, idx + 1); break
        case "nav:left":  if (mode !== "reboot" && mode !== "shutdown") return; idx = Math.max(0, idx - 1); break
        case "nav:right": if (mode !== "reboot" && mode !== "shutdown") return; idx = Math.min(1, idx + 1); break

        // ------------------------------------------------------------
        // Selection
        // ------------------------------------------------------------

        case "select":
            if (mode === "menu") { action = idx === 0 ? "reboot" : "shutdown"; mode = action; idx = 0 }
            else if (mode === "reboot" || mode === "shutdown") {
                if (idx === 0) { exitCode = 0; stderr = ""; mode = "running"; execRequested(action === "reboot" ? ["systemctl", "reboot"] : ["systemctl", "poweroff"]) }
                else { mode = "menu"; action = ""; idx = 0 }
            }
            break

        // ------------------------------------------------------------
        // Back / dismiss
        // ------------------------------------------------------------

        case "back":    if (mode === "reboot" || mode === "shutdown") { mode = "menu"; action = ""; idx = 0 } else { hideRequested() }; break
        case "dismiss": hideRequested(); break

        // ------------------------------------------------------------
        // Lifecycle
        // ------------------------------------------------------------

        case "open": mode = "menu"; idx = 0; action = ""; exitCode = 0; stderr = ""; break

        // ------------------------------------------------------------
        // Process result
        // ------------------------------------------------------------

        case "process:exited":
            if (mode !== "running") return
            if (event.exitCode === 0) return
            mode = "error"; exitCode = event.exitCode; stderr = event.stderr
            break
        }
    }
}