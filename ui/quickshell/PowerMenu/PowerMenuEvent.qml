import QtQml

QtObject {
    enum Type {
        NavLeft,
        NavRight,
        Select,
        Dismiss,
        Open,
        ProcessExited
    }

    required property int type

    // ProcessExited
    property int exitCode: 0
    property string stderr: ""
}
