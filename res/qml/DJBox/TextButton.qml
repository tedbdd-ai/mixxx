import QtQuick
import "."

// Flacher Knopf in der Kopfzeile und auf der Karte
Rectangle {
    id: root

    property bool checkable: false
    property bool checked: false
    property bool strong: false
    property alias text: label.text

    signal clicked

    activeFocusOnTab: true
    border.color: root.checked || root.strong ? Style.fg : area.containsMouse || root.activeFocus ? Style.dim : Style.faint
    border.width: 1
    color: root.checked ? Style.fg : area.pressed ? "#1c1c1c" : "transparent"
    height: 26
    implicitWidth: label.implicitWidth + 20
    opacity: enabled ? 1 : 0.35
    width: implicitWidth

    Keys.onReturnPressed: area.clicked(null)
    Keys.onSpacePressed: area.clicked(null)

    Text {
        id: label

        anchors.centerIn: parent
        color: root.checked ? "#000000" : Style.fg
        font.family: Style.sans
        font.pixelSize: 12
        font.weight: Font.Medium
    }
    MouseArea {
        id: area

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: {
            if (root.checkable)
                root.checked = !root.checked;
            root.clicked();
        }
    }
}
