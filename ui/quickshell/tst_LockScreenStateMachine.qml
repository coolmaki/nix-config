import QtQuick
import QtTest

TestCase {
    name: "LockScreenStateMachine"

    property var lm

    function init() {
        lm = Qt.createComponent("LockScreenStateMachine.qml").createObject()
        lm.dispatch({ type: "open" })
    }

    // ------------------------------------------------------------
    // Initial state
    // ------------------------------------------------------------

    function test_initial() {
        compare(lm.state, "ready")
        compare(lm.password, "")
        compare(lm.pendingPassword, "")
        compare(lm.attempts, 0)
        verify(!lm.authError)
    }

    // ------------------------------------------------------------
    // Input
    // ------------------------------------------------------------

    function test_append_char() {
        lm.dispatch({ type: "input", text: "a" })
        compare(lm.password, "a")
        lm.dispatch({ type: "input", text: "b" })
        compare(lm.password, "ab")
    }

    function test_backspace() {
        lm.password = "abc"
        lm.dispatch({ type: "backspace" })
        compare(lm.password, "ab")
    }

    function test_backspace_empty() {
        lm.dispatch({ type: "backspace" })
        compare(lm.password, "")
    }

    function test_input_in_backoff() {
        lm.state = "backoff"
        lm.dispatch({ type: "input", text: "x" })
        compare(lm.password, "x")
    }

    function test_input_in_checking() {
        lm.state = "checking"
        lm.dispatch({ type: "input", text: "x" })
        compare(lm.password, "x")
    }

    function test_input_in_unavailable() {
        lm.state = "unavailable"
        lm.dispatch({ type: "input", text: "x" })
        compare(lm.password, "x")
    }

    // ------------------------------------------------------------
    // Submit
    // ------------------------------------------------------------

    function test_submit_ready() {
        lm.password = "secret"
        var submitted = false
        lm.onSubmitRequested.connect(function() { submitted = true })
        lm.dispatch({ type: "submit" })
        compare(lm.state, "checking")
        compare(lm.password, "")
        compare(lm.pendingPassword, "secret")
        verify(submitted)
    }

    function test_submit_unavailable() {
        lm.state = "unavailable"
        lm.password = "secret"
        var submitted = false
        lm.onSubmitRequested.connect(function() { submitted = true })
        lm.dispatch({ type: "submit" })
        compare(lm.state, "checking")
        compare(lm.pendingPassword, "secret")
        verify(submitted)
    }

    function test_submit_empty_password() {
        lm.password = ""
        var submitted = false
        lm.onSubmitRequested.connect(function() { submitted = true })
        lm.dispatch({ type: "submit" })
        compare(lm.state, "ready")
        verify(!submitted)
    }

    function test_submit_backoff_ignored() {
        lm.state = "backoff"
        lm.password = "secret"
        var submitted = false
        lm.onSubmitRequested.connect(function() { submitted = true })
        lm.dispatch({ type: "submit" })
        compare(lm.state, "backoff")
        compare(lm.password, "secret")
        verify(!submitted)
    }

    function test_submit_checking_ignored() {
        lm.state = "checking"
        lm.password = "secret"
        var submitted = false
        lm.onSubmitRequested.connect(function() { submitted = true })
        lm.dispatch({ type: "submit" })
        compare(lm.state, "checking")
        compare(lm.password, "secret")
        verify(!submitted)
    }

    // ------------------------------------------------------------
    // PAM results
    // ------------------------------------------------------------

    function test_pam_success() {
        lm.state = "checking"
        lm.pendingPassword = "secret"
        var unlocked = false
        lm.onUnlockRequested.connect(function() { unlocked = true })
        lm.dispatch({ type: "pam:success" })
        verify(unlocked)
    }

    function test_pam_failed() {
        lm.state = "checking"
        lm.pendingPassword = "secret"
        lm.dispatch({ type: "pam:failed" })
        compare(lm.state, "backoff")
        compare(lm.attempts, 1)
        compare(lm.pendingPassword, "")
        verify(!lm.authError)
    }

    function test_pam_failed_increments() {
        lm.attempts = 3
        lm.state = "checking"
        lm.dispatch({ type: "pam:failed" })
        compare(lm.attempts, 4)
    }

    function test_pam_error() {
        lm.state = "checking"
        lm.pendingPassword = "secret"
        lm.dispatch({ type: "pam:error" })
        compare(lm.state, "backoff")
        compare(lm.pendingPassword, "")
        verify(lm.authError)
    }

    function test_pam_unavailable() {
        lm.state = "checking"
        lm.pendingPassword = "secret"
        lm.dispatch({ type: "pam:unavailable" })
        compare(lm.state, "unavailable")
        compare(lm.pendingPassword, "")
    }

    // ------------------------------------------------------------
    // Retry timer
    // ------------------------------------------------------------

    function test_retry_ready() {
        lm.state = "backoff"
        lm.dispatch({ type: "retry:ready" })
        compare(lm.state, "ready")
    }

    function test_retry_ready_noop_when_not_backoff() {
        lm.state = "checking"
        lm.dispatch({ type: "retry:ready" })
        compare(lm.state, "checking")
    }

    // ------------------------------------------------------------
    // Retry delay formula
    // ------------------------------------------------------------

    function test_retry_delay_low_attempts() {
        lm.attempts = 0
        compare(lm.retryDelayMs, 1000)
        lm.attempts = 4
        compare(lm.retryDelayMs, 1000)
    }

    function test_retry_delay_exponential() {
        lm.attempts = 5
        compare(lm.retryDelayMs, 2000)
        lm.attempts = 6
        compare(lm.retryDelayMs, 4000)
        lm.attempts = 7
        compare(lm.retryDelayMs, 8000)
        lm.attempts = 8
        compare(lm.retryDelayMs, 16000)
    }

    function test_retry_delay_capped() {
        lm.attempts = 9
        compare(lm.retryDelayMs, 30000)
        lm.attempts = 20
        compare(lm.retryDelayMs, 30000)
    }

    // ------------------------------------------------------------
    // Open / reset
    // ------------------------------------------------------------

    function test_open_resets() {
        lm.state = "backoff"
        lm.password = "abc"
        lm.pendingPassword = "xyz"
        lm.attempts = 5
        lm.authError = true
        lm.dispatch({ type: "open" })
        compare(lm.state, "ready")
        compare(lm.password, "")
        compare(lm.pendingPassword, "")
        compare(lm.attempts, 0)
        verify(!lm.authError)
    }
}