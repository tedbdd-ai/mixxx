// [AI-generated] This file was written by an AI agent (Claude, Anthropic).
import QtQuick
import "."

// Große runde Taste mit Leuchtring, wie PLAY und CUE am Player.
Item {
    id: root

    property bool blink: false
    property bool lit: false
    property color ringColor: Style.play
    property real size: 64
    property alias text: label.text

    signal pressStarted
    signal released

    height: size
    width: size

    Rectangle {
        id: ring

        anchors.fill: parent
        border.color: root.ringColor
        border.width: 3
        color: "transparent"
        opacity: root.lit ? (root.blink ? blinker.level : 1) : 0.28
        radius: width / 2
    }
    Rectangle {
        anchors.centerIn: parent
        border.color: "#3a3b3d"
        border.width: 1
        height: width
        radius: width / 2
        width: root.size - 12

        gradient: Gradient {
            GradientStop {
                color: area.pressed ? "#2a2b2d" : "#3a3b3e"
                position: 0
            }
            GradientStop {
                color: area.pressed ? "#121314" : "#18191b"
                position: 1
            }
        }

        Text {
            id: label

            anchors.centerIn: parent
            color: Style.ink
            font.family: Style.sansSemi
            font.pixelSize: root.size * 0.16
        }
    }
    QtObject {
        id: blinker

        property real level: 1
    }
    SequentialAnimation {
        loops: Animation.Infinite
        running: root.lit && root.blink

        onStopped: blinker.level = 1

        PropertyAction {
            property: "level"
            target: blinker
            value: 1
        }
        PauseAnimation {
            duration: 400
        }
        PropertyAction {
            property: "level"
            target: blinker
            value: 0.2
        }
        PauseAnimation {
            duration: 400
        }
    }
    MouseArea {
        id: area

        anchors.fill: parent

        onCanceled: root.released()
        onPressed: root.pressStarted()
        onReleased: root.released()
    }
}
// [/AI-generated]
