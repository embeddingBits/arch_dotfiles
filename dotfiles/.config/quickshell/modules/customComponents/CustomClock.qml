import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import QtQuick.Effects
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services
import qs.modules.settings

Item{
    id: root
    anchors.centerIn: parent
    implicitWidth: row.implicitWidth

    property string hourDigit1: {
        var h = ServiceClock.hour > 12 ? ServiceClock.hour - 12 : ServiceClock.hour;
        if(h === 0) h = 12; 
        return Math.floor(h / 10).toString();
    }

    property string hourDigit2: {
        var h = ServiceClock.hour > 12 ? ServiceClock.hour - 12 : ServiceClock.hour;
        if(h === 0) h = 12;
        return (h % 10).toString();
    }
    property string minuteDigit1: ServiceClock.minute[0];
    property string minuteDigit2: ServiceClock.minute[1];
    property real fontSize: 30
    property real fontX: 5



    //color: "transparent"
    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: -3

        Item {
            Layout.preferredWidth: text1.implicitWidth
            Layout.preferredHeight: text1.implicitHeight

            CustomText {
                id: text1
                content: hourDigit1
                size: root.fontSize
                color: Colors.surfaceText
                layer.enabled: true
                visible: false
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
                style: Text.Raised
                styleColor: Colors.outline
                weight: 600
            }

            Item {
                id: maskItem
                width: text1.implicitWidth
                height: text1.implicitHeight
                layer.enabled: true
                visible: false

                CustomText {
                    id: child
                    content: hourDigit2
                    size: root.fontSize + 10
                    x: text1.implicitWidth - root.fontX
                    y: -5
                    font.family: SettingsConfig.general.displayFont ?? "Titan One"
                    color: "white"
                    style: Text.Raised
                    styleColor: Colors.outline
                    weight: 600
                }
            }

            MultiEffect {
                source: text1
                x: 0; y: 0
                width: text1.implicitWidth
                height: text1.implicitHeight
                maskEnabled: true
                maskSource: maskItem
                maskInverted: true
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }
        } 
        CustomText {
            content: hourDigit2
            size: root.fontSize
            color:Colors.primary
            font.family: SettingsConfig.general.displayFont ?? "Titan One"
            style: Text.Raised
            styleColor: Colors.outline
            weight: 600
        }

        CustomText{
            Layout.leftMargin: 5
            Layout.rightMargin: 5
            content: ":"
            size: root.fontSize
            font.family: SettingsConfig.general.displayFont ?? "Titan One"
            bottomPadding: 5
            color: Colors.primary
            style: Text.Raised
            styleColor: Colors.outline
            weight: 600
        }

        Item {
            Layout.preferredWidth: text2.implicitWidth
            Layout.preferredHeight: text2.implicitHeight

            CustomText {
                id: text2
                content: minuteDigit1
                size: root.fontSize
                color: Colors.surfaceText
                layer.enabled: true
                visible: false
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
                style: Text.Raised
                styleColor: Colors.outline
                weight: 600
            }

            Item {
                id: maskItem2
                width: text2.implicitWidth
                height: text2.implicitHeight
                layer.enabled: true
                visible: false

                CustomText {
                    id: child2
                    content: minuteDigit2
                    size: root.fontSize + 10
                    x: text2.implicitWidth - root.fontX
                    y: -5
                    font.family: SettingsConfig.general.displayFont ?? "Titan One"
                    color: "white"
                    style: Text.Raised
                    styleColor: Colors.outline
                    weight: 600
                }
            }

            MultiEffect {
                source: text2
                x: 0; y: 0
                width: text2.implicitWidth
                height: text2.implicitHeight
                maskEnabled: true
                maskSource: maskItem2
                maskInverted: true
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }
        } 
        CustomText {
            content: minuteDigit2
            size: root.fontSize
            color:Colors.primary
            font.family: SettingsConfig.general.displayFont ?? "Titan One"
            style: Text.Raised
            styleColor: Colors.outline
            weight: 600
        }

    }
}
