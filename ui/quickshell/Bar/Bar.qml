import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."
import "../components"

Scope {

    // ------------------------------------------------------------
    // Exclusion Zone
    // ------------------------------------------------------------

     PanelWindow {
        id: exclusionZone
        screen: ScreenHelper.focusedScreen()
        anchors { top: true; left: true; right: true; }
        implicitHeight: 40
        color: "transparent"
    }

    // ------------------------------------------------------------
    // Rendered Bar
    // ------------------------------------------------------------

    PanelWindow {
        id: container
        screen: ScreenHelper.focusedScreen()
        anchors { top: true; left: true; right: true; bottom: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay

        // Only the island is clickable; clicks anywhere else pass through
        // to whatever is behind the bar.
        mask: Region { item: content }

        Rectangle {
            id: content
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
            implicitWidth: widgetsRow.implicitWidth + 32   // 16px padding on each side
            implicitHeight: 40
            bottomLeftRadius: 16
            bottomRightRadius: 16
            color: Theme.bg

            Row {
                id: widgetsRow
                anchors.centerIn: parent
                spacing: 16

                Workspaces { anchors.verticalCenter: parent.verticalCenter }
                NetworkIndicator { anchors.verticalCenter: parent.verticalCenter }
                BatteryIndicator { anchors.verticalCenter: parent.verticalCenter }
                Time { anchors.verticalCenter: parent.verticalCenter }
            }
        }

        Shadow { element: content }
    }
}