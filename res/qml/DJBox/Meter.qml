// [AI-generated] This file was written by an AI agent (Claude, Anthropic).
import Mixxx 1.0 as Mixxx
import QtQuick
import "."

// Pegelanzeige aus Leuchtpunkten: grün, oben orange, ganz oben rot.
// Nur Rechtecke, die ihre Farbe wechseln: billig, auch wenn der Pegel 60-mal pro Sekunde kommt.
Column {
    id: root

    property real dot: 6
    property real gap: 2
    required property string group
    required property string key
    readonly property int lit: Math.round(Math.max(0, Math.min(1, control.value)) * segments)
    property int segments: 15

    spacing: gap

    Mixxx.ControlProxy {
        id: control

        group: root.group
        key: root.key
    }
    Repeater {
        model: root.segments

        Rectangle {
            readonly property int fromBottom: root.segments - 1 - index
            required property int index
            readonly property bool on: fromBottom < root.lit

            color: !on ? "#1d1e1f" : fromBottom >= root.segments - 2 ? Style.ledRed : fromBottom >= root.segments - 5 ? Style.ledAmber : Style.ledGreen
            height: root.dot * 0.62
            radius: 1
            width: root.dot
        }
    }
}
// [/AI-generated]
