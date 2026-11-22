import QtQuick
import QtTest

TestCase {
    name: "PowerMenuStateMachine"

    // Event type constants (matching PowerMenuEvent.Type enum order)
    readonly property int navUpConst: 0
    readonly property int navDownConst: 1
    readonly property int navLeftConst: 2
    readonly property int navRightConst: 3
    readonly property int selectConst: 4
    readonly property int backConst: 5
    readonly property int dismissConst: 6
    readonly property int openConst: 7
    readonly property int processExitedConst: 8

    // Mode constants (matching PowerMenuStateMachine.Mode enum order)
    readonly property int modeMenuConst: 0
    readonly property int modeRebootConst: 1
    readonly property int modeShutdownConst: 2
    readonly property int modeRunningConst: 3
    readonly property int modeErrorConst: 4

    property var pm
    property var pev
    property var effects

    function init() {
        pev = Qt.createComponent("PowerMenuEvent.qml").createObject(null, { type: openConst })
        pm = Qt.createComponent("PowerMenuStateMachine.qml").createObject()
        effects = []
        pm.onExecRequested.connect(function(cmd) { effects.push(cmd) })
        pm.dispatch(ev(openConst))
    }

    function ev(type: int): var {
        pev.type = type
        pev.exitCode = 0
        pev.stderr = ""
        return pev
    }

    // ------------------------------------------------------------
    // Initial
    // ------------------------------------------------------------

    function test_initial() {
        compare(pm.mode, modeMenuConst)
        compare(pm.idx, 0)
    }

    // ------------------------------------------------------------
    // Nav up/down
    // ------------------------------------------------------------

    function test_nav_up_clamped() {
        pm.dispatch(ev(navUpConst))
        compare(pm.idx, 0)
    }

    function test_nav_down() {
        pm.dispatch(ev(navDownConst))
        compare(pm.idx, 1)
    }

    function test_nav_down_clamped() {
        pm.idx = 1
        pm.dispatch(ev(navDownConst))
        compare(pm.idx, 1)
    }

    function test_nav_updown_ignored_in_confirm() {
        pm.mode = modeRebootConst
        pm.dispatch(ev(navDownConst))
        compare(pm.idx, 0)
    }

    // ------------------------------------------------------------
    // Nav left/right
    // ------------------------------------------------------------

    function test_nav_left_ignored_in_menu() {
        pm.dispatch(ev(navLeftConst))
        compare(pm.idx, 0)
    }

    function test_nav_right_in_confirm() {
        pm.mode = modeRebootConst
        pm.dispatch(ev(navRightConst))
        compare(pm.idx, 1)
    }

    function test_nav_right_clamped_in_confirm() {
        pm.mode = modeRebootConst
        pm.idx = 1
        pm.dispatch(ev(navRightConst))
        compare(pm.idx, 1)
    }

    // ------------------------------------------------------------
    // Select
    // ------------------------------------------------------------

    function test_select_reboot() {
        pm.dispatch(ev(selectConst))
        compare(pm.mode, modeRebootConst)
        compare(pm.action, "reboot")
        compare(pm.idx, 0)
    }

    function test_select_shutdown() {
        pm.idx = 1
        pm.dispatch(ev(selectConst))
        compare(pm.mode, modeShutdownConst)
    }

    function test_select_yes_emits_exec() {
        pm.mode = modeRebootConst
        pm.action = "reboot"
        effects.length = 0
        pm.dispatch(ev(selectConst))
        compare(pm.mode, modeRunningConst)
        compare(effects.length, 1)
    }

    function test_select_no_returns_menu() {
        pm.mode = modeRebootConst
        pm.action = "reboot"
        pm.idx = 1
        pm.dispatch(ev(selectConst))
        compare(pm.mode, modeMenuConst)
        compare(pm.action, "")
    }

    function test_select_ignored_running() {
        pm.mode = modeRunningConst
        pm.action = "reboot"
        effects.length = 0
        pm.dispatch(ev(selectConst))
        compare(pm.mode, modeRunningConst)
        compare(effects.length, 0)
    }

    function test_select_ignored_error() {
        pm.mode = modeErrorConst
        pm.action = "reboot"
        effects.length = 0
        pm.dispatch(ev(selectConst))
        compare(pm.mode, modeErrorConst)
        compare(effects.length, 0)
    }

    // ------------------------------------------------------------
    // Back
    // ------------------------------------------------------------

    function test_back_from_confirm() {
        pm.mode = modeRebootConst
        pm.dispatch(ev(backConst))
        compare(pm.mode, modeMenuConst)
        compare(pm.action, "")
    }

    function test_back_from_menu_hides() {
        var hideCalled = false
        pm.onHideRequested.connect(function() { hideCalled = true })
        pm.dispatch(ev(backConst))
        verify(hideCalled)
    }

    function test_back_from_error_hides() {
        pm.mode = modeErrorConst
        pm.action = "reboot"
        var hideCalled = false
        pm.onHideRequested.connect(function() { hideCalled = true })
        pm.dispatch(ev(backConst))
        verify(hideCalled)
    }

    // ------------------------------------------------------------
    // Process exited
    // ------------------------------------------------------------

    function test_exit_zero_stays_running() {
        pm.mode = modeRunningConst
        var e = ev(processExitedConst)
        e.exitCode = 0
        pm.dispatch(e)
        compare(pm.mode, modeRunningConst)
    }

    function test_exit_nonzero_enters_error() {
        pm.mode = modeRunningConst
        pm.action = "shutdown"
        var e = ev(processExitedConst)
        e.exitCode = 5
        e.stderr = "denied"
        pm.dispatch(e)
        compare(pm.mode, modeErrorConst)
        compare(pm.exitCode, 5)
        compare(pm.stderr, "denied")
    }

    function test_exit_ignored_outside_running() {
        var e = ev(processExitedConst)
        e.exitCode = 1
        pm.dispatch(e)
        compare(pm.mode, modeMenuConst)
    }

    // ------------------------------------------------------------
    // Open
    // ------------------------------------------------------------

    function test_open_resets() {
        pm.mode = modeErrorConst
        pm.action = "reboot"
        pm.exitCode = 3
        pm.stderr = "fail"
        pm.dispatch(ev(openConst))
        compare(pm.mode, modeMenuConst)
        compare(pm.idx, 0)
        compare(pm.action, "")
        compare(pm.exitCode, 0)
        compare(pm.stderr, "")
    }
}