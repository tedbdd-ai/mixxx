// [AI-generated] This file was written by an AI agent (Claude, Anthropic).
import Mixxx 1.0 as Mixxx
import QtQuick
import "."

// Drehregler am Gerät, an einen Mixxx-Regler gebunden.
// Ziehen hoch/runter dreht (Umschalt = fein), Scrollen in kleinen Schritten, Doppelklick = Grundstellung.
// Alles aus Rechtecken: kein Zeichnen zur Laufzeit.
Item {
    id: root

    property color capColor: "#2a2b2d"
    property bool center: true                 // Raste in der Mitte
    required property string group
    property string hi: ""
    required property string key
    property string label: ""
    property bool labelAbove: false
    property string lo: ""
    readonly property real parameter: control.parameter
    property real radius: 14

    function setParameter(p) {
        p = Math.max(0, Math.min(1, p));
        if (center && Math.abs(p - 0.5) < 0.012)
            p = 0.5;
        control.parameter = p;
    }

    activeFocusOnTab: true
    height: dial.height + (label !== "" ? 14 : 0)
    width: Math.max(dial.width + 16, labelText.implicitWidth)

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
    Text {
        id: labelText

        anchors.horizontalCenter: parent.horizontalCenter
        color: Style.ink
        font.capitalization: Font.AllUppercase
        font.family: Style.sansMedium
        font.letterSpacing: 0.4
        font.pixelSize: 8
        text: root.label
        y: root.labelAbove ? 0 : dial.y + dial.height + 2
    }
    Item {
        id: dial

        anchors.horizontalCenter: parent.horizontalCenter
        height: width
        width: root.radius * 2 + 12
        y: root.labelAbove && root.label !== "" ? 12 : 0

        // Skala
        Repeater {
            model: 11

            Rectangle {
                readonly property bool big: index === 0 || index === 5 || index === 10
                required property int index

                antialiasing: true
                color: big ? Style.ink : "#6b6b6b"
                height: big ? 4 : 3
                rotation: -135 + index * 27
                transformOrigin: Item.Bottom
                width: 1
                x: dial.width / 2 - 0.5
                y: dial.height / 2 - (root.radius + 2) - height
            }
        }
        Text {
            color: Style.dim
            font.family: Style.sans
            font.pixelSize: 6
            text: root.lo
            x: -2
            y: dial.height - 7
        }
        Text {
            color: Style.dim
            font.family: Style.sans
            font.pixelSize: 6
            horizontalAlignment: Text.AlignRight
            text: root.hi
            width: 12
            x: dial.width - 10
            y: dial.height - 7
        }
        // Regelkappe
        Rectangle {
            anchors.centerIn: parent
            border.color: root.activeFocus ? Style.fg : "#3c3d40"
            border.width: 1
            color: "#0e0e0f"
            height: width
            radius: width / 2
            width: root.radius * 2

            Rectangle {
                anchors.centerIn: parent
                height: width
                radius: width / 2
                width: parent.width - 6

                gradient: Gradient {
                    GradientStop {
                        color: Qt.lighter(root.capColor, 1.35)
                        position: 0
                    }
                    GradientStop {
                        color: root.capColor
                        position: 0.55
                    }
                    GradientStop {
                        color: Qt.darker(root.capColor, 1.5)
                        position: 1
                    }
                }
            }
            Item {
                anchors.fill: parent
                rotation: -135 + 270 * control.parameter

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    antialiasing: true
                    color: "#f2f2f2"
                    height: root.radius * 0.8
                    radius: 1
                    width: 2
                    y: 2
                }
            }
        }
        MouseArea {
            property real p0: 0
            property real y0: 0

            anchors.fill: parent
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
}
// [/AI-generated]
