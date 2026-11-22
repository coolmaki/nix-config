import QtQuick
import QtTest

TestCase {
    name: "LockScreenStateMachine"

    // Event type constants (matching LockScreenEvent.Type enum order)
    readonly property int inputConst: 0
    readonly property int backspaceConst: 1
    readonly property int submitConst: 2
    readonly property int pamSuccessConst: 3
    readonly property int pamFailedConst: 4
    readonly property int pamErrorConst: 5
    readonly property int pamUnavailableConst: 6
    readonly property int retryReadyConst: 7
    readonly property int openConst: 8

    // State constants (matching LockScreenStateMachine.State enum order)
    readonly property int stateReadyConst: 0
    readonly property int stateCheckingConst: 1
    readonly property int stateBackoffConst: 2
    readonly property int stateUnavailableConst: 3

    property var lm
    property var lev

    function init() {
        lev = Qt.createComponent("LockScreenEvent.qml").createObject(null, { type: openConst })
        lm = Qt.createComponent("LockScreenStateMachine.qml").createObject()
        lm.dispatch(ev(openConst))
    }

    function ev(type: int): var {
        lev.type = type
        lev.text = ""
        return lev
    }

    // ------------------------------------------------------------
    // Initial state
    // ------------------------------------------------------------

    function test_initial() {
        compare(lm.state, stateReadyConst)
        compare(lm.password, "")
        compare(lm.pendingPassword, "")
        compare(lm.attempts, 0)
        verify(!lm.authError)
    }

    // ------------------------------------------------------------
    // Input
    // ------------------------------------------------------------

    function test_append_char() {
        var e = ev(inputConst)
        e.text = "a"
        lm.dispatch(e)
        compare(lm.password, "a")
        e.text = "b"
        lm.dispatch(e)
        compare(lm.password, "ab")
    }

    function test_backspace() {
        lm.password = "abc"
        lm.dispatch(ev(backspaceConst))
        compare(lm.password, "ab")
    }

    function test_backspace_empty() {
        lm.dispatch(ev(backspaceConst))
        compare(lm.password, "")
    }

    function test_input_in_backoff() {
        lm.state = stateBackoffConst
        var e = ev(inputConst)
        e.text = "x"
        lm.dispatch(e)
        compare(lm.password, "x")
    }

    function test_input_in_checking() {
        lm.state = stateCheckingConst
        var e = ev(inputConst)
        e.text = "x"
        lm.dispatch(e)
        compare(lm.password, "x")
    }

    function test_input_in_unavailable() {
        lm.state = stateUnavailableConst
        var e = ev(inputConst)
        e.text = "x"
        lm.dispatch(e)
        compare(lm.password, "x")
    }

    // ------------------------------------------------------------
    // Submit
    // ------------------------------------------------------------

    function test_submit_ready() {
        lm.password = "secret"
        var submitted = false
        lm.onSubmitRequested.connect(function() { submitted = true })
        lm.dispatch(ev(submitConst))
        compare(lm.state, stateCheckingConst)
        compare(lm.password, "")
        compare(lm.pendingPassword, "secret")
        verify(submitted)
    }

    function test_submit_unavailable() {
        lm.state = stateUnavailableConst
        lm.password = "secret"
        var submitted = false
        lm.onSubmitRequested.connect(function() { submitted = true })
        lm.dispatch(ev(submitConst))
        compare(lm.state, stateCheckingConst)
        compare(lm.pendingPassword, "secret")
        verify(submitted)
    }

    function test_submit_empty_password() {
        lm.password = ""
        var submitted = false
        lm.onSubmitRequested.connect(function() { submitted = true })
        lm.dispatch(ev(submitConst))
        compare(lm.state, stateReadyConst)
        verify(!submitted)
    }

    function test_submit_backoff_ignored() {
        lm.state = stateBackoffConst
        lm.password = "secret"
        var submitted = false
        lm.onSubmitRequested.connect(function() { submitted = true })
        lm.dispatch(ev(submitConst))
        compare(lm.state, stateBackoffConst)
        compare(lm.password, "secret")
        verify(!submitted)
    }

    function test_submit_checking_ignored() {
        lm.state = stateCheckingConst
        lm.password = "secret"
        var submitted = false
        lm.onSubmitRequested.connect(function() { submitted = true })
        lm.dispatch(ev(submitConst))
        compare(lm.state, stateCheckingConst)
        compare(lm.password, "secret")
        verify(!submitted)
    }

    // ------------------------------------------------------------
    // PAM results
    // ------------------------------------------------------------

    function test_pam_success() {
        lm.state = stateCheckingConst
        lm.pendingPassword = "secret"
        var unlocked = false
        lm.onUnlockRequested.connect(function() { unlocked = true })
        lm.dispatch(ev(pamSuccessConst))
        verify(unlocked)
    }

    function test_pam_failed() {
        lm.state = stateCheckingConst
        lm.pendingPassword = "secret"
        lm.dispatch(ev(pamFailedConst))
        compare(lm.state, stateBackoffConst)
        compare(lm.attempts, 1)
        compare(lm.pendingPassword, "")
        verify(!lm.authError)
    }

    function test_pam_failed_increments() {
        lm.attempts = 3
        lm.state = stateCheckingConst
        lm.dispatch(ev(pamFailedConst))
        compare(lm.attempts, 4)
    }

    function test_pam_error() {
        lm.state = stateCheckingConst
        lm.pendingPassword = "secret"
        lm.dispatch(ev(pamErrorConst))
        compare(lm.state, stateBackoffConst)
        compare(lm.pendingPassword, "")
        verify(lm.authError)
    }

    function test_pam_unavailable() {
        lm.state = stateCheckingConst
        lm.pendingPassword = "secret"
        lm.dispatch(ev(pamUnavailableConst))
        compare(lm.state, stateUnavailableConst)
        compare(lm.pendingPassword, "")
    }

    // ------------------------------------------------------------
    // Retry timer
    // ------------------------------------------------------------

    function test_retry_ready() {
        lm.state = stateBackoffConst
        lm.dispatch(ev(retryReadyConst))
        compare(lm.state, stateReadyConst)
    }

    function test_retry_ready_noop_when_not_backoff() {
        lm.state = stateCheckingConst
        lm.dispatch(ev(retryReadyConst))
        compare(lm.state, stateCheckingConst)
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
        lm.state = stateBackoffConst
        lm.password = "abc"
        lm.pendingPassword = "xyz"
        lm.attempts = 5
        lm.authError = true
        lm.dispatch(ev(openConst))
        compare(lm.state, stateReadyConst)
        compare(lm.password, "")
        compare(lm.pendingPassword, "")
        compare(lm.attempts, 0)
        verify(!lm.authError)
    }
}