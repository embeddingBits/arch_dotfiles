import QtQuick
import qs.modules.utils
import qs.modules.settings

// Shared chrome for every desktop widget.
//
// Owns position persistence, grid-snapped dragging, the arrange-mode lift and
// preview mode, so no widget has to repeat any of it. A widget file declares a
// configKey plus its footprint and then contains nothing but its own visuals.
//
//     WidgetHost {
//         configKey: "sunArc"
//         tile: WidgetSizes.wide
//         defaultPos: Qt.point(100, 620)
//         ...content...
//     }
//
// Widgets not yet migrated onto the WidgetSizes ladder can set implicitWidth /
// implicitHeight directly instead of `tile`.
//
// Content is added as ordinary children (no default-property alias — aliasing
// the default property to an inner Item is circular, since the holder is itself
// a child). The drag surface sits above them on z.
Item {
    id: root

    // ── API ───────────────────────────────────────────────────────────
    // Prefix for the persisted position: "<configKey>X" / "<configKey>Y".
    // Variants of one family share a key (all date styles use "dateWidget"),
    // so switching style keeps the position.
    property string configKey: ""

    property size tile: WidgetSizes.small
    property point defaultPos: Qt.point(100, 100)

    // Rendered inside the settings gallery: no position, no drag, no saving.
    // Heavy widgets can also read this to throttle animation.
    property bool preview: false

    implicitWidth: tile.width
    implicitHeight: tile.height

    // ── Lift affordance ───────────────────────────────────────────────
    readonly property bool lifted: !preview && GlobalStates.widgetEditMode

    // Deliberately no scale-up here. Growing the widget while arranging makes
    // its footprint disagree with where it will actually land, which makes
    // placing it against the grid harder. The outline below marks it instead —
    // it's drawn inside the bounds, so the footprint stays honest.

    // ── Position ──────────────────────────────────────────────────────
    readonly property bool _persists: !preview && configKey !== ""
    property bool dragging: false

    // Driven by Binding rather than Component.onCompleted: a widget file that
    // declares its own Component.onCompleted would override the host's.
    // RestoreNone so releasing the binding mid-drag keeps the dragged position.
    Binding {
        target: root
        property: "x"
        value: SettingsConfig.widgets[root.configKey + "X"] ?? root.defaultPos.x
        when: root._persists && !root.dragging
        restoreMode: Binding.RestoreNone
    }

    Binding {
        target: root
        property: "y"
        value: SettingsConfig.widgets[root.configKey + "Y"] ?? root.defaultPos.y
        when: root._persists && !root.dragging
        restoreMode: Binding.RestoreNone
    }

    function savePosition() {
        if (!_persists) return
        var patch = {}
        patch[configKey + "X"] = root.x
        patch[configKey + "Y"] = root.y
        SettingsConfig.widgets = Object.assign({}, SettingsConfig.widgets, patch)
    }

    // ── Grid-snapped drag ─────────────────────────────────────────────
    function snap(v) {
        const g = WidgetSizes.gutter
        return Math.round(v / g) * g
    }

    // Double-click a widget to enter arrange mode, as it worked before.
    // Sits *beneath* the content so a widget's own controls keep priority —
    // plain Rectangles don't consume events, so ordinary cards still get it.
    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: !root.preview && !root.lifted
        onDoubleClicked: GlobalStates.widgetEditMode = true
    }

    // Footprint marker — inside the bounds, so it never shifts placement
    Rectangle {
        anchors.fill: parent
        z: 99
        visible: root.lifted
        color: root.dragging ? Qt.alpha(Colors.primary, 0.10) : "transparent"
        radius: WidgetSizes.radius
        border.width: root.dragging ? 2 : 1
        border.color: Qt.alpha(Colors.primary, root.dragging ? 0.95 : 0.55)
    }

    MouseArea {
        anchors.fill: parent
        z: 100
        enabled: root.lifted
        // Must be conditional: Qt applies an item's cursor on hover even when
        // the MouseArea is disabled, which would advertise a drag that is not
        // actually available outside arrange mode.
        cursorShape: root.lifted ? Qt.SizeAllCursor : Qt.ArrowCursor
        preventStealing: true

        // Qt's own drag does the moving; we only quantise the result. Drag
        // recomputes the target from the press offset each event, so rounding
        // in between cannot accumulate drift.
        drag.target: root.lifted ? root : undefined
        drag.threshold: 0

        onPressed: root.dragging = true

        onPositionChanged: {
            if (!drag.active) return
            root.x = root.snap(root.x)
            root.y = root.snap(root.y)
        }

        // Save before clearing `dragging`: the moment dragging goes false the
        // Binding above re-engages, and it must read the new position, not the
        // stale one it would otherwise restore.
        onReleased: {
            if (!root.dragging) return
            root.savePosition()
            root.dragging = false
        }
    }
}
