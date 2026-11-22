import Quickshell
import Quickshell.Io
import QtQuick
import ".."

PanelWindow {
    screen: ScreenHelper.focusedScreen()
    anchors { top: true; left: true; right: true }
    margins { left: 16; right: 16 }
    implicitHeight: 40
    color: "transparent"

    // Workspace data
    property var workspaces: []
    property int activeWsId: -1

    Rectangle {
        anchors.fill: parent
        bottomLeftRadius: 8
        bottomRightRadius: 8
        color: "#aa595959"

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: 1
            anchors.rightMargin: 1
            anchors.bottomMargin: 1
            bottomLeftRadius: 8
            bottomRightRadius: 8
            color: Theme.bg
        }
    }

    // ------------------------------------------------------------
    // IPC
    // ------------------------------------------------------------

    IpcHandler {
        target: "bar"
        function refresh(): void { fetchAll() }
    }

    // ------------------------------------------------------------
    // Left — workspaces
    // ------------------------------------------------------------

    Row {
        id: workspaceRow
        anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
        spacing: 16

        Repeater {
            model: ListModel { id: workspaceModel }

            Text {
                required property int wsId
                required property string wsName
                required property bool wsActive

                text: wsActive ? "\uebb4" : "\ueb8a"
                color: wsActive ? Theme.accent.content : Theme.secondary
                font.pixelSize: 16
            }
        }
    }

    // Right — status + clock

        Text {
            id: batteryIcon
            anchors { right: timeText.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
            color: Theme.success.content
            font.pixelSize: 20
            text: ""
        }

        Text {
            id: timeText
            anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
            color: Theme.primary
            font.pixelSize: 16
            text: Qt.formatDateTime(clock.date, "HH:mm")
        }

        Text {
            id: networkIcon
            anchors { right: batteryIcon.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
            color: Theme.secondary
            font.pixelSize: 16
            text: ""
            visible: text !== ""
        }

        SystemClock { id: clock; precision: SystemClock.Minutes }

    // ------------------------------------------------------------
    // Startup trigger
    // ------------------------------------------------------------

    Timer {
        interval: 0
        running: true
        repeat: false
        onTriggered: fetchAll()
    }

    function fetchAll(): void {
        wsProcess.running = true
        awProcess.running = true
        netProcess.running = true
        batProcess.running = true
    }

    // ------------------------------------------------------------
    // Workspace polling
    // ------------------------------------------------------------

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: { wsProcess.running = true; awProcess.running = true }
    }

    Process {
        id: wsProcess
        command: ["hyprctl", "-j", "workspaces"]
        running: false

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) return
            var out = wsProcess.stdout
            if (!out || !out.text) return
            try {
                workspaces = JSON.parse(out.text)
                rebuildWorkspaces()
            } catch (e) {}
        }

        stdout: StdioCollector {}
    }

    Process {
        id: awProcess
        command: ["hyprctl", "-j", "activeworkspace"]
        running: false

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) return
            var out = awProcess.stdout
            if (!out || !out.text) return
            try {
                var aw = JSON.parse(out.text)
                if (aw && aw.id !== undefined) {
                    activeWsId = aw.id
                    rebuildWorkspaces()
                }
            } catch (e) {}
        }

        stdout: StdioCollector {}
    }

    function rebuildWorkspaces(): void {
        workspaceModel.clear()
        if (!workspaces || workspaces.length === 0) return
        for (var j = 0; j < workspaces.length; j++) {
            var ws = workspaces[j]
            workspaceModel.append({
                wsId: ws.id,
                wsName: ws.name || String(ws.id),
                wsActive: ws.id === activeWsId
            })
        }
    }

    // ------------------------------------------------------------
    // Network polling
    // ------------------------------------------------------------

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: netProcess.running = true
    }

    Process {
        id: netProcess
        command: ["sh", "-c", "grep -q up /sys/class/net/wl*/operstate 2>/dev/null && echo 1"]
        running: false

        onExited: (exitCode, exitStatus) => {
            var out = netProcess.stdout
            networkIcon.text = (out && out.text && out.text.trim().length > 0) ? "\uf1eb" : ""
        }

        stdout: StdioCollector {}
    }

    // ------------------------------------------------------------
    // Battery polling
    // ------------------------------------------------------------

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: batProcess.running = true
    }

    Process {
        id: batProcess
        command: ["sh", "-c", "awk 'NR==1{n=$1} NR==2{f=$1} END{printf \"%d\", (n*100+f-1)/f}' /sys/class/power_supply/BAT0/charge_now /sys/class/power_supply/BAT0/charge_full"]
        running: false

        onExited: (exitCode, exitStatus) => {
            var out = batProcess.stdout
            if (!out || !out.text) {
                batteryIcon.text = ""
                return
            }
            var pct = parseInt(out.text.trim())
            if (isNaN(pct)) {
                batteryIcon.text = ""
                return
            }
            batteryIcon.text = batteryIconFor(pct)
            batteryIcon.color = batteryColorFor(pct)
        }

        stdout: StdioCollector {}
    }

    function batteryIconFor(pct: int): string {
        if (pct >= 90) return "\uf240"
        if (pct >= 60) return "\uf241"
        if (pct >= 30) return "\uf242"
        if (pct >= 10) return "\uf243"
        return "\uf244"
    }

    function batteryColorFor(pct: int): color {
        if (pct >= 60) return Theme.success.content
        if (pct >= 30) return Theme.warn.content
        return Theme.error.content
    }
}