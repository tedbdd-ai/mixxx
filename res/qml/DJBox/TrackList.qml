// [AI-generated] This file was written by an AI agent (Claude, Anthropic).
import QtQuick
import "."
import "ShelfLogic.mjs" as Logic

// Die Trackliste, wie man sie aus jedem DJ-Programm kennt. Standardmäßig in der Reihenfolge des Regals:
// Platte für Platte, Track für Track. Ein Klick auf eine Spalte sortiert nach ihr.
// Auswahl und Regal laufen gemeinsam: Wer hier einen Track wählt, zieht dort die Platte heraus.
Rectangle {
    id: root

    readonly property var columns: [
        {
            "key": "art",
            "label": "",
            "w": 30
        },
        {
            "key": "title",
            "label": "Titel",
            "flex": 3
        },
        {
            "key": "artist",
            "label": "Interpret",
            "flex": 2
        },
        {
            "key": "album",
            "label": "Platte",
            "flex": 2
        },
        {
            "key": "bpm",
            "label": "BPM",
            "w": 52,
            "right": true
        },
        {
            "key": "key",
            "label": "Tonart",
            "w": 50
        },
        {
            "key": "dur",
            "label": "Zeit",
            "w": 46,
            "right": true
        },
        {
            "key": "genre",
            "label": "Genre",
            "w": 92
        },
        {
            "key": "added",
            "label": "Neu",
            "w": 74
        }
    ]
    readonly property real flexUnit: {
        let fixed = 0, flex = 0;
        for (const c of columns) {
            if (c.w)
                fixed += c.w;
            else
                flex += c.flex;
        }
        return Math.max(0, (width - 12 - fixed) / flex);
    }
    property var lay: null
    property int layRev: 0
    property var rows: []
    property var selRec: null                    // die Platte, die im Regal heraus ist
    property int selRev: 0
    property string sortCol: ""                  // leer = Reihenfolge des Regals
    property bool sortDesc: false

    signal dragEnded(real x, real y)
    signal dragMoved(real x, real y)
    signal dragStarted(int id, int pick)
    signal loadRequested(int id, int pick)
    signal picked(int id, int pick)

    function cell(r, key) {
        switch (key) {
        case "title":
            return r.t.title;
        case "artist":
            return r.t.artist || r.rec.artist;
        case "album":
            return r.rec.single ? "" : r.rec.title;
        case "bpm":
            return r.t.bpm ? r.t.bpm.toFixed(1) : "";
        case "key":
            return r.t.key;
        case "dur":
            return r.t.dur ? Logic.fmtTime(r.t.dur) : "";
        case "genre":
            return r.rec.genre;
        case "added":
            return r.rec.added ? String(r.rec.added).slice(0, 10) : "";
        }
        return "";
    }
    function colWidth(c) {
        return c.w ? c.w : c.flex * flexUnit;
    }
    // die herausgezogene Platte in der Liste zeigen
    function follow() {
        if (!selRec)
            return;
        for (let i = 0; i < rows.length; i++) {
            if (rows[i].rec === selRec && rows[i].i === selRec.pick) {
                list.currentIndex = i;
                list.positionViewAtIndex(i, ListView.Contain);
                return;
            }
        }
    }
    function rebuild() {
        rows = lay ? Logic.sortRows(Logic.trackRows(lay.order), sortCol, sortDesc) : [];
        list.currentIndex = -1;
        follow();
    }
    function sortBy(key) {
        if (key === "art")
            return;
        if (sortCol === key) {
            if (sortDesc) {
                sortCol = "";
                sortDesc = false;
            } else {
                sortDesc = true;
            }
        } else {
            sortCol = key;
            sortDesc = false;
        }
        rebuild();
    }

    color: "#080808"

    onLayRevChanged: rebuild()
    onSelRevChanged: follow()

    // Kopfzeile
    Rectangle {
        id: header

        color: "#0d0d0d"
        height: 26
        width: parent.width

        Row {
            x: 6

            Repeater {
                model: root.columns

                Item {
                    required property var modelData

                    height: header.height
                    width: root.colWidth(modelData)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.sortCol === parent.modelData.key ? Style.fg : Style.dim
                        elide: Text.ElideRight
                        font.family: Style.sansMedium
                        font.letterSpacing: 0.4
                        font.pixelSize: 10
                        horizontalAlignment: parent.modelData.right ? Text.AlignRight : Text.AlignLeft
                        text: parent.modelData.label + (root.sortCol === parent.modelData.key ? (root.sortDesc ? "  ↓" : "  ↑") : "")
                        width: parent.width - 10
                        x: 4
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: parent.modelData.key === "art" ? Qt.ArrowCursor : Qt.PointingHandCursor

                        onClicked: root.sortBy(parent.modelData.key)
                    }
                }
            }
        }
        Rectangle {
            anchors.bottom: parent.bottom
            color: Style.line
            height: 1
            width: parent.width
        }
    }
    ListView {
        id: list

        activeFocusOnTab: true
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        currentIndex: -1
        highlightMoveDuration: 0
        model: root.rows
        reuseItems: true

        delegate: Rectangle {
            id: row

            required property int index
            readonly property bool isCurrent: ListView.isCurrentItem
            required property var modelData
            readonly property bool onSel: root.selRec !== null && modelData.rec === root.selRec

            color: isCurrent ? "#e8e8e8" : onSel ? "#1b1b1b" : index % 2 ? "#0b0b0b" : "#080808"
            height: 24
            width: list.width

            Row {
                x: 6

                Repeater {
                    model: root.columns

                    Item {
                        required property var modelData

                        height: row.height
                        width: root.colWidth(modelData)

                        // Plattenfarbe als Rücken, darüber das Cover, wenn es eins gibt
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            color: row.modelData.rec.tone
                            height: 18
                            visible: parent.modelData.key === "art"
                            width: 18
                            x: 4

                            Image {
                                anchors.fill: parent
                                asynchronous: true
                                cache: true
                                fillMode: Image.PreserveAspectCrop
                                source: parent.visible && row.modelData.rec.cover ? row.modelData.rec.cover : ""
                                sourceSize.height: 48
                                sourceSize.width: 48
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            color: {
                                const k = parent.modelData.key;
                                if (row.isCurrent)
                                    return "#000000";
                                if (k === "key" && row.modelData.t.key)
                                    return Logic.keyColor(row.modelData.t.key);
                                return k === "title" ? Style.fg : "#a8a8a8";
                            }
                            elide: Text.ElideRight
                            font.family: parent.modelData.key === "bpm" || parent.modelData.key === "dur" || parent.modelData.key === "added" ? Style.mono : (parent.modelData.key === "title" ? Style.sansMedium : Style.sans)
                            font.pixelSize: 12
                            horizontalAlignment: parent.modelData.right ? Text.AlignRight : Text.AlignLeft
                            text: parent.modelData.key === "art" ? "" : root.cell(row.modelData, parent.modelData.key)
                            width: parent.width - 10
                            x: 4
                        }
                    }
                }
            }
            MouseArea {
                property bool dragging: false
                property real px: 0
                property real py: 0

                anchors.fill: parent

                onDoubleClicked: root.loadRequested(row.modelData.rec.id, row.modelData.i)
                onPositionChanged: m => {
                    if (!pressed)
                        return;
                    const p = mapToItem(root, m.x, m.y);
                    if (!dragging && Math.hypot(m.x - px, m.y - py) > 8) {
                        dragging = true;
                        root.dragStarted(row.modelData.rec.id, row.modelData.i);
                    }
                    if (dragging)
                        root.dragMoved(p.x, p.y);
                }
                onPressed: m => {
                    list.forceActiveFocus();
                    px = m.x;
                    py = m.y;
                    dragging = false;
                    list.currentIndex = row.index;
                    root.picked(row.modelData.rec.id, row.modelData.i);
                }
                onReleased: m => {
                    if (dragging) {
                        const p = mapToItem(root, m.x, m.y);
                        dragging = false;
                        root.dragEnded(p.x, p.y);
                    }
                }
            }
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                const i = Math.max(0, Math.min(root.rows.length - 1, currentIndex + (event.key === Qt.Key_Down ? 1 : -1)));
                currentIndex = i;
                positionViewAtIndex(i, ListView.Contain);
                root.picked(root.rows[i].rec.id, root.rows[i].i);
            } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && currentIndex >= 0) {
                root.loadRequested(root.rows[currentIndex].rec.id, root.rows[currentIndex].i);
            } else {
                return;
            }
            event.accepted = true;
        }
    }
    // Rollbalken
    Rectangle {
        color: Style.dim
        height: Math.max(24, list.visibleArea.heightRatio * list.height)
        opacity: list.moving ? 0.8 : 0.35
        radius: 2
        visible: list.visibleArea.heightRatio < 1
        width: 4
        x: root.width - 6
        y: list.y + list.visibleArea.yPosition * list.height
    }
}
// [/AI-generated]
