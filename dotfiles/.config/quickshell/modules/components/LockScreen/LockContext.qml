pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

Scope {
	id: root
	signal unlocked()
	signal failed()

	// These properties are in the context and not individual lock surfaces
	// so all surfaces can share the same state.
	property string currentText: ""
	property bool unlockInProgress: false
	property bool showFailure: false

	// Driven by LockScreen. Gates the caps-lock watcher so nothing polls
	// while the session is unlocked.
	property bool active: false

	property int failedAttempts: 0
	property bool capsLockOn: false

	onActiveChanged: {
		if (active) {
			failedAttempts = 0
			showFailure = false
			currentText = ""
		} else {
			capsLockOn = false
		}
	}

	// Security: clear password after 10 seconds of inactivity
	Timer {
		id: passwordClearTimer
		interval: 10000
		onTriggered: root.currentText = ""
	}

	// Clear failure text and reset timer when user types
	onCurrentTextChanged: {
		showFailure = false
		if (currentText.length > 0) {
			passwordClearTimer.restart()
		}
	}

	// Caps lock state. One long-lived shell loop that only prints on a change,
	// so the QML side wakes up on transitions rather than every tick.
	Process {
		id: capsWatcher
		running: root.active
		command: ["bash", "-c",
			"prev=x; while :; do s=0; " +
			"for f in /sys/class/leds/*::capslock/brightness; do " +
			"[ -r \"$f\" ] || continue; read -r v < \"$f\"; " +
			"[ \"$v\" != 0 ] && s=1; done; " +
			"if [ \"$s\" != \"$prev\" ]; then echo \"$s\"; prev=$s; fi; " +
			"sleep 0.4; done"]

		stdout: SplitParser {
			onRead: data => root.capsLockOn = data.trim() === "1"
		}
	}

	function tryUnlock() {
		if (currentText === "") return;

		root.unlockInProgress = true;
		pam.start();
	}

	PamContext {
		id: pam

		// Custom pam config for quickshell
		configDirectory: "pam"
		config: "password.conf"

		onPamMessage: {
			if (this.responseRequired) {
				this.respond(root.currentText);
			}
		}

		onCompleted: result => {
			if (result == PamResult.Success) {
				root.unlocked();
			} else {
				root.currentText = "";
				root.showFailure = true;
				root.failedAttempts++;
				root.failed();
			}

			root.unlockInProgress = false;
		}
	}
}
