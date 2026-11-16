// [AI-generated] This file was written by an AI agent (Claude, Anthropic).
import Mixxx 1.0 as Mixxx
import QtQuick
import "."

// DJBOX: oben die Bibliothek (Regal und Liste), darunter das Set aus Playern und Mixer.
// Die Grenze zwischen beiden lässt sich ziehen; das Set skaliert mit.
Item {
    id: root

    readonly property var allDecks: [
        {
            "group": "[Channel1]",
            "label": "A"
        },
        {
            "group": "[Channel2]",
            "label": "B"
        },
        {
            "group": "[Channel3]",
            "label": "C"
        },
        {
            "group": "[Channel4]",
            "label": "D"
        }
    ]
    property real boothShare: 0.58               // Anteil des Sets an der Höhe unter der Kopfzeile
    property int deckCount: 2
    readonly property var decks: allDecks.slice(0, deckCount)
    property int dragPick: 0
    property var dragRec: null
    readonly property alias library: library
    property bool setShown: true
    readonly property alias shelf: library.shelf
    property int stackRev: 0
    property var stacks: ({})                      // Gruppe → Platten auf dem Player, die oberste zuletzt

    signal preferencesRequested

    function deckAt(x, y) {
        for (let i = 0; i < players.count; i++) {
            const t = players.itemAt(i);
            if (!t)
                continue;
            const p = t.mapFromItem(root, x, y);
            if (p.x >= 0 && p.y >= 0 && p.x <= t.width && p.y <= t.height)
                return t.group;
        }
        return "";
    }
    function deckControls(group) {
        for (let i = 0; i < ejectors.count; i++) {
            const e = ejectors.itemAt(i);
            if (e && e.group === group)
                return e;
        }
        return null;
    }
    // Der Stapel weicht einer Platte, die von außen aufs Deck kam (Controller, Tastatur, Auto-DJ)
    function deckLoaded(group, url) {
        const st = stackOf(group);
        if (!url) {
            if (st.length)
                setStack(group, []);
            return;
        }
        const hit = shelf.urlIndex[url];
        if (hit && st.indexOf(hit.rec) >= 0) {
            if (st[st.length - 1] === hit.rec && hit.rec.pick !== hit.i) {
                hit.rec.pick = hit.i;
                setStack(group, st);
            }
            return;
        }
        if (hit)
            hit.rec.pick = hit.i;
        setStack(group, hit ? [hit.rec] : []);
    }
    // Die oberste Platte fliegt vom Teller; darunter liegt die nächste
    function dropTop(group) {
        const st = stackOf(group).slice();
        st.pop();
        setStack(group, st);
        deckControls(group).stop();
        if (st.length)
            loadPicked(group, st[st.length - 1], false);
        else
            deckControls(group).eject();
    }
    function loadPicked(group, rec, play) {
        const t = rec.tracks[rec.pick] || rec.tracks[0];
        Mixxx.PlayerManager.getPlayer(group).loadTrackFromLocationUrl(t.url, play);
    }
    // Platte auflegen. Steht das Deck, kommt sie obenauf und ihr gewählter Track wird geladen.
    // Läuft das Deck, schiebt sie sich unter die laufende Platte und ist nach DROP dran.
    function loadTo(rec, group) {
        if (!rec || !group)
            return;
        const st = stackOf(group), top = st[st.length - 1];
        if (top === rec) {
            pickTrack(group, rec.pick);
            return;
        }
        const rest = st.filter(r => r !== rec);
        if (deckControls(group).playing && rest.length) {
            rest.splice(rest.length - 1, 0, rec);
            setStack(group, rest);
            return;
        }
        rest.push(rec);
        setStack(group, rest);
        loadPicked(group, rec, false);
    }
    // Nadel umsetzen: anderer Track derselben Platte. Lief das Deck, läuft es weiter.
    function pickTrack(group, i) {
        const st = stackOf(group), top = st[st.length - 1];
        if (!top || i < 0 || i >= top.tracks.length)
            return;
        top.pick = i;
        setStack(group, st);
        shelf.selRev++;
        const c = deckControls(group), was = c.playing;
        c.stop();
        loadPicked(group, top, was);
    }
    function removeDeck() {
        if (deckCount <= 1)
            return;
        const g = allDecks[deckCount - 1].group;
        setStack(g, []);
        deckControls(g).stop();
        deckControls(g).eject();
        deckCount--;
    }
    function setStack(group, list) {
        const s = Object.assign({}, stacks);
        s[group] = list.slice();
        stacks = s;
        stackRev++;
    }
    function stackOf(group) {
        return stacks[group] || [];
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
            search.forceActiveFocus();
            event.accepted = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Style.bg
    }
    // Kopfzeile
    Rectangle {
        id: header

        color: "#070707"
        height: 44
        width: parent.width

        Rectangle {
            anchors.bottom: parent.bottom
            color: Style.line
            height: 1
            width: parent.width
        }
        Dots {
            anchors.verticalCenter: parent.verticalCenter
            size: 20
            text: "DJBOX"
            x: 16
        }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            x: 104

            Repeater {
                model: [["regal", "Regal"], ["beides", "Regal + Liste"], ["liste", "Liste"]]

                TextButton {
                    required property var modelData

                    checked: library.mode === modelData[0]
                    text: modelData[1]

                    onClicked: library.mode = modelData[0]
                }
            }
            Item {
                height: 1
                width: 14
            }
            Repeater {
                model: [["az", "A–Z"], ["genre", "Genre"], ["bpm", "BPM"], ["jahr", "Jahr"], ["neu", "Neu"], ["farbe", "Farbe"], ["zufall", "Stöbern"]]

                TextButton {
                    required property var modelData

                    checked: library.shelf.sortMode === modelData[0]
                    text: modelData[1]

                    onClicked: {
                        library.list.sortCol = "";
                        if (library.shelf.sortMode === modelData[0])
                            library.shelf.relayout();
                        else
                            library.shelf.sortMode = modelData[0];
                    }
                }
            }
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // Suche
            Rectangle {
                border.color: search.activeFocus ? Style.dim : Style.faint
                border.width: 1
                color: "transparent"
                height: 26
                width: 200

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: Style.dim
                    font.family: Style.sans
                    font.pixelSize: 12
                    text: "Suchen   ⌃F"
                    visible: search.text === "" && !search.activeFocus
                    x: 8
                }
                TextInput {
                    id: search

                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.right: clearSearch.left
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true
                    color: Style.fg
                    font.family: Style.sans
                    font.pixelSize: 12
                    selectByMouse: true
                    selectionColor: "#444444"

                    Keys.onEscapePressed: {
                        text = "";
                        library.shelf.forceActiveFocus();
                    }
                    Keys.onReturnPressed: {
                        if (library.mode === "regal")
                            library.shelf.forceActiveFocus();
                        else
                            library.list.forceActiveFocus();
                    }
                    onTextChanged: library.searchText = text
                }
                Text {
                    id: clearSearch

                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    color: Style.dim
                    font.family: Style.sans
                    font.pixelSize: 12
                    text: search.text ? "✕" : ""

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6

                        onClicked: search.text = ""
                    }
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: Style.dim
                font.family: Style.sans
                font.pixelSize: 12
                leftPadding: 6
                rightPadding: 6
                text: (library.searchText ? library.shelf.recordCount + " von " : "") + library.shelf.totalRecords.toLocaleString(Qt.locale("de_DE"), "f", 0) + " Platten  ·  " + library.shelf.trackCount.toLocaleString(Qt.locale("de_DE"), "f", 0) + " Tracks"
            }
            TextButton {
                enabled: root.deckCount < 4
                text: "+ Player"

                onClicked: {
                    root.deckCount++;
                    root.setShown = true;
                }
            }
            TextButton {
                checked: root.setShown
                text: "Set"

                onClicked: root.setShown = !root.setShown
            }
            TextButton {
                text: "Einstellungen"

                onClicked: root.preferencesRequested()
            }
        }
    }
    Library {
        id: library

        deckRecords: {
            root.stackRev;
            const m = {};
            for (const d of root.decks) {
                const st = root.stackOf(d.group);
                if (st.length)
                    m[d.group] = st[st.length - 1];
            }
            return m;
        }
        decks: root.decks
        height: (root.setShown ? split.y : root.height) - y
        width: parent.width
        y: header.height

        onDragEnded: (x, y) => {
            const p = mapToItem(root, x, y);
            const g = root.deckAt(p.x, p.y);
            if (g) {
                root.dragRec.pick = root.dragPick;
                root.loadTo(root.dragRec, g);
            }
            root.dragRec = null;
        }
        onDragMoved: (x, y) => {
            const p = mapToItem(root, x, y);
            ghost.x = p.x - ghost.width / 2;
            ghost.y = p.y - ghost.height / 2;
            ghost.over = root.deckAt(p.x, p.y);
        }
        onDragStarted: (id, pick) => {
            root.dragRec = library.shelf.records[id];
            root.dragPick = pick;
            root.setShown = true;
        }
        onLoadRequested: (id, pick, group) => {
            const rec = library.shelf.records[id];
            rec.pick = pick;
            root.loadTo(rec, group);
        }
        onPreferencesRequested: root.preferencesRequested()
    }
    // Die Bibliothek wurde neu eingelesen: die Stapel zeigen auf die neuen Platten
    Connections {
        function onReloaded() {
            const s = {};
            for (const g in root.stacks) {
                s[g] = root.stacks[g].map(r => {
                    const hit = library.shelf.urlIndex[r.tracks[r.pick].url];
                    if (hit)
                        hit.rec.pick = hit.i;
                    return hit ? hit.rec : null;
                }).filter(r => r !== null);
            }
            root.stacks = s;
            root.stackRev++;
        }

        target: library.shelf
    }
    // Griff zwischen Bibliothek und Set
    Rectangle {
        id: split

        color: splitArea.containsMouse || splitArea.pressed ? "#2a2a2a" : "#121212"
        height: 7
        visible: root.setShown
        width: parent.width
        y: Math.round(header.height + (root.height - header.height) * (1 - root.boothShare))

        Rectangle {
            anchors.centerIn: parent
            color: Style.dim
            height: 2
            radius: 1
            width: 40
        }
        MouseArea {
            id: splitArea

            anchors.fill: parent
            anchors.margins: -3
            cursorShape: Qt.SplitVCursor
            hoverEnabled: true

            onPositionChanged: m => {
                if (!pressed)
                    return;
                const y = split.y + m.y - 3, avail = root.height - header.height;
                root.boothShare = Math.max(0.2, Math.min(0.85, 1 - (y - header.height) / avail));
            }
        }
    }
    // Das Set
    Item {
        id: booth

        height: root.height - y
        visible: root.setShown
        width: parent.width
        y: split.y + split.height

        Item {
            id: rail

            readonly property int leftCount: Math.ceil(root.deckCount / 2)
            readonly property int playerW: 520 + 12

            // links C, A · Mixer · rechts B, D
            function deckX(i) {
                return i % 2 === 0 ? (leftCount - 1 - i / 2) * playerW : leftCount * playerW + mixer.width + 12 + (i - 1) / 2 * playerW;
            }

            height: 770
            scale: Math.max(0.2, Math.min((booth.width - 20) / width, (booth.height - 12) / height))
            transformOrigin: Item.Top
            width: root.deckCount * playerW + mixer.width
            x: (parent.width - width) / 2
            y: 6

            Repeater {
                id: players

                model: root.decks

                Player {
                    required property int index
                    required property var modelData

                    group: modelData.group
                    highlight: ghost.visible && ghost.over === modelData.group
                    label: modelData.label
                    removable: index === root.deckCount - 1 && root.deckCount > 1
                    rev: root.stackRev
                    stack: {
                        root.stackRev;
                        return root.stackOf(modelData.group);
                    }
                    x: rail.deckX(index)

                    onDropRequested: root.dropTop(group)
                    onLoadedUrlChanged: root.deckLoaded(group, loadedUrl)
                    onPickRequested: i => root.pickTrack(group, i)
                    onRemoveRequested: root.removeDeck()
                }
            }
            Mixer {
                id: mixer

                x: rail.leftCount * rail.playerW
            }
        }
    }
    // Die Platte in der Hand
    Item {
        id: ghost

        property string over: ""

        height: 120
        rotation: -4
        visible: root.dragRec !== null
        width: 120

        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            color: ghost.over ? Style.fg : Style.dim
        }
        CoverArt {
            anchors.fill: parent
            rec: root.dragRec
        }
        Rectangle {
            anchors.bottom: parent.bottom
            color: Qt.rgba(0, 0, 0, 0.8)
            height: 20
            visible: root.dragRec !== null && root.dragRec.tracks.length > 1
            width: parent.width

            Text {
                anchors.centerIn: parent
                color: Style.fg
                elide: Text.ElideRight
                font.family: Style.sansMedium
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
                text: root.dragRec && root.dragRec.tracks[root.dragPick] ? "Track " + root.dragRec.tracks[root.dragPick].pos + " · " + root.dragRec.tracks[root.dragPick].title : ""
                width: parent.width - 8
            }
        }
    }
    Repeater {
        id: ejectors

        model: root.allDecks

        Item {
            id: ejector

            readonly property string group: modelData.group
            required property var modelData
            readonly property bool playing: playControl.value > 0

            function eject() {
                ejectControl.trigger();
            }
            function stop() {
                playControl.value = 0;
            }

            Mixxx.ControlProxy {
                id: playControl

                group: ejector.group
                key: "play"
            }
            Mixxx.ControlProxy {
                id: ejectControl

                group: ejector.group
                key: "eject"
            }
        }
    }
}
// [/AI-generated]
