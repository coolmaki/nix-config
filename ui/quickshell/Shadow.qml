import QtQuick
import QtQuick.Effects

MultiEffect {
    required property Item element

    source: element
    anchors.fill: element
    shadowEnabled: true
    shadowColor: "black"
    shadowOpacity: 0.6
    shadowBlur: 1.0
    shadowVerticalOffset: 4
    shadowHorizontalOffset: 2
    autoPaddingEnabled: true
}