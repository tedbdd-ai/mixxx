// [AI-generated] This file was written by an AI agent (Claude, Anthropic).
import QtQuick
import "."
import "ShelfLogic.mjs" as Logic

// Die Karte neben der herausgezogenen Platte: alle Angaben, die Tracklist zum Auswählen
// und die Knöpfe, mit denen der gewählte Track auf ein Deck geht.
Rectangle {
    id: root

    property var decks: []
    readonly property int pick: {
        rev;
        return rec ? rec.pick : 0;
    }
    property bool pinned: false
    property var rec: null
    property int rev: 0
    readonly property var track: rec ? rec.tracks[pick] : null

    signal load(string group)
    signal picked(int i)
    signal putBack

    border.color: Style.faint
    border.width: 1
    color: "#0a0a0a"
    height: column.implicitHeight + 28

    MouseArea {
        anchors.fill: parent          // Klicks auf die Karte gehen nicht ans Regal durch
        hoverEnabled: true
    }
    Column {
        id: column

        anchors.left: parent.left
        anchors.margins: 14
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 0

        Text {
            color: Style.dim
            elide: Text.ElideRight
            font.family: Style.sans
            font.pixelSize: 12
            text: root.rec ? root.rec.artist : ""
            width: parent.width
        }
        Text {
            color: Style.fg
            elide: Text.ElideRight
            font.family: Style.sansSemi
            font.pixelSize: 19
            text: root.rec ? root.rec.title : ""
            topPadding: 1
            width: parent.width
        }
        Text {
            color: Style.dim
            elide: Text.ElideRight
            font.family: Style.sans
            font.pixelSize: 12
            text: {
                if (!root.rec)
                    return "";
                const r = root.rec, n = r.tracks.length, parts = [];
                if (r.genre)
                    parts.push(r.genre);
                if (r.year)
                    parts.push(String(r.year));
                parts.push(n === 1 ? "1 Track" : n + " Tracks");
                parts.push(Logic.fmtTime(r.dur));
                return parts.join("  ·  ");
            }
            topPadding: 4
            width: parent.width
        }
        Item {
            height: 12
            width: 1
        }
        Row {
            spacing: 18

            Column {
                spacing: 5

                Text {
                    color: Style.dim
                    font.family: Style.sans
                    font.letterSpacing: 0.6
                    font.pixelSize: 9
                    text: "BPM"
                }
                Dots {
                    size: 22
                    text: root.track && root.track.bpm ? root.track.bpm.toFixed(1) : "---.-"
                }
            }
            Column {
                spacing: 5

                Text {
                    color: Style.dim
                    font.family: Style.sans
                    font.letterSpacing: 0.6
                    font.pixelSize: 9
                    text: "TONART"
                }
                Dots {
                    color: root.track && root.track.key ? Logic.keyColor(root.track.key) : Style.faint
                    size: 22
                    text: root.track && root.track.key ? root.track.key.slice(0, 4) : "--"
                }
            }
            Column {
                spacing: 5

                Text {
                    color: Style.dim
                    font.family: Style.sans
                    font.letterSpacing: 0.6
                    font.pixelSize: 9
                    text: "LÄNGE"
                }
                Dots {
                    size: 22
                    text: root.track ? Logic.fmtTime(root.track.dur) : "-:--"
                }
            }
        }
        Item {
            height: 12
            width: 1
        }
        Rectangle {
            color: Style.line
            height: 1
            width: parent.width
        }
        // Tracklist. Mehr als acht Tracks rollen.
        ListView {
            id: list

            boundsBehavior: Flickable.StopAtBounds
            clip: true
            currentIndex: root.pick
            height: Math.min(count, 8) * 24
            interactive: count > 8
            model: root.rec ? root.rec.tracks : []
            width: parent.width

            delegate: Rectangle {
                id: row

                required property int index
                readonly property bool isPick: index === root.pick
                required property var modelData

                color: isPick ? Style.fg : rowArea.containsMouse && root.pinned ? "#161616" : "transparent"
                height: 24
                width: list.width

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: row.isPick ? "#000000" : Style.dim
                    font.family: Style.mono
                    font.pixelSize: 11
                    text: row.modelData.pos
                    x: 6
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: row.isPick ? "#000000" : Style.fg
                    elide: Text.ElideRight
                    font.family: Style.sans
                    font.pixelSize: 12
                    text: row.modelData.title + (root.rec && row.modelData.artist && row.modelData.artist !== root.rec.artist ? "  –  " + row.modelData.artist : "")
                    width: parent.width - 34 - 150
                    x: 34
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: row.isPick ? "#000000" : Style.dim
                    font.family: Style.mono
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignRight
                    text: (row.modelData.bpm ? row.modelData.bpm.toFixed(1) : "–") + "   " + (row.modelData.key || "–").slice(0, 4).padEnd(4, " ") + "  " + Logic.fmtTime(row.modelData.dur).padStart(5, " ")
                    width: 146
                    x: parent.width - 152
                }
                MouseArea {
                    id: rowArea

                    anchors.fill: parent
                    cursorShape: root.pinned ? Qt.PointingHandCursor : Qt.ArrowCursor
                    hoverEnabled: true

                    onClicked: root.picked(row.index)
                    onDoubleClicked: {
                        root.picked(row.index);
                        if (root.decks.length)
                            root.load(root.decks[0].group);
                    }
                }
            }
        }
        Rectangle {
            color: Style.line
            height: 1
            width: parent.width
        }
        Item {
            height: 12
            width: 1
        }
        Text {
            color: Style.dim
            font.family: Style.sans
            font.pixelSize: 11
            text: "Klick hält die Platte fest: Track wählen und auflegen. Ziehen trägt sie zum Deck."
            visible: !root.pinned
            width: parent.width
            wrapMode: Text.WordWrap
        }
        Flow {
            spacing: 6
            visible: root.pinned
            width: parent.width

            Repeater {
                model: root.decks

                TextButton {
                    required property var modelData

                    strong: true
                    text: (root.rec && root.rec.tracks.length > 1 && root.track ? "Track " + root.track.pos + " auf " : "Auf ") + modelData.label

                    onClicked: root.load(modelData.group)
                }
            }
            TextButton {
                text: "Zurück ins Regal"

                onClicked: root.putBack()
            }
        }
    }
}
// [/AI-generated]
