import QtQml

QtObject {
    function dispatch(m, event, effects) {
        if (!effects) effects = []
        switch (event.type) {
        case "nav:up": if (m.mode !== "menu") return; m.index = Math.max(0, m.index - 1); break
        case "nav:down": if (m.mode !== "menu") return; m.index = Math.min(1, m.index + 1); break
        case "nav:left": if (m.mode !== "reboot" && m.mode !== "shutdown") return; m.index = Math.max(0, m.index - 1); break
        case "nav:right": if (m.mode !== "reboot" && m.mode !== "shutdown") return; m.index = Math.min(1, m.index + 1); break
        case "select":
            if (m.mode === "menu") { m.action = m.index === 0 ? "reboot" : "shutdown"; m.mode = m.action; m.index = 0 }
            else if (m.mode === "reboot" || m.mode === "shutdown") {
                if (m.index === 0) { m.exitCode = 0; m.stderr = ""; m.mode = "running"; effects.push({ type: "exec", command: m.action === "reboot" ? ["systemctl", "reboot"] : ["systemctl", "poweroff"] }) }
                else { m.mode = "menu"; m.action = ""; m.index = 0 }
            }
            break
        case "back":
            if (m.mode === "reboot" || m.mode === "shutdown") { m.mode = "menu"; m.action = ""; m.index = 0 }
            else { effects.push({ type: "hide" }) }
            break
        case "dismiss": effects.push({ type: "hide" }); break
        case "open": m.mode = "menu"; m.index = 0; m.action = ""; m.exitCode = 0; m.stderr = ""; break
        case "process:exited": if (m.mode !== "running") return; if (event.exitCode === 0) return; m.mode = "error"; m.exitCode = event.exitCode; m.stderr = event.stderr; break
        }
    }
}