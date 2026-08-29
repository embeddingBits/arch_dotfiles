import Quickshell
import QtQuick

pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root

    property string scheme: SettingsConfig.general.motionScheme ?? "expressive"
    readonly property bool expressive: root.scheme !== "standard"

    property QtObject spatial
    property QtObject effects
    property QtObject container

    container: QtObject {
        readonly property int duration: 360
        readonly property int radiusDuration: 200
        readonly property int crossFadeDuration: 210
        readonly property var curve: [0.53, 0.47, 0.53, 1.06, 1, 1]
        readonly property var alphaOut: [0.0, 0.0, 0.8, 1.0, 1, 1]
        readonly property var alphaIn: [0.4, 0.0, 1.0, 1.0, 1, 1]
    }

    spatial: QtObject {
        readonly property int fastDuration:    root.expressive ? 350 : 220
        readonly property int defaultDuration: root.expressive ? 500 : 315
        readonly property int slowDuration:    root.expressive ? 650 : 480

        readonly property var fastCurve:    root.expressive ? [0.42, 1.67, 0.21, 0.90, 1, 1]
                                                            : [0.25, 0.35, 0.11, 1.14, 1, 1]
        readonly property var defaultCurve: root.expressive ? [0.38, 1.21, 0.22, 1.00, 1, 1]
                                                            : [0.25, 0.35, 0.11, 1.14, 1, 1]
        readonly property var slowCurve:    root.expressive ? [0.39, 1.29, 0.35, 0.98, 1, 1]
                                                            : [0.25, 0.35, 0.11, 1.14, 1, 1]
    }

    effects: QtObject {
        readonly property int fastDuration:    150
        readonly property int defaultDuration: 230
        readonly property int slowDuration:    325
        readonly property var curve: [0.24, 0.36, 0.10, 1.10, 1, 1]
    }

    function spatialDuration(speed) {
        if (speed === "fast") return root.spatial.fastDuration
        if (speed === "slow") return root.spatial.slowDuration
        return root.spatial.defaultDuration
    }

    function spatialCurve(speed) {
        if (speed === "fast") return root.spatial.fastCurve
        if (speed === "slow") return root.spatial.slowCurve
        return root.spatial.defaultCurve
    }

    function effectsDuration(speed) {
        if (speed === "fast") return root.effects.fastDuration
        if (speed === "slow") return root.effects.slowDuration
        return root.effects.defaultDuration
    }
}
