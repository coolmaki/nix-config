import QtQuick
import QtTest

TestCase {
    name: "PowerMenuStateMachine"

    property var pm
    property var effects

    function init() {
        pm = Qt.createComponent("PowerMenuStateMachine.qml").createObject()
        pm.mode = "menu"; pm.idx = 0; pm.action = ""; pm.exitCode = 0; pm.stderr = ""
        effects = []
        // Capture signals
        pm.onExecRequested.connect(function(cmd) { effects.push(cmd) })
    }

    // ── initial ──────────────────────────────────

    function test_initial() {
        verify(pm.mode === "menu" || !pm.mode)
        verify(pm.idx === 0 || !pm.idx)
    }

    // ── nav:up/down ──────────────────────────────

    function test_nav_up_clamped() {
        pm.dispatch({ type: "nav:up" })
        compare(pm.idx, 0)
    }

    function test_nav_down() {
        pm.dispatch({ type: "nav:down" })
        compare(pm.idx, 1)
    }

    function test_nav_down_clamped() {
        pm.idx = 1
        pm.dispatch({ type: "nav:down" })
        compare(pm.idx, 1)
    }

    function test_nav_updown_ignored_in_confirm() {
        pm.mode = "reboot"
        pm.dispatch({ type: "nav:down" })
        compare(pm.idx, 0)
    }

    // ── nav:left/right ───────────────────────────

    function test_nav_left_ignored_in_menu() {
        pm.dispatch({ type: "nav:left" })
        compare(pm.idx, 0)
    }

    function test_nav_right_in_confirm() {
        pm.mode = "reboot"
        pm.dispatch({ type: "nav:right" })
        compare(pm.idx, 1)
    }

    function test_nav_right_clamped_in_confirm() {
        pm.mode = "reboot"
        pm.idx = 1
        pm.dispatch({ type: "nav:right" })
        compare(pm.idx, 1)
    }

    // ── select ─────────────────────────────────────

    function test_select_reboot() {
        pm.dispatch({ type: "select" })
        compare(pm.mode, "reboot")
        compare(pm.action, "reboot")
        compare(pm.idx, 0)
    }

    function test_select_shutdown() {
        pm.idx = 1
        pm.dispatch({ type: "select" })
        compare(pm.mode, "shutdown")
    }

    function test_select_yes_emits_exec() {
        pm.mode = "reboot"
        pm.action = "reboot"
        effects.length = 0
        pm.dispatch({ type: "select" })
        compare(pm.mode, "running")
        compare(effects.length, 1)
    }

    function test_select_no_returns_menu() {
        pm.mode = "reboot"
        pm.action = "reboot"
        pm.idx = 1
        pm.dispatch({ type: "select" })
        compare(pm.mode, "menu")
        compare(pm.action, "")
    }

    function test_select_ignored_running() {
        pm.mode = "running"
        pm.action = "reboot"
        effects.length = 0
        pm.dispatch({ type: "select" })
        compare(pm.mode, "running")
        compare(effects.length, 0)
    }

    function test_select_ignored_error() {
        pm.mode = "error"
        pm.action = "reboot"
        effects.length = 0
        pm.dispatch({ type: "select" })
        compare(pm.mode, "error")
        compare(effects.length, 0)
    }

    // ── back ────────────────────────────────────────

    function test_back_from_confirm() {
        pm.mode = "reboot"
        pm.dispatch({ type: "back" })
        compare(pm.mode, "menu")
        compare(pm.action, "")
    }

    function test_back_from_menu_hides() {
        var hideCalled = false
        pm.onHideRequested.connect(function() { hideCalled = true })
        pm.dispatch({ type: "back" })
        verify(hideCalled)
    }

    function test_back_from_error_hides() {
        pm.mode = "error"
        pm.action = "reboot"
        var hideCalled = false
        pm.onHideRequested.connect(function() { hideCalled = true })
        pm.dispatch({ type: "back" })
        verify(hideCalled)
    }

    // ── process:exited ───────────────────────────

    function test_exit_zero_stays_running() {
        pm.mode = "running"
        pm.dispatch({ type: "process:exited", exitCode: 0, stderr: "" })
        compare(pm.mode, "running")
    }

    function test_exit_nonzero_enters_error() {
        pm.mode = "running"
        pm.action = "shutdown"
        pm.dispatch({ type: "process:exited", exitCode: 5, stderr: "denied" })
        compare(pm.mode, "error")
        compare(pm.exitCode, 5)
        compare(pm.stderr, "denied")
    }

    function test_exit_ignored_outside_running() {
        pm.dispatch({ type: "process:exited", exitCode: 1, stderr: "" })
        compare(pm.mode, "menu")
    }

    // ── open ─────────────────────────────────────

    function test_open_resets() {
        pm.mode = "error"
        pm.action = "reboot"
        pm.exitCode = 3
        pm.stderr = "fail"
        pm.dispatch({ type: "open" })
        compare(pm.mode, "menu")
        compare(pm.idx, 0)
        compare(pm.action, "")
        compare(pm.exitCode, 0)
        compare(pm.stderr, "")
    }
}