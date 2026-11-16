import Mixxx 1.0 as Mixxx
import QtQuick
import "."
import "ShelfLogic.mjs" as Logic

// DJBOX: das Plattenregal füllt das Fenster, davor steht das Set aus Plattenspielern und Mixer.
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
    property int deckCount: 2
    // so, wie die Geräte stehen: links C, A · rechts B, D. In dieser Reihenfolge liegen auch die Kanalzüge.
    readonly property var deckOrder: decks.filter((d, i) => i % 2 === 0).reverse().concat(decks.filter((d, i) => i % 2 === 1))
    readonly property var decks: allDecks.slice(0, deckCount)
    readonly property real dockHeight: 488 * rail.scale + 14
    property var dragRec: null
    property bool setShown: true
    readonly property alias shelf: shelf
    property int stackRev: 0
    property var stacks: ({})                      // Gruppe → Platten auf dem Teller, die oberste zuletzt

    signal preferencesRequested

    function deckAt(x, y) {
        for (let i = 0; i < turntables.count; i++) {
            const t = turntables.itemAt(i);
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

    Shelf {
        id: shelf

        anchors.fill: parent
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
        visibleBottom: root.setShown ? root.height - root.dockHeight : root.height

        onDragEnded: (x, y) => {
            const g = root.deckAt(x, y);
            if (g)
                root.loadTo(root.dragRec, g);
            root.dragRec = null;
        }
        onDragMoved: (x, y) => {
            ghost.x = x - ghost.width / 2;
            ghost.y = y - ghost.height / 2;
            ghost.over = root.deckAt(x, y);
        }
        onDragStarted: id => {
            root.dragRec = shelf.records[id];
            root.setShown = true;
        }
        onLoadRequested: (id, group) => root.loadTo(shelf.records[id], group)
        onPreferencesRequested: root.preferencesRequested()
        // Die Bibliothek wurde neu eingelesen: die Stapel zeigen auf die neuen Platten
        onReloaded: {
            const s = {};
            for (const g in root.stacks) {
                s[g] = root.stacks[g].map(r => {
                    const hit = shelf.urlIndex[r.tracks[r.pick].url];
                    if (hit)
                        hit.rec.pick = hit.i;
                    return hit ? hit.rec : null;
                }).filter(r => r !== null);
            }
            root.stacks = s;
            root.stackRev++;
        }
    }
    // Kopfzeile
    Rectangle {
        color: Qt.rgba(0.02, 0.02, 0.02, 0.92)
        height: 40
        width: parent.width

        Rectangle {
            anchors.bottom: parent.bottom
            color: Style.line
            height: 1
            width: parent.width
        }
        DotText {
            anchors.verticalCenter: parent.verticalCenter
            dot: 2.5
            text: "DJBOX"
            x: 18
        }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            x: 112

            Repeater {
                model: [["az", "A–Z"], ["genre", "Genre"], ["bpm", "BPM"], ["jahr", "Jahr"], ["neu", "Neu"], ["farbe", "Farbe"], ["zufall", "Stöbern"]]

                TextButton {
                    required property var modelData

                    checked: shelf.sortMode === modelData[0]
                    text: modelData[1]

                    onClicked: {
                        if (shelf.sortMode === modelData[0])
                            shelf.relayout();
                        else
                            shelf.sortMode = modelData[0];
                    }
                }
            }
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: Style.dim
                font.family: Style.sans
                font.pixelSize: 12
                rightPadding: 10
                text: shelf.recordCount.toLocaleString(Qt.locale("de_DE"), "f", 0) + " Platten  ·  " + shelf.trackCount.toLocaleString(Qt.locale("de_DE"), "f", 0) + " Tracks"
            }
            TextButton {
                enabled: root.deckCount < 4
                text: "+ Deck"

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
    // Das Set
    Item {
        id: dock

        height: root.dockHeight
        width: parent.width
        y: root.setShown ? root.height - height : root.height

        Behavior on y {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent

            gradient: Gradient {
                GradientStop {
                    color: Qt.rgba(0, 0, 0, 0)
                    position: 0
                }
                GradientStop {
                    color: Qt.rgba(0, 0, 0, 0.85)
                    position: 0.12
                }
                GradientStop {
                    color: "#000000"
                    position: 1
                }
            }
        }
        MouseArea {
            anchors.fill: parent     // Klicks zwischen den Geräten gehen nicht ans Regal
            hoverEnabled: true
        }
        Item {
            id: rail

            readonly property int leftCount: Math.ceil(root.deckCount / 2)

            // links C, A · Mixer · rechts B, D
            function deckX(i) {
                return i % 2 === 0 ? (leftCount - 1 - i / 2) * 634 : leftCount * 634 + mixer.width + 14 + (i - 1) / 2 * 634;
            }

            height: 488
            scale: Math.max(0.5, Math.min(1, (root.width - 28) / width))
            transformOrigin: Item.Bottom
            width: root.deckCount * 634 + mixer.width
            x: (parent.width - width) / 2
            y: parent.height - height - 6

            Repeater {
                id: turntables

                model: root.decks

                Turntable {
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
            MixerPanel {
                id: mixer

                decks: root.deckOrder
                x: rail.leftCount * 634
            }
        }
    }
    // Die Platte in der Hand
    Item {
        id: ghost

        property string over: ""

        height: 132
        rotation: -4
        visible: root.dragRec !== null
        width: 132

        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            color: ghost.over ? Style.fg : Style.dim
        }
        CoverArt {
            anchors.fill: parent
            rec: root.dragRec
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
