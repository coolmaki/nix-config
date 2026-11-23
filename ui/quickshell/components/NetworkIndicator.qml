import Quickshell
import Quickshell.Networking
import QtQuick
import ".."

Text {
    color: Theme.secondary
    font.pixelSize: 16
    text: "\uf1eb"
    visible: isNetworkConnected

    readonly property bool isNetworkConnected: Networking.connectivity == NetworkConnectivity.Full    
}