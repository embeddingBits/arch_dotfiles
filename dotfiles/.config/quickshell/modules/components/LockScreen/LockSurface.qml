pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents
import qs.modules.services

Item {
    id: root
    required property LockContext context
    focus: true

    Keys.onPressed: event => { auth.input.forceActiveFocus() }

    // ── Clock digit helpers (NewClock style) ──────────────────────────────────
    readonly property string _font: SettingsConfig.general.displayFont ?? "Titan One"

    // These are constants on purpose. _th1/_mh1 are layered items feeding a
    // MultiEffect mask, and their layer textures are captured on first render —
    // so anything that resizes them afterwards (e.g. deriving _sz from
    // root.height, which is 0 until geometry arrives) leaves the mask sized for
    // the old glyphs and visibly misaligns the digits.
    readonly property real _sz: 160
    readonly property real _fX: 26    // overlap offset (scaled from NewClock 40/250 * 160)

    readonly property string h1: {
        let h = parseInt(ServiceClock.hour)
        if (h > 12) h -= 12; if (h === 0) h = 12
        return Math.floor(h / 10).toString()
    }
    readonly property string h2: {
        let h = parseInt(ServiceClock.hour)
        if (h > 12) h -= 12; if (h === 0) h = 12
        return (h % 10).toString()
    }
    readonly property string m1: ServiceClock.minute[0] ?? "0"
    readonly property string m2: ServiceClock.minute[1] ?? "0"

    // Corners settle in after the surface itself has slid into place.
    property real cornersOpacity: 0
    NumberAnimation on cornersOpacity {
        from: 0; to: 1; duration: 450; easing.type: Easing.OutQuad
    }

    // ── Blurred wallpaper ─────────────────────────────────────────────────────
    Image {
        anchors.fill: parent
        source: WallpaperTheme.wallpaper
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: 1920
        sourceSize.height: 1080
        asynchronous: true
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true; blur: 0.8; blurMax: 40; autoPaddingEnabled: false
        }
    }

    // Gradient scrim — darkest through the middle band where the auth stack
    // sits, so the pill and its border stay legible over any wallpaper.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.00; color: Qt.rgba(0, 0, 0, 0.30) }
            GradientStop { position: 0.50; color: Qt.rgba(0, 0, 0, 0.46) }
            GradientStop { position: 1.00; color: Qt.rgba(0, 0, 0, 0.38) }
        }
    }

    // ── Corners ───────────────────────────────────────────────────────────────
    LockWeatherChip {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 30
        opacity: root.cornersOpacity
    }

    LockStatusRow {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 30
        opacity: root.cornersOpacity
    }

    LockMusicCard {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 30
        opacity: root.cornersOpacity
    }

    LockPowerActions {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 30
        opacity: root.cornersOpacity
    }

    // ── Centered stack: clock → date → avatar → name → password ───────────────
    ColumnLayout {
        id: stack
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        opacity: 0
        NumberAnimation on opacity {
            from: 0; to: 1; duration: 500; easing.type: Easing.OutQuad
        }

        // HH:MM with overlapping digit masking — exact NewClock technique
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: -20

            // H1 (surfaceText, masked by H2)
            Item {
                width: _th1.width; height: _th1.height
                CustomText {
                    id: _th1; content: root.h1; size: root._sz; weight: 600
                    font.family: root._font; color: Colors.surfaceText
                    style: Text.Raised; styleColor: Colors.outline
                    layer.enabled: true; visible: false
                }
                Item {
                    id: _mh1; width: parent.width; height: parent.height
                    layer.enabled: true; visible: false
                    CustomText {
                        content: root.h2; size: root._sz; weight: 600
                        font.family: root._font; color: "white"
                        x: _th1.width - root._fX
                    }
                }
                MultiEffect {
                    source: _th1; anchors.fill: _th1
                    maskEnabled: true; maskSource: _mh1
                    maskInverted: true; maskThresholdMin: 0.5; maskSpreadAtMin: 1.0
                }
            }

            // H2 (primary)
            CustomText {
                content: root.h2; size: root._sz; weight: 600
                font.family: root._font; color: Colors.primary
                style: Text.Raised; styleColor: Colors.outline
            }

            // Colon
            CustomText {
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                content: ":"; size: root._sz; weight: 600
                bottomPadding: 18
                font.family: root._font; color: Colors.primary
                style: Text.Raised; styleColor: Colors.outline
            }

            // M1 (surfaceText, masked by M2)
            Item {
                width: _tm1.width; height: _tm1.height
                CustomText {
                    id: _tm1; content: root.m1; size: root._sz; weight: 600
                    font.family: root._font; color: Colors.surfaceText
                    style: Text.Raised; styleColor: Colors.outline
                    layer.enabled: true; visible: false
                }
                Item {
                    id: _mm1; width: parent.width; height: parent.height
                    layer.enabled: true; visible: false
                    CustomText {
                        content: root.m2; size: root._sz; weight: 600
                        font.family: root._font; color: "white"
                        x: _tm1.width - root._fX
                    }
                }
                MultiEffect {
                    source: _tm1; anchors.fill: _tm1
                    maskEnabled: true; maskSource: _mm1
                    maskInverted: true; maskThresholdMin: 0.5; maskSpreadAtMin: 1.0
                }
            }

            // M2 (primary)
            CustomText {
                content: root.m2; size: root._sz; weight: 600
                font.family: root._font; color: Colors.primary
                style: Text.Raised; styleColor: Colors.outline
            }
        }

        // DAY · 04 AUGUST 2026 — day keeps the two-tone split from NewClock
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0

            CustomText {
                content: ServiceClock.day.slice(0, -3)
                size: 28; weight: 600
                font.family: root._font; color: Colors.surfaceText
                style: Text.Raised; styleColor: Colors.outline
            }
            CustomText {
                content: ServiceClock.day.slice(-3)
                size: 28; weight: 600
                font.family: root._font; color: Colors.primary
                style: Text.Raised; styleColor: Colors.outline
            }
            CustomText {
                leftPadding: 14; rightPadding: 14
                content: "·"
                size: 28; weight: 600
                font.family: root._font; color: Colors.outline
            }
            CustomText {
                content: ServiceClock.date + " " + ServiceClock.month + " " + ServiceClock.year
                size: 28; weight: 600
                font.family: root._font; color: Colors.surfaceText
                style: Text.Raised; styleColor: Colors.outline
            }
        }

        LockAvatar {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 46
            context: root.context
        }

        CustomText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12
            content: Quickshell.env("USER") || "user"
            size: 17; weight: 700
        }

        CustomText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 1
            content: "Hyprland"
            size: 11; weight: 500
            customColor: Colors.outline
        }

        LockAuthField {
            id: auth
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 26
            context: root.context
        }
    }

    // The input can only take focus once it is actually on screen.
    Timer {
        interval: 700; running: true
        onTriggered: auth.input.forceActiveFocus()
    }
}
