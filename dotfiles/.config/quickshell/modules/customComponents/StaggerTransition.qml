import QtQuick
import qs.modules.customComponents

Transition {
    id: stagger

    property int step: 30
    property int maxIndex: 6
    property real offset: 14

    SequentialAnimation {
        PauseAnimation {
            duration: Math.min(ViewTransition.index, stagger.maxIndex) * stagger.step
        }

        ParallelAnimation {
            EffectsAnim {
                property: "opacity"
                from: 0
                to: 1
            }

            SpatialAnim {
                property: "y"
                speed: "fast"
                from: ViewTransition.destination.y + stagger.offset
                to: ViewTransition.destination.y
            }
        }
    }
}
