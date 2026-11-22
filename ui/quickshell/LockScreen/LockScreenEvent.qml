import QtQml

QtObject {
    enum Type {
        Input,
        Backspace,
        Submit,
        PamSuccess,
        PamFailed,
        PamError,
        PamUnavailable,
        RetryReady,
        Open
    }

    required property int type

    // Input
    property string text: ""
}