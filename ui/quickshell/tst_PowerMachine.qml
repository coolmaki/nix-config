import QtQuick
import QtTest

TestCase {
    name: "PowerMachine"

    property var machine

    function init() {
        machine = Qt.createComponent("PowerMachine.qml").createObject()
    }

    function fresh() {
        return { mode: "menu", index: 0, action: "", exitCode: 0, stderr: "" }
    }

    // ── initial ──────────────────────────────────

    function test_initial() {
        var m = fresh()
        compare(m.mode, "menu")
        compare(m.index, 0)
    }

    // ── nav:up/down ──────────────────────────────

    function test_nav_up_clamped() {
        var m = fresh()
        machine.dispatch(m, { type: "nav:up" })
        compare(m.index, 0)
    }

    function test_nav_down() {
        var m = fresh()
        machine.dispatch(m, { type: "nav:down" })
        compare(m.index, 1)
    }

    function test_nav_down_clamped() {
        var m = fresh()
        m.index = 1
        machine.dispatch(m, { type: "nav:down" })
        compare(m.index, 1)
    }

    function test_nav_updown_ignored_in_confirm() {
        var m = fresh()
        m.mode = "reboot"
        machine.dispatch(m, { type: "nav:down" })
        compare(m.index, 0)
    }

    // ── nav:left/right ───────────────────────────

    function test_nav_left_ignored_in_menu() {
        var m = fresh()
        machine.dispatch(m, { type: "nav:left" })
        compare(m.index, 0)
    }

    function test_nav_right_in_confirm() {
        var m = fresh()
        m.mode = "reboot"
        machine.dispatch(m, { type: "nav:right" })
        compare(m.index, 1)
    }

    function test_nav_right_clamped_in_confirm() {
        var m = fresh()
        m.mode = "reboot"
        m.index = 1
        machine.dispatch(m, { type: "nav:right" })
        compare(m.index, 1)
    }

    // ── select ─────────────────────────────────────

    function test_select_reboot() {
        var m = fresh()
        machine.dispatch(m, { type: "select" })
        compare(m.mode, "reboot")
        compare(m.action, "reboot")
        compare(m.index, 0)
    }

    function test_select_shutdown() {
        var m = fresh()
        m.index = 1
        machine.dispatch(m, { type: "select" })
        compare(m.mode, "shutdown")
    }

    function test_select_yes_emits_exec() {
        var m = fresh()
        m.mode = "reboot"
        m.action = "reboot"
        var effects = []
        machine.dispatch(m, { type: "select" }, effects)
        compare(m.mode, "running")
        compare(effects.length, 1)
        compare(effects[0].type, "exec")
    }

    function test_select_no_returns_menu() {
        var m = fresh()
        m.mode = "reboot"
        m.action = "reboot"
        m.index = 1
        machine.dispatch(m, { type: "select" })
        compare(m.mode, "menu")
        compare(m.action, "")
    }

    function test_select_ignored_running() {
        var m = fresh()
        m.mode = "running"
        m.action = "reboot"
        var effects = []
        machine.dispatch(m, { type: "select" }, effects)
        compare(m.mode, "running")
        compare(effects.length, 0)
    }

    function test_select_ignored_error() {
        var m = fresh()
        m.mode = "error"
        m.action = "reboot"
        var effects = []
        machine.dispatch(m, { type: "select" }, effects)
        compare(m.mode, "error")
        compare(effects.length, 0)
    }

    // ── back ────────────────────────────────────────

    function test_back_from_confirm() {
        var m = fresh()
        m.mode = "reboot"
        var effects = []
        machine.dispatch(m, { type: "back" }, effects)
        compare(m.mode, "menu")
        compare(m.action, "")
    }

    function test_back_from_menu_hides() {
        var m = fresh()
        var effects = []
        machine.dispatch(m, { type: "back" }, effects)
        compare(effects.length, 1)
        compare(effects[0].type, "hide")
    }

    function test_back_from_error_hides() {
        var m = fresh()
        m.mode = "error"
        m.action = "reboot"
        var effects = []
        machine.dispatch(m, { type: "back" }, effects)
        compare(effects.length, 1)
        compare(effects[0].type, "hide")
    }

    // ── process:exited ───────────────────────────

    function test_exit_zero_stays_running() {
        var m = fresh()
        m.mode = "running"
        machine.dispatch(m, { type: "process:exited", exitCode: 0, stderr: "" })
        compare(m.mode, "running")
    }

    function test_exit_nonzero_enters_error() {
        var m = fresh()
        m.mode = "running"
        m.action = "shutdown"
        machine.dispatch(m, { type: "process:exited", exitCode: 5, stderr: "denied" })
        compare(m.mode, "error")
        compare(m.exitCode, 5)
        compare(m.stderr, "denied")
    }

    function test_exit_ignored_outside_running() {
        var m = fresh()
        machine.dispatch(m, { type: "process:exited", exitCode: 1, stderr: "" })
        compare(m.mode, "menu")
    }

    // ── open ─────────────────────────────────────

    function test_open_resets() {
        var m = fresh()
        m.mode = "error"
        m.action = "reboot"
        m.exitCode = 3
        m.stderr = "fail"
        machine.dispatch(m, { type: "open" })
        compare(m.mode, "menu")
        compare(m.index, 0)
        compare(m.action, "")
        compare(m.exitCode, 0)
        compare(m.stderr, "")
    }
}