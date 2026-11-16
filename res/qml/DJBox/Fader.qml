// [AI-generated] This file was written by an AI agent (Claude, Anthropic).
import Mixxx 1.0 as Mixxx
import QtQuick
import "."

// Schieberegler (hoch oder quer), an einen Mixxx-Regler gebunden.
Item {
    id: root

    property bool center: false                // Raste in der Mitte
    required property string group
    property bool horizontal: false
    property bool inverted: false              // hoch: oben = 0 statt oben = 1
    required property string key
    property real length: 90
    readonly property real parameter: control.parameter
    readonly property real pos: horizontal ? control.parameter : inverted ? control.parameter : 1 - control.parameter
    property int ticks: 11
    readonly property real travel: length - (horizontal ? cap.width : cap.height)

    function setFromPos(p) {
        p = Math.max(0, Math.min(1, p));
        let v = horizontal || inverted ? p : 1 - p;
        if (center && Math.abs(v - 0.5) < 0.015)
            v = 0.5;
        control.parameter = v;
    }
    function setParameter(v) {
        control.parameter = Math.max(0, Math.min(1, v));
    }

    activeFocusOnTab: true
    height: horizontal ? 30 : length
    width: horizontal ? length : 34

    Keys.onPressed: event => {
        const step = event.modifiers & Qt.ShiftModifier ? 0.005 : 0.02;
        const up = event.key === Qt.Key_Up || event.key === Qt.Key_Right, down = event.key === Qt.Key_Down || event.key === Qt.Key_Left;
        if (!up && !down)
            return;
        const dir = (up ? 1 : -1) * (!root.horizontal && root.inverted ? -1 : 1);
        root.setParameter(control.parameter + dir * step);
        event.accepted = true;
    }

    Mixxx.ControlProxy {
        id: control

        group: root.group
        key: root.key
    }
    Repeater {
        model: root.ticks

        Rectangle {
            readonly property real at: (root.horizontal ? cap.width : cap.height) / 2 + root.travel * index / (root.ticks - 1)
            required property int index
            readonly property bool major: index === 0 || index === root.ticks - 1 || index * 2 === root.ticks - 1

            color: major ? Style.ink : Style.dim
            height: root.horizontal ? (major ? 6 : 4) : 1
            width: root.horizontal ? 1 : (major ? 7 : 4)
            x: root.horizontal ? at : 0
            y: root.horizontal ? 0 : at
        }
    }
    Rectangle {
        border.color: "#2a2a2a"
        border.width: 1
        color: "#000000"
        height: root.horizontal ? 4 : root.length
        width: root.horizontal ? root.length : 4
        x: root.horizontal ? 0 : 19
        y: root.horizontal ? 15 : 0
    }
    Rectangle {
        id: cap

        border.color: root.activeFocus ? Style.fg : "#4a4a4a"
        border.width: 1
        height: root.horizontal ? 22 : 26
        width: root.horizontal ? 26 : 22
        x: root.horizontal ? root.travel * root.pos : 10
        y: root.horizontal ? 6 : root.travel * root.pos

        gradient: Gradient {
            orientation: root.horizontal ? Gradient.Horizontal : Gradient.Vertical

            GradientStop {
                color: "#3a3a3a"
                position: 0
            }
            GradientStop {
                color: "#141414"
                position: 0.48
            }
            GradientStop {
                color: "#2c2c2c"
                position: 1
            }
        }

        Rectangle {
            anchors.centerIn: parent
            color: Style.fg
            height: root.horizontal ? parent.height - 4 : 2
            width: root.horizontal ? 2 : parent.width - 4
        }
    }
    MouseArea {
        property real grab: 0

        anchors.fill: parent
        anchors.margins: -4

        onDoubleClicked: control.reset()
        onPositionChanged: m => {
            if (!pressed)
                return;
            const at = (root.horizontal ? m.x : m.y) - 4 - grab;
            root.setFromPos(at / root.travel);
        }
        onPressed: m => {
            root.forceActiveFocus();
            const at = (root.horizontal ? m.x : m.y) - 4, capAt = root.travel * root.pos, size = root.horizontal ? cap.width : cap.height;
            // neben der Kappe geklickt: die Kappe springt hin
            if (at < capAt || at > capAt + size) {
                grab = size / 2;
                root.setFromPos((at - grab) / root.travel);
            } else {
                grab = at - capAt;
            }
        }
        onWheel: w => {
            const d = w.pixelDelta.y !== 0 ? w.pixelDelta.y / 600 : w.angleDelta.y / 120 * 0.02;
            root.setParameter(control.parameter + (!root.horizontal && root.inverted ? -d : d));
        }
    }
}
// [/AI-generated]
