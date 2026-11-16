import QtQuick
import "."

// Schiebeschalter mit zwei bis vier Stellungen
Item {
    id: root

    property int index: 0
    property var labels: []
    property real step: 22

    signal moved(int index)

    activeFocusOnTab: true
    height: 26
    width: labels.length * step

    Keys.onLeftPressed: {
        if (index > 0)
            moved(index - 1);
    }
    Keys.onRightPressed: {
        if (index < labels.length - 1)
            moved(index + 1);
    }

    Repeater {
        model: root.labels

        Text {
            required property int index
            required property string modelData

            color: index === root.index ? Style.fg : Style.dim
            font.family: Style.sans
            font.pixelSize: 8
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            text: modelData
            width: root.step
            x: index * root.step
            y: 0
        }
    }
    Rectangle {
        border.color: root.activeFocus ? Style.fg : "#333333"
        border.width: 1
        color: "#000000"
        height: 12
        width: root.width - 6
        x: 3
        y: 13

        Rectangle {
            color: "#cfcfcf"
            height: 8
            width: Math.max(8, root.step - 12)
            x: 2 + (parent.width - 4 - width) * (root.labels.length > 1 ? root.index / (root.labels.length - 1) : 0)
            y: 2

            Behavior on x {
                NumberAnimation {
                    duration: 70
                }
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onPressed: m => {
            root.forceActiveFocus();
            root.moved(Math.max(0, Math.min(root.labels.length - 1, Math.floor(m.x / root.step))));
        }
    }
}
