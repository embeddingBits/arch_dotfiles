import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents

WelcomeTile {
    id: tile

    icon: "partly_cloudy_day"
    title: "WEATHER"
    note: "optional"

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        radius: 20
        color: Colors.surfaceContainerHigh
        border.width: locationInput.activeFocus ? 1 : 0
        border.color: Colors.primary

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 15
            anchors.rightMargin: 15
            spacing: 9

            MaterialIconSymbol {
                content: "location_on"
                iconSize: 16
                customColor: locationInput.activeFocus ? Colors.primary : Colors.outline
            }

            TextInput {
                id: locationInput
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: SettingsConfig.weather.location ?? ""
                color: Colors.surfaceText
                font.pixelSize: 13
                font.family: SettingsConfig.general.defaultFont ?? "Rubik"
                clip: true
                verticalAlignment: TextInput.AlignVCenter
                onEditingFinished: {
                    if (text.trim().length > 0)
                        SettingsConfig.weather = Object.assign({}, SettingsConfig.weather, { location: text.trim() })
                }

                CustomText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: locationInput.text === ""
                    content: "City, or 28.61,77.20"
                    size: 13
                    customColor: Colors.outline
                }
            }
        }
    }

    M3ButtonGroup {
        Layout.preferredWidth: 210
        Layout.preferredHeight: 30
        fillWidth: true
        model: [
            { value: true,  label: "Metric"   },
            { value: false, label: "Imperial" }
        ]
        activeCheck: v => (SettingsConfig.weather.useMetric ?? true) === v
        onSegmentClicked: v => SettingsConfig.weather = Object.assign({}, SettingsConfig.weather, { useMetric: v })
    }

    CustomText {
        Layout.fillWidth: true
        content: "Holidays need nothing — the calendar reads your country from the system timezone."
        size: 12
        customColor: Colors.outline
        wrapMode: Text.WordWrap
    }
}
