pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import Quickshell.Bluetooth
import QtQml.Models

Singleton {
    id: root

    property var list: !Bluetooth.devices?.values ? [] :
        Bluetooth.devices.values.slice().sort((a, b) =>
            a.connected !== b.connected ? b.connected - a.connected :
            (a.name || "").localeCompare(b.name || "")
    )
    property var pairedDevices: list.filter(device => device.paired && device.state !== 1)
    property var unpairedDevices: list.filter(device => !device.paired)
    property var connectedDevicesList: list.filter(device => device.state === 1)
    property var connectedAndPairedDevices: list.filter(device => device.state === 1 || device.paired)
    property int connectedDevices: list.filter(device => device.state === 1).length
    property bool state: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.state === 1 ? true : false

    // Watch each device for state changes
     property Instantiator _watchers: Instantiator {
    model: Bluetooth.devices?.values ?? []
    delegate: QtObject {
        id: watcher
        required property BluetoothDevice modelData
        property int prevState: modelData.state

        property Connections _conn: Connections {
            target: watcher.modelData
            function onStateChanged() {
                const dev = watcher.modelData
                const prev = watcher.prevState
                if (prev !== 1 && dev.state === 1) {
                    ServiceNotification.sendNotification(
                        dev.name,
                        "Connected",
                        "Bluetooth",
                        "bluetooth-active"
                    )
                } else if (prev === 1 && dev.state !== 1) {
                    ServiceNotification.sendNotification(
                        dev.name,
                        "Disconnected",
                        "Bluetooth",
                        "bluetooth-disconnected"
                    )
                }
                watcher.prevState = dev.state
            }
        }
    }
}
}
