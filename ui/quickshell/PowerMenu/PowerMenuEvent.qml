import QtQml

QtObject {
    enum Type {
        NavUp,
        NavDown,
        NavLeft,
        NavRight,
        Select,
        Back,
        Dismiss,
        Open,
        ProcessExited
    }

    required property int type

    // ProcessExited
    property int exitCode: 0
    property string stderr: ""
}