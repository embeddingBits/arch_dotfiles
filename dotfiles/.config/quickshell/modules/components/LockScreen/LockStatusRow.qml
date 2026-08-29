import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.modules.utils
import qs.modules.services

// Top-right system readout: battery, network, unread notifications.
RowLayout {
    id: root
    spacing: 8

    readonly property real _level: ServiceUPower.powerLevel
    readonly property bool _lowBattery: !ServiceUPower.isCharging && _level > 0 && _level <= 0.15

    // Same thresholds as the bar's Battery.qml so both readouts agree.
    readonly property string _batteryIcon: {
        if (ServiceUPower.isCharging) return "battery_android_bolt"
        if (_level === 1)                       return "battery_android_full"
        if (_level < 1    && _level > 0.9)      return "battery_android_6"
        if (_level <= 0.9 && _level > 0.7)      return "battery_android_5"
        if (_level <= 0.7 && _level > 0.5)      return "battery_android_4"
        if (_level <= 0.5 && _level > 0.3)      return "battery_android_3"
        if (_level <= 0.3 && _level > 0.2)      return "battery_android_2"
        if (_level <= 0.2 && _level > 0)        return "battery_android_1"
        return "battery_android_0"
    }

    LockInfoChip {
        // Desktops have no battery — don't show a permanent 0%
        visible: UPower.displayDevice?.isLaptopBattery ?? false
        icon: root._batteryIcon
        iconSize: 18
        label: Math.round(root._level * 100) + "%"
        iconColor: root._lowBattery
            ? Colors.error
            : ServiceUPower.isCharging ? Colors.primary : Colors.surfaceText
        labelColor: root._lowBattery ? Colors.error : Colors.surfaceText
    }

    LockInfoChip {
        readonly property bool _online: ServiceNetwork.connectionType !== "disconnected"

        icon: ServiceNetwork.icon
        label: ServiceNetwork.connectionLabel !== "" ? ServiceNetwork.connectionLabel : "Offline"
        iconColor: _online ? Colors.surfaceText : Colors.outline
        labelColor: _online ? Colors.surfaceText : Colors.outline
    }

    LockInfoChip {
        icon: "notifications"
        label: ServiceNotification.notificationsNumber.toString()
        iconColor: Colors.primary
        labelColor: Colors.primary
        visible: ServiceNotification.notificationsNumber > 0
    }
}
