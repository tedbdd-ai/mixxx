import Mixxx 1.0 as Mixxx
import QtQuick
import "."

// Drehregler, an einen Mixxx-Regler gebunden.
// Ziehen hoch/runter dreht, Umschalt = fein, Scrollen = kleine Schritte, Doppelklick = Grundstellung.
Item {
    id: root

    property bool center: true                 // Raste in der Mitte
    required property string group
    property string hi: ""
    required property string key
    property string label: ""
    property string lo: ""
    readonly property real parameter: control.parameter
    property real radius: 14
    property bool silver: false

    function setParameter(p) {
        p = Math.max(0, Math.min(1, p));
        if (center && Math.abs(p - 0.5) < 0.012)
            p = 0.5;
        control.parameter = p;
    }

    activeFocusOnTab: true
    height: radius * 2 + (label !== "" ? 26 : 12)
    width: radius * 2 + 28

    Keys.onPressed: event => {
        const step = event.modifiers & Qt.ShiftModifier ? 0.005 : 0.02;
        if (event.key === Qt.Key_Up || event.key === Qt.Key_Right)
            root.setParameter(control.parameter + step);
        else if (event.key === Qt.Key_Down || event.key === Qt.Key_Left)
            root.setParameter(control.parameter - step);
        else if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace)
            control.reset();
        else
            return;
        event.accepted = true;
    }

    Mixxx.ControlProxy {
        id: control

        group: root.group
        key: root.key
    }
    Canvas {
        id: dial

        anchors.horizontalCenter: parent.horizontalCenter
        height: width
        width: root.radius * 2 + 12
        y: 0

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const c = width / 2;
            ctx.strokeStyle = Style.dim;
            for (let i = 0; i <= 10; i++) {
                const a = (-225 + i * 27) * Math.PI / 180, big = i === 0 || i === 5 || i === 10;
                ctx.lineWidth = big ? 1.2 : 0.7;
                ctx.beginPath();
                ctx.moveTo(c + Math.cos(a) * (root.radius + 2.5), c + Math.sin(a) * (root.radius + 2.5));
                ctx.lineTo(c + Math.cos(a) * (root.radius + (big ? 6 : 4.5)), c + Math.sin(a) * (root.radius + (big ? 6 : 4.5)));
                ctx.stroke();
            }
        }
    }
    Rectangle {
        id: body

        anchors.centerIn: dial
        border.color: root.activeFocus ? Style.fg : root.silver ? "#e6e6e6" : "#3b3b3b"
        border.width: 1
        height: width
        radius: width / 2
        rotation: -135 + 270 * control.parameter
        width: root.radius * 2

        gradient: Gradient {
            GradientStop {
                color: root.silver ? "#d9d9d9" : "#2a2a2a"
                position: 0
            }
            GradientStop {
                color: root.silver ? "#8c8c8c" : "#101010"
                position: 1
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.silver ? "#101010" : Style.fg
            height: root.radius * 0.72
            width: 2
            y: 2
        }
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        color: Style.ink
        font.capitalization: Font.AllUppercase
        font.family: Style.sans
        font.letterSpacing: 0.5
        font.pixelSize: 9
        font.weight: Font.Medium
        text: root.label
        y: dial.height + 1
    }
    Text {
        color: Style.dim
        font.family: Style.sans
        font.pixelSize: 7
        horizontalAlignment: Text.AlignRight
        text: root.lo
        width: 20
        x: dial.x - 17
        y: dial.height - 9
    }
    Text {
        color: Style.dim
        font.family: Style.sans
        font.pixelSize: 7
        text: root.hi
        x: dial.x + dial.width - 3
        y: dial.height - 9
    }
    MouseArea {
        property real p0: 0
        property real y0: 0

        anchors.fill: dial
        cursorShape: Qt.SizeVerCursor

        onDoubleClicked: control.reset()
        onPositionChanged: m => {
            if (pressed)
                root.setParameter(p0 + (y0 - m.y) / (m.modifiers & Qt.ShiftModifier ? 900 : 180));
        }
        onPressed: m => {
            root.forceActiveFocus();
            y0 = m.y;
            p0 = control.parameter;
        }
        onWheel: w => {
            const d = w.pixelDelta.y !== 0 ? w.pixelDelta.y / 600 : w.angleDelta.y / 120 * 0.02;
            root.setParameter(control.parameter + d);
        }
    }
}
