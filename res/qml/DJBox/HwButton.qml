import QtQuick
import "."

// Gerätetaste: dunkel, mit Leuchtkante, wenn sie aktiv ist
Rectangle {
    id: root

    property bool lit: false
    property color litColor: Style.fg
    readonly property bool pressed: area.pressed
    property alias text: label.text

    signal clicked
    signal pressStarted
    signal released

    activeFocusOnTab: true
    border.color: root.lit ? root.litColor : root.activeFocus ? Style.dim : "#3a3a3a"
    border.width: 1
    color: area.pressed ? "#262626" : "#121212"
    height: 30
    opacity: enabled ? 1 : 0.4
    width: 70

    Keys.onReturnPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()

    Text {
        id: label

        anchors.centerIn: parent
        color: root.lit ? root.litColor : Style.ink
        font.family: Style.sans
        font.letterSpacing: 0.6
        font.pixelSize: 9
        font.weight: Font.DemiBold
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
