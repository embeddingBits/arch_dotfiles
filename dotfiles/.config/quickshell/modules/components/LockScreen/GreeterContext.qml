import QtQuick
import Quickshell
import Quickshell.Services.Greetd

Scope {
    id: root
    signal readyToLaunch()
    signal failed()

    // Shared state for all greeter surfaces
    property string currentText: ""
    property string currentUser: "steel"  // Default user, change as needed
    property bool unlockInProgress: false
    property bool showFailure: false

    // Clear the failure text once the user starts typing
    onCurrentTextChanged: showFailure = false

    function tryUnlock() {
        if (currentUser === "" || currentText === "") return

        root.unlockInProgress = true
        Greetd.createSession(currentUser)
    }

    function launchSession() {
        // start-hyprland (/usr/bin/start-hyprland) rather than the Hyprland
        // binary directly — the wrapper sets up the session environment.
        Greetd.launch(["start-hyprland"], [], true)
    }

    // Handle authentication messages from greetd
    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            console.log("Auth message:", message, "Error:", error, "Response required:", responseRequired)

            if (responseRequired) {
                // Send the password
                Greetd.respond(root.currentText)
            }
        }

        function onAuthFailure(message) {
            console.log("Auth failed:", message)
            root.currentText = ""
            root.showFailure = true
            root.unlockInProgress = false
        }

        function onReadyToLaunch() {
            console.log("Ready to launch!")
            root.readyToLaunch()
        }

        function onLaunched() {
            console.log("Session launched!")
        }

        function onError(error) {
            console.error("Greetd error:", error)
            root.showFailure = true
            root.unlockInProgress = false
        }

        function onStateChanged() {
            console.log("Greetd state:", Greetd.state)
        }
    }
}
