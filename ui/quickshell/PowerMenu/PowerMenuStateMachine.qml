import QtQml

QtObject {
    enum State {
        Menu,
        Reboot,
        Shutdown,
        Running,
        Error
    }

    // ------------------------------------------------------------
    // Properties
    // ------------------------------------------------------------

    property int mode: PowerMenuStateMachine.Menu
    property int selected: PowerMenuTile.Shutdown
    property bool isLeftSelected: true
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

    function dispatch(e: PowerMenuEvent): void {
        switch (e.type) {

        case PowerMenuEvent.NavLeft:
            if (mode === PowerMenuStateMachine.Menu) {
                selected = PowerMenuTile.Shutdown
                break
            }

            if (mode === PowerMenuStateMachine.Reboot) {
                selected = PowerMenuTile.Back
                break
            }
            
            if (mode === PowerMenuStateMachine.Shutdown) {
                selected = PowerMenuTile.Shutdown
                break
            }

            break

        case PowerMenuEvent.NavRight:
            if (mode === PowerMenuStateMachine.Menu) {
                selected = PowerMenuTile.Reboot
                break
            }

            if (mode === PowerMenuStateMachine.Reboot) {
                selected = PowerMenuTile.Reboot
                break
            }

            if (mode === PowerMenuStateMachine.Shutdown) {
                selected = PowerMenuTile.Back
                break
            }

            break

        case PowerMenuEvent.Select:
            if (mode === PowerMenuStateMachine.Menu && selected === PowerMenuTile.Reboot) {
                mode = PowerMenuStateMachine.Reboot
                break
            }

            if (mode === PowerMenuStateMachine.Menu && selected === PowerMenuTile.Shutdown) {
                mode = PowerMenuStateMachine.Shutdown
                break
            }

            if (mode === PowerMenuStateMachine.Reboot && selected === PowerMenuTile.Back) {
                mode = PowerMenuStateMachine.Menu
                selected = PowerMenuTile.Shutdown
                break
            }

            if (mode === PowerMenuStateMachine.Shutdown && selected === PowerMenuTile.Back) {
                mode = PowerMenuStateMachine.Menu
                selected = PowerMenuTile.Reboot
                break
            }

            if (mode === PowerMenuStateMachine.Reboot && selected === PowerMenuTile.Reboot) {
                exitCode = 0
                stderr = ""
                execRequested(["systemctl", "reboot"])
                break
            }

            if (mode === State.Shutdown && selected === PowerMenuTile.Shutdown) {
                exitCode = 0
                stderr = ""
                execRequested(["systemctl", "poweroff"])
                break
            }

            break

        case PowerMenuEvent.Dismiss:
            hideRequested()
            break

        case PowerMenuEvent.Open:
            mode = PowerMenuStateMachine.Menu
            selected = PowerMenuTile.Shutdown
            exitCode = 0
            stderr = ""
            break

        case PowerMenuEvent.ProcessExited:
            if (mode !== State.Running) return
            if (event.exitCode === 0) return
            mode = PowerMenuStateMachine.Error
            exitCode = event.exitCode
            stderr = event.stderr
            break
        }
    }
}