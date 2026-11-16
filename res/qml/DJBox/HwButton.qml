// [AI-generated] This file was written by an AI agent (Claude, Anthropic).
import QtQuick
import "."

// Gerätetaste: dunkel, beschriftet, leuchtet in ihrer Farbe, wenn sie aktiv ist.
Rectangle {
    id: root

    property bool lit: false
    property color litColor: Style.fg
    property real litLevel: lit ? 1 : 0
    readonly property bool pressed: area.pressed
    property alias text: label.text
    property real textSize: 8

    signal clicked
    signal pressStarted
    signal released

    activeFocusOnTab: true
    border.color: root.litLevel > 0 ? Qt.rgba(root.litColor.r, root.litColor.g, root.litColor.b, 0.35 + 0.65 * root.litLevel) : root.activeFocus ? Style.dim : "#3a3b3d"
    border.width: root.litLevel > 0 ? 1.5 : 1
    color: area.pressed ? "#2b2c2e" : root.litLevel > 0 ? Qt.rgba(root.litColor.r * 0.22, root.litColor.g * 0.22, root.litColor.b * 0.22, 1) : "#1a1b1d"
    height: 24
    opacity: enabled ? 1 : 0.4
    radius: 3
    width: 52

    Keys.onReturnPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()

    Text {
        id: label

        anchors.centerIn: parent
        color: root.litLevel > 0 ? root.litColor : Style.ink
        font.family: Style.sansSemi
        font.letterSpacing: 0.4
        font.pixelSize: root.textSize
    }
    MouseArea {
        id: area

        anchors.fill: parent

        onCanceled: root.released()
        onClicked: root.clicked()
        onPressed: root.pressStarted()
        onReleased: root.released()
    }
}
// [/AI-generated]
