import Quickshell
import QtQuick

FloatingWindow {
    id: launcher
    title: "Launcher"
    implicitWidth: 600
    implicitHeight: 420
    color: "#1a1b26"
    visible: true

    property var allApps: []

    function loadApps() {
        let entries = DesktopEntries.applications.values
        if (entries.length === 0) return
        let apps = []
        for (let i = 0; i < entries.length; i++) {
            apps.push(entries[i])
        }
        apps.sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()))
        allApps = apps
        filterApps()
    }

    Component.onCompleted: {
        loadApps()
        searchInput.focus = true
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            loadApps()
        }
    }

    function filterApps() {
        appListModel.clear()
        let query = searchInput.text.toLowerCase()
        for (let i = 0; i < allApps.length; i++) {
            let app = allApps[i]
            let name = app.name.toLowerCase()
            let generic = (app.genericName || "").toLowerCase()
            if (query === "" || name.includes(query) || generic.includes(query)) {
                appListModel.append({
                    name: app.name,
                    genericName: app.genericName || "",
                    entry: app
                })
            }
        }
        resultsList.selectedIndex = 0
    }

    // Search field
    Rectangle {
        id: searchArea
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
        height: 40
        color: "#222330"
        radius: 6

        TextInput {
            id: searchInput
            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
            color: "#c0caf5"
            font.pixelSize: 16
            verticalAlignment: TextInput.AlignVCenter
            focus: true

            onTextChanged: filterApps()

            Keys.onDownPressed: {
                if (resultsList.selectedIndex < appListModel.count - 1) {
                    resultsList.selectedIndex++
                    resultsList.positionViewAtIndex(resultsList.selectedIndex, ListView.Contain)
                }
            }
            Keys.onUpPressed: {
                if (resultsList.selectedIndex > 0) {
                    resultsList.selectedIndex--
                    resultsList.positionViewAtIndex(resultsList.selectedIndex, ListView.Contain)
                }
            }
            Keys.onReturnPressed: {
                if (appListModel.count > 0 && resultsList.selectedIndex >= 0) {
                    appListModel.get(resultsList.selectedIndex).entry.execute()
                    Qt.quit()
                }
            }
            Keys.onEscapePressed: {
                if (text !== "") {
                    text = ""
                } else {
                    Qt.quit()
                }
            }
        }
    }

    // Result list
    ListView {
        id: resultsList
        anchors {
            top: searchArea.bottom
            topMargin: 8
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 8
        }
        clip: true
        model: ListModel { id: appListModel }

        property int selectedIndex: 0

        delegate: Item {
            width: ListView.view.width
            height: 40

            Rectangle {
                anchors.fill: parent
                color: index === resultsList.selectedIndex ? "#2a2b36" : "transparent"
                radius: 6
            }

            Text {
                anchors {
                    left: parent.left
                    leftMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                text: model.name
                color: "#c0caf5"
                font.pixelSize: 14
            }

            Text {
                anchors {
                    right: parent.right
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                text: model.genericName || ""
                color: "#565f89"
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    model.entry.execute()
                    Qt.quit()
                }
                onEntered: resultsList.selectedIndex = index
            }
        }
    }
}