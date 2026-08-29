import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.services

Rectangle {
    id: root
    property string entry: ""

    color: "transparent"

    Image {
        id: clipImage
        anchors.centerIn: parent
        fillMode: Image.PreserveAspectFit
        asynchronous: true

        property var dims: ServiceCliphist.getImageDimensions(root.entry)
        property string imagePath: ServiceCliphist.getImagePath(root.entry)

        property real scale: Math.min(
            parent.width / dims.width,
            parent.height / dims.height,
            1
        )

        width: dims.width * scale
        height: dims.height * scale
        sourceSize.width: width
        sourceSize.height: height

        Component.onCompleted: {
            decodeProcess.running = true
        }
    }

    Process {
        id: decodeProcess
        command: [
            "bash", "-c",
            `mkdir -p '${ServiceCliphist.cliphistDecodeDir}' && [ -f '${clipImage.imagePath}' ] || printf '${root.entry.replace(/'/g, "'\\''")}' | cliphist decode > '${clipImage.imagePath}'`
        ]

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                clipImage.source = "file://" + clipImage.imagePath
            }
        }
    }

    Component.onDestruction: {
        ServiceCliphist.cleanupImage(root.entry)
    }
}
