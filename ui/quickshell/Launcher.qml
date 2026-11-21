import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    property bool shown: false
    property var allApps: []

    IpcHandler {
        target: "launcher"
        function toggle(): void { shown ? hide() : show() }
        function open(): void { show() }
        function close(): void { hide() }
    }

    function show() {
        searchInput.text = ""
        filterApps()
        searchInput.focus = true
        shown = true
    }

    function hide() {
        shown = false
    }

    function loadApps() {
        let entries = DesktopEntries.applications.values
        if (entries.length === 0) return
        let apps = []
        for (let i = 0; i < entries.length; i++) {
            apps.push(entries[i])
        }
        apps.sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()))
        allApps = apps
    }

    function filterApps() {
        appListModel.clear()
        let query = (searchInput.text || "").toLowerCase()
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

    Component.onCompleted: loadApps()

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { loadApps() }
    }

    PanelWindow {
        id: window
        screen: Quickshell.screens[0]
        anchors { top: true; left: true; right: true; bottom: true }
        color: "transparent"
        visible: root.shown
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: 600
                height: 420
                color: Theme.bg
                radius: 8
                border {
                    color: Theme.muted
                    width: 1
                }
                focus: true

                Keys.onEscapePressed: root.hide()

                Rectangle {
                    id: searchArea
                    anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
                    height: 40
                    color: Theme.surface
                    radius: 6

                    TextInput {
                        id: searchInput
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        color: Theme.fg
                        font.pixelSize: 16
                        verticalAlignment: TextInput.AlignVCenter
                        focus: true

                        onTextChanged: root.filterApps()

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
                                root.hide()
                            }
                        }
                        Keys.onEscapePressed: root.hide()
                    }
                }

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
                            color: index === resultsList.selectedIndex ? Theme.selected : "transparent"
                            radius: 6
                        }

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: 12
                                verticalCenter: parent.verticalCenter
                            }
                            text: model.name
                            color: Theme.fg
                            font.pixelSize: 14
                        }

                        Text {
                            anchors {
                                right: parent.right
                                rightMargin: 12
                                verticalCenter: parent.verticalCenter
                            }
                            text: model.genericName || ""
                            color: Theme.muted
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                model.entry.execute()
                                root.hide()
                            }
                            onEntered: resultsList.selectedIndex = index
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: root.hide()
            }
        }
    }
}