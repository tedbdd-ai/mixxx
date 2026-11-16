// [AI-generated] This file was written by an AI agent (Claude, Anthropic).
import QtQuick
import "."

// Die Bibliothek: Regal und Liste nebeneinander, oder eins von beiden.
// Beide zeigen dieselbe Sammlung in derselben Reihenfolge, Suche und Auswahl gelten für beide.
Item {
    id: root

    property var deckRecords: ({})
    property var decks: []
    readonly property alias list: list
    property string mode: "beides"               // "regal", "liste" oder "beides"
    property string searchText: ""
    readonly property alias shelf: shelf

    signal dragEnded(real x, real y)
    signal dragMoved(real x, real y)
    signal dragStarted(int id, int pick)
    signal loadRequested(int id, int pick, string group)
    signal preferencesRequested

    Shelf {
        id: shelf

        deckRecords: root.deckRecords
        decks: root.decks
        filterText: root.searchText
        height: parent.height
        visible: root.mode !== "liste"
        width: root.mode === "beides" ? Math.round(parent.width * 0.56) : parent.width

        onDragEnded: (x, y) => {
            const p = mapToItem(root, x, y);
            root.dragEnded(p.x, p.y);
        }
        onDragMoved: (x, y) => {
            const p = mapToItem(root, x, y);
            root.dragMoved(p.x, p.y);
        }
        onDragStarted: (id, pick) => root.dragStarted(id, pick)
        onLoadRequested: (id, group) => root.loadRequested(id, shelf.records[id].pick, group)
        onPreferencesRequested: root.preferencesRequested()
    }
    Rectangle {
        color: Style.line
        height: parent.height
        visible: root.mode === "beides"
        width: 1
        x: shelf.width
    }
    TrackList {
        id: list

        height: parent.height
        lay: shelf.lay
        layRev: shelf.layRev
        selRec: shelf.sel
        selRev: shelf.selRev
        visible: root.mode !== "regal"
        width: root.mode === "beides" ? parent.width - shelf.width - 1 : parent.width
        x: root.mode === "beides" ? shelf.width + 1 : 0

        onDragEnded: (x, y) => {
            const p = mapToItem(root, x, y);
            root.dragEnded(p.x, p.y);
        }
        onDragMoved: (x, y) => {
            const p = mapToItem(root, x, y);
            root.dragMoved(p.x, p.y);
        }
        onDragStarted: (id, pick) => root.dragStarted(id, pick)
        onLoadRequested: (id, pick) => root.loadRequested(id, pick, root.decks.length ? root.decks[0].group : "")
        // Track in der Liste gewählt: im Regal kommt die Platte heraus, mit diesem Track ausgewählt
        onPicked: (id, pick) => {
            const rec = shelf.records[id];
            rec.pick = pick;
            if (shelf.visible && shelf.sel !== rec)
                shelf.nav(rec);
            else
                shelf.select(rec);
            shelf.selRev++;
        }
    }
}
// [/AI-generated]
