pragma Singleton
import Quickshell
import QtQuick

Singleton {
    // ------------------------------------------------------------
    // Meta
    // ------------------------------------------------------------

    readonly property bool dark: true

    // ------------------------------------------------------------
    // Surface hierarchy
    // ------------------------------------------------------------

    readonly property color bg:       "#1e1e2e"
    readonly property color neutral:  "#313244"
    readonly property color overlay:  "#45475a"
    readonly property color selected: "#45475a"
    readonly property color border:   "#45475a"

    // ------------------------------------------------------------
    // Text hierarchy
    // ------------------------------------------------------------

    readonly property color primary:   "#cdd6f4"
    readonly property color secondary: "#a6adc8"
    readonly property color disabled:  "#6c7086"

    // ------------------------------------------------------------
    // Semantic — paired content / surface
    // ------------------------------------------------------------

    readonly property QtObject accent: QtObject {
        readonly property color content: "#89b4fa"
        readonly property color surface: "#1e2a4a"
    }

    readonly property QtObject success: QtObject {
        readonly property color content: "#a6e3a1"
        readonly property color surface: "#1e2a1e"
    }

    readonly property QtObject warn: QtObject {
        readonly property color content: "#f9e2af"
        readonly property color surface: "#2a261e"
    }

    readonly property QtObject error: QtObject {
        readonly property color content: "#f38ba8"
        readonly property color surface: "#2a1e24"
    }
}