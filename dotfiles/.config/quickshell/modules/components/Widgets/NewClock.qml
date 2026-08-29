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

WidgetHost{
    id: root
    configKey: "clock"
    defaultPos: Qt.point(100, 100)

    // Sizes to its own content rather than a tile
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

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
    property real fontSize: 250
    property real fontX: 40



    //color: "transparent"
    ColumnLayout{
        id: col
        spacing: 0
        RowLayout {
            id: row
            spacing: -35

            Item {
                width: text1.width
                height: text1.height

                CustomText {
                    id: text1
                    content: hourDigit1
                    size: root.fontSize
                    color:Colors.surfaceText
                    layer.enabled: true
                    visible: false
                    font.family: SettingsConfig.general.displayFont ?? "Titan One"
                    style: Text.Raised
                    styleColor: Colors.outline
                    weight: 600
                }

                Item {
                    id: maskItem
                    width: parent.width
                    height: parent.height
                    layer.enabled: true  
                    visible: false

                    CustomText {
                        id: child
                        content: hourDigit2
                        size: root.fontSize
                        x: text1.width - root.fontX
                        font.family: SettingsConfig.general.displayFont ?? "Titan One"
                        color: "white"
                        style: Text.Raised
                        styleColor: Colors.outline
                        weight: 600
                    }
                }

                MultiEffect {
                    source: text1
                    anchors.fill: text1
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
                Layout.leftMargin: 35
                Layout.rightMargin: 35
                content: ":"
                size: root.fontSize
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
                bottomPadding: 30
                color: Colors.primary
                style: Text.Raised
                styleColor: Colors.outline
                weight: 600
            }

            Item {
                Layout.preferredWidth: text2.width
                Layout.preferredHeight: text2.height

                CustomText {
                    id: text2
                    content: minuteDigit1
                    size: root.fontSize 
                    color:Colors.surfaceText
                    layer.enabled: true
                    visible: false
                    font.family: SettingsConfig.general.displayFont ?? "Titan One"
                    renderType: Text.NativeRendering
                    style: Text.Raised
                    styleColor: Colors.outline
                    weight: 600
                }

                Item {
                    id: maskItem2
                    width: parent.width
                    height: parent.height
                    layer.enabled: true 
                    visible: false

                    CustomText {
                        id: child2
                        content: minuteDigit2
                        size: root.fontSize 
                        x: text2.width - root.fontX
                        font.family: SettingsConfig.general.displayFont ?? "Titan One"
                        color: "white"
                        style: Text.Raised
                        styleColor: Colors.outline
                        weight: 600
                    }
                }

                MultiEffect {
                    source: text2
                    anchors.fill: text2
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
        RowLayout{
            Layout.alignment: Qt.AlignHCenter
            spacing: 0
            CustomText{
                content: ServiceClock.day.slice(0, -3)
                size: 100
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
                style: Text.Raised
                styleColor: Colors.outline
                weight: 600
                color: Colors.surfaceText
            }
            CustomText{
                content: ServiceClock.day.slice(-3)
                size: 100
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
                style: Text.Raised
                styleColor: Colors.outline
                weight: 600
                color: Colors.primary
            }
        }

        RowLayout{
            Layout.alignment: Qt.AlignHCenter
            spacing: 10
            CustomText{
                Layout.alignment: Qt.AlignHCenter
                content: ServiceClock.date
                size: 40
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
                style: Text.Raised
                styleColor: Colors.outline
                weight: 600
            }

            CustomText{
                Layout.alignment: Qt.AlignHCenter
                content: ServiceClock.month
                size: 40
                color: Colors.primary
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
                style: Text.Raised
                styleColor: Colors.outline
                weight: 600
            }

            CustomText{
                Layout.alignment: Qt.AlignHCenter
                content: ServiceClock.year
                size: 40
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
                style: Text.Raised
                styleColor: Colors.outline
                weight: 600
            }
        } 
    }
}
