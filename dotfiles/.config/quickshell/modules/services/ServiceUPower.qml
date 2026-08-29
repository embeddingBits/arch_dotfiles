pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import Quickshell.Services.UPower
import qs.modules.utils

Singleton{
    id: root
    property var powerProfiles:[
        {
            name: "Save",
            icon: "energy_savings_leaf"
        },
        {
            name: "Balance",
            icon: "balance"
        },
        {
            name: "Performance",
            icon: "rocket_launch"
        }
    ]
    property var powerProfile: PowerProfiles.profile
    property string powerProfileIcon: powerProfile === 0 ? "leaf" : "balance" 
    property real powerLevel: UPower.displayDevice.percentage
    property bool isCharging: UPowerDeviceState.Charging === UPower.displayDevice.state
    property real health: 0
    property bool _lowNotified: false
    property bool _ready: false



    onIsChargingChanged: {
        if (isCharging) {
            _lowNotified = false
            //Quickshell.execDetached(["notify-send", "-i", "battery_charging_full", "Battery", "Charging — " + Math.round(powerLevel) + "%"])
            ServiceNotification.sendNotification(
                "Battery",
                "Charging - " + Math.round(powerLevel * 100) + "%",
                "Battery",
                "battery_charging_full"
            )
        } else {
            //Quickshell.execDetached(["notify-send", "-i", "battery_full", "Battery", "Unplugged — " + Math.round(powerLevel) + "%"])
            ServiceNotification.sendNotification(
                "Battery",
                "Unplugged - " + Math.round(powerLevel * 100) + "%",
                "Battery",
                "battery_full"
            )
        }
    }



    Process {
        id: healthProcess
        command: ["bash", "-c", "awk 'NR==1{full=$1} NR==2{design=$1} END{printf \"%.1f\", full/design*100}' /sys/class/power_supply/BAT1/charge_full /sys/class/power_supply/BAT1/charge_full_design"]
        running: true
        stdout: SplitParser {
            onRead: data => root.health = parseFloat(data) / 100
        }
    }
    property string timeToFull: formatTime(UPower.displayDevice.timeToFull)
    property real changeRate: UPower.displayDevice.changeRate
    function setPowerProfile(value){
        PowerProfiles.profile = value
    }

    function formatTime(seconds) {
        var h = Math.floor(seconds / 3600);
        var m = Math.floor((seconds % 3600) / 60);
        if (h > 0)
        return `${h}h, ${m}m`;
        else
        return `${m}m`;
    }
}


