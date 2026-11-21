pragma Singleton
import Quickshell
import Quickshell.Hyprland

Singleton {
    function focusedScreen() {
        for (var i = 0; i < Quickshell.screens.length; i++) {
            var s = Quickshell.screens[i]
            if (Hyprland.monitorFor(s) === Hyprland.focusedMonitor)
                return s
        }
        return Quickshell.screens[0]
    }
}