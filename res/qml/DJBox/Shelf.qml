// [AI-generated] This file was written by an AI agent (Claude, Anthropic).
import QtQuick
import "."
import "ShelfLogic.mjs" as Logic

// Das Plattenregal: die Mixxx-Bibliothek als Wand voller Platten.
// Schweben zieht eine Platte heraus, Scrollen blättert (links/rechts) und wechselt die Reihe (hoch/runter),
// ein Klick hält die Platte fest, Ziehen trägt sie zu einem Deck.
// Die Wand besteht aus Rechtecken (keine Canvas): scharf auf Retina-Displays, und es wird nur
// gebaut, was gerade zu sehen ist.
Item {
    id: root

    readonly property int cardWidth: 430
    property var deckRecords: ({})                  // Gruppe → Platte, die gerade auf dem Deck liegt
    property var decks: []                          // [{ group: "[Channel1]", label: "A" }]
    property string filterText: ""
    property var lay: null
    property int layRev: 0
    readonly property alias librarySource: source
    readonly property real maxPanX: lay ? Math.max(0, lay.width - width) : 0
    readonly property real maxPanY: lay ? Math.max(0, lay.height - height) : 0
    property bool navMode: false                    // Auswahl kam vom Scrollen oder aus der Liste; der Zeiger ruht
    property point navPt
    property real panX: 0
    property real panY: 0
    property real pinO: pinned && sel ? 1 : 0
    property bool pinned: false
    readonly property int recordCount: lay ? lay.count : 0
    property var records: []
    property var sel: null                          // die herausgezogene Platte
    property int selRev: 0
    property string sortMode: "az"
    property int totalRecords: records.length
    property int trackCount: 0
    property var urlIndex: ({})                     // Datei → { rec, i }
    property real wallX: panX
    property real wallY: panY

    // Platten gehen als Nummer (Index in records) durch Signale: als Objekt kämen sie als Kopie an
    signal dragEnded(real x, real y)
    signal dragMoved(real x, real y)
    signal dragStarted(int id, int pick)
    signal loadRequested(int id, string group)
    signal preferencesRequested
    signal reloaded

    function clearSel() {
        sel = null;
        pinned = false;
        navMode = false;
    }
    function ensureVisible() {
        if (!sel || sel.f < 0)
            return;
        const sx = sel.tx - panX;
        if (sx > width * 0.52)
            setPan(panX + sx - width * 0.52, panY);
        else if (sx < 150)
            setPan(panX + sx - 150, panY);
        const top = Logic.Y0 + (sel.f % Logic.ROWS) * Logic.FW, bot = top + Logic.FW + 26;
        let y = panY;
        if (bot - y > height)
            y = bot - height;
        if (top - y < 8)
            y = top - 8;
        setPan(panX, y);
    }
    function firstVisible() {
        if (!lay)
            return null;
        for (const fa of lay.fachs) {
            if (fa.recs.length && Logic.fachX(fa.f) + Logic.IN - panX >= 0 && Logic.fachYB(fa.f) - panY <= height)
                return fa.recs[0];
        }
        return null;
    }
    function hit(x, y) {
        if (!lay)
            return null;
        const wx = x + wallX, wy = y + wallY;
        const col = Math.floor((wx - Logic.X0) / Logic.FW), row = Math.floor((wy - Logic.Y0) / Logic.FW);
        if (col < 0 || col >= lay.cols || row < 0 || row >= Logic.ROWS)
            return null;
        const fa = lay.fachs[col * Logic.ROWS + row];
        let best = null, bd = 1e9;
        for (const r of fa.recs) {
            const d = Math.abs(r.tx + 1.5 - wx);
            if (d < bd) {
                bd = d;
                best = r;
            }
        }
        return best ? {
            "rec": best,
            "d": bd
        } : null;
    }
    function hitRec(x, y) {
        const h = hit(x, y);
        return h && h.d < 6 ? h.rec : null;
    }
    function nav(rec) {
        if (!rec || rec.f < 0)
            return;
        select(rec);
        navMode = true;
        navPt = Qt.point(mouse.mouseX, mouse.mouseY);
        ensureVisible();
    }
    function pin(v) {
        if (!sel)
            return;
        pinned = v;
        if (v)
            ensureVisible();
    }
    function relayout() {
        clearSel();
        for (const r of records)
            r.f = -1;
        const shown = filterText ? records.filter(r => Logic.matches(r, filterText)) : records;
        lay = Logic.layout(shown, sortMode, Math.ceil(width / Logic.FW) + 1);
        console.info("DJBOX shelf:", lay.summary);
        layRev++;
        setPan(panX, panY);
    }
    // Bibliothek aus der Quelle lesen und zu Platten zusammenfassen
    function reload() {
        const rows = source.rows();
        // die herausgezogene Platte übersteht das Neueinlesen
        const keepUrl = sel ? sel.tracks[sel.pick].url : "", keepPinned = pinned;
        trackCount = rows.length;
        const recs = Logic.buildRecords(rows);
        const idx = {};
        for (const rec of recs) {
            rec.tracks.forEach((t, i) => {
                idx[t.url] = {
                    "rec": rec,
                    "i": i
                };
            });
        }
        records = recs;
        urlIndex = idx;
        relayout();
        const keep = keepUrl ? idx[keepUrl] : null;
        if (keep && keep.rec.f >= 0) {
            keep.rec.pick = keep.i;
            select(keep.rec);
            pinned = keepPinned;
            navMode = true;
            navPt = Qt.point(mouse.mouseX, mouse.mouseY);
        }
        reloaded();
    }
    function rowSel(d) {
        if (!sel) {
            nav(firstVisible());
            return;
        }
        const row = sel.f % Logic.ROWS + d;
        if (row < 0 || row >= Logic.ROWS)
            return;
        let best = null, bd = 1e9;
        for (const fa of lay.fachs) {
            if (fa.f % Logic.ROWS !== row)
                continue;
            for (const r of fa.recs) {
                const dd = Math.abs(r.tx - sel.tx);
                if (dd < bd) {
                    bd = dd;
                    best = r;
                }
            }
        }
        nav(best);
    }
    function select(rec) {
        if (rec === sel)
            return;
        sel = rec;
        selRev++;
    }
    function setPan(x, y) {
        panX = Math.max(0, Math.min(maxPanX, x));
        panY = Math.max(0, Math.min(maxPanY, y));
    }
    function sideOf(rec) {
        return rec.tx - panX + 3 + Logic.COVER + 90 + cardWidth + 12 < width ? 1 : -1;
    }
    function stepSel(d) {
        if (!sel) {
            nav(firstVisible());
            return;
        }
        const fa = lay.fachs[sel.f], i = fa.recs.indexOf(sel) + d;
        if (i >= 0 && i < fa.recs.length) {
            nav(fa.recs[i]);
            return;
        }
        for (let f = sel.f + d * Logic.ROWS; f >= 0 && f < lay.fachs.length; f += d * Logic.ROWS) {
            const n = lay.fachs[f].recs;
            if (n.length) {
                nav(d > 0 ? n[0] : n[n.length - 1]);
                return;
            }
        }
    }

    clip: true
    focus: true

    Behavior on pinO {
        NumberAnimation {
            duration: 160
        }
    }
    Behavior on wallX {
        NumberAnimation {
            duration: 170
            easing.type: Easing.OutCubic
        }
    }
    Behavior on wallY {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    Component.onCompleted: reload()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Right)
            stepSel(1);
        else if (event.key === Qt.Key_Left)
            stepSel(-1);
        else if (event.key === Qt.Key_Down)
            rowSel(1);
        else if (event.key === Qt.Key_Up)
            rowSel(-1);
        else if (event.key === Qt.Key_Space && sel)
            pin(!pinned);
        else if (event.key === Qt.Key_Escape)
            clearSel();
        else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && sel && decks.length)
            loadRequested(sel.id, decks[0].group);
        else
            return;
        event.accepted = true;
    }
    onFilterTextChanged: filterTimer.restart()
    onHeightChanged: setPan(panX, panY)
    onSelChanged: {
        pullAnim.stop();
        pull.o = 0;
        if (sel)
            pullAnim.start();
    }
    onSortModeChanged: relayout()
    onWidthChanged: {
        // breiteres Fenster: so viele Spalten, dass die Wand den Platz füllt
        if (lay && Math.ceil(width / Logic.FW) + 1 > lay.cols)
            widthTimer.restart();
        else
            setPan(panX, panY);
    }

    LibrarySource {
        id: source

        onChanged: reloadTimer.restart()
    }
    Timer {
        id: reloadTimer

        interval: 400

        onTriggered: root.reload()
    }
    Timer {
        id: filterTimer

        interval: 180

        onTriggered: root.relayout()
    }
    Timer {
        id: widthTimer

        interval: 120

        onTriggered: root.relayout()
    }
    Rectangle {
        anchors.fill: parent
        color: "#060606"
    }
    // Die Wand, Spalte für Spalte. Nur sichtbare Spalten werden gebaut.
    ListView {
        id: wallView

        cacheBuffer: Logic.FW * 2
        contentX: root.wallX - Logic.X0
        height: root.lay ? root.lay.height : 0
        interactive: false
        model: root.lay ? root.lay.cols + 1 : 0
        orientation: ListView.Horizontal
        width: root.width
        y: -root.wallY

        delegate: Item {
            id: column

            readonly property int col: index
            required property int index
            readonly property real x0: Logic.X0 + col * Logic.FW

            height: wallView.height
            width: Logic.FW

            // Fächer dieser Spalte
            Repeater {
                model: root.lay && column.col < root.lay.cols ? Logic.ROWS : 0

                Item {
                    id: fach

                    readonly property var fa: root.lay.fachs[column.col * Logic.ROWS + index]
                    required property int index
                    readonly property real yb: Logic.fachYB(fa.f)

                    height: Logic.IN
                    width: Logic.IN
                    x: Logic.T
                    y: yb - Logic.IN

                    Rectangle {
                        anchors.fill: parent
                        color: "#0b0b0b"
                    }
                    Repeater {
                        model: fach.fa.recs

                        Rectangle {
                            required property var modelData

                            antialiasing: modelData.rot !== 0
                            color: modelData.tone
                            height: modelData.h
                            rotation: modelData.rot * 180 / Math.PI
                            transformOrigin: Item.BottomLeft
                            width: 3
                            x: modelData.tx - column.x0 - Logic.T
                            y: Logic.IN - modelData.h

                            Rectangle {
                                color: parent.modelData.band ? parent.modelData.band.c : "transparent"
                                height: parent.modelData.band ? parent.modelData.band.len : 0
                                visible: !!parent.modelData.band
                                width: 3
                                y: parent.modelData.band ? parent.height * (1 - parent.modelData.band.y) : 0
                            }
                        }
                    }
                    // Trennkarten mit Reiter
                    Repeater {
                        model: fach.fa.dividers

                        Item {
                            required property var modelData

                            x: modelData.x - column.x0 - Logic.T
                            y: Logic.IN - 240

                            Rectangle {
                                color: "#e4e4e4"
                                height: 226
                                width: 1.5
                                y: 14
                            }
                            Rectangle {
                                clip: true
                                color: "#e4e4e4"
                                height: 15
                                width: Math.max(4, Math.min(tab.implicitWidth + 10, parent.modelData.maxW))

                                Text {
                                    id: tab

                                    color: "#000000"
                                    font.family: Style.sansSemi
                                    font.pixelSize: 10
                                    text: parent.parent.modelData.label
                                    x: 5
                                    y: 1
                                }
                            }
                        }
                    }
                    Rectangle {
                        height: 40
                        width: parent.width

                        gradient: Gradient {
                            GradientStop {
                                color: Qt.rgba(0, 0, 0, 0.75)
                                position: 0
                            }
                            GradientStop {
                                color: Qt.rgba(0, 0, 0, 0)
                                position: 1
                            }
                        }
                    }
                    Text {
                        color: "#6c6c6c"
                        font.family: Style.mono
                        font.pixelSize: 10
                        text: String(fach.fa.f + 1).padStart(2, "0")
                        visible: fach.index === Logic.ROWS - 1
                        x: 2
                        y: Logic.IN + 6
                    }
                    Text {
                        color: "#a5a5a5"
                        elide: Text.ElideRight
                        font.family: Style.sans
                        font.pixelSize: 11
                        text: fach.fa.label
                        visible: fach.index === Logic.ROWS - 1
                        width: Logic.IN - 30
                        x: 24
                        y: Logic.IN + 5
                    }
                }
            }
            // Böden
            Repeater {
                model: root.lay && column.col < root.lay.cols ? Logic.ROWS + 1 : 0

                Rectangle {
                    required property int index

                    color: "#1b1b1c"
                    height: Logic.T
                    width: Logic.FW
                    y: Logic.Y0 + index * Logic.FW

                    Rectangle {
                        color: Qt.rgba(1, 1, 1, 0.1)
                        height: 1
                        width: parent.width
                    }
                }
            }
            // Stütze
            Rectangle {
                color: "#1b1b1c"
                height: Logic.ROWS * Logic.FW + Logic.T
                width: Logic.T
                y: Logic.Y0

                Rectangle {
                    color: Qt.rgba(1, 1, 1, 0.1)
                    height: parent.height
                    width: 1
                }
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.5 * root.pinO
    }
    Item {
        id: world

        x: -root.wallX
        y: -root.wallY

        // Platten, die gerade auf einem Deck liegen: kleine Marke über dem Rücken
        Repeater {
            model: root.decks

            Rectangle {
                required property var modelData
                readonly property var rec: root.deckRecords[modelData.group] || null

                color: Style.fg
                height: 5
                visible: rec !== null && rec.f >= 0
                width: 3
                x: rec ? rec.tx : 0
                y: rec ? rec.ty - rec.h - 9 : 0
            }
        }
        // die Lücke, aus der die Platte kommt
        Rectangle {
            color: "#0b0b0b"
            height: Logic.IN - 2
            rotation: root.sel ? root.sel.rot * 180 / Math.PI : 0
            transformOrigin: Item.BottomLeft
            visible: root.sel !== null && !mouse.dragging
            width: 4.4
            x: root.sel ? root.sel.tx - 0.6 : 0
            y: root.sel ? root.sel.ty - height : 0
        }
        Item {
            id: pull

            readonly property real e: o * o * (3 - 2 * o)
            property real o: 0                         // 0 = im Fach, 1 = ganz heraus
            readonly property int side: root.sel ? root.sideOf(root.sel) : 1

            visible: root.sel !== null && !mouse.dragging
            x: root.sel ? root.sel.tx + (side > 0 ? 3 : 0) : 0
            y: root.sel ? root.sel.ty - Logic.COVER - 4 - 12 * e : 0

            Vinyl {
                rec: root.sel
                size: Logic.COVER * 0.94
                visible: root.pinO > 0
                x: (pull.side > 0 ? Logic.COVER - size : -Logic.COVER) + pull.side * Logic.COVER * 0.37 * root.pinO
                y: (Logic.COVER - size) / 2
            }
            Item {
                height: Logic.COVER
                width: Logic.COVER
                x: pull.side > 0 ? 0 : -Logic.COVER

                transform: Scale {
                    origin.x: pull.side > 0 ? 0 : Logic.COVER
                    xScale: 0.02 + 0.98 * pull.e
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -1 - root.pinO
                    color: Qt.rgba(1, 1, 1, 0.35 + 0.65 * root.pinO)
                }
                CoverArt {
                    anchors.fill: parent
                    rec: root.sel
                }
                Rectangle {
                    anchors.fill: parent
                    color: "#000000"
                    opacity: (1 - pull.e) * 0.55
                }
            }
        }
    }
    NumberAnimation {
        id: pullAnim

        duration: 130
        easing.type: Easing.OutCubic
        from: 0
        property: "o"
        target: pull
        to: 1
    }
    MouseArea {
        id: mouse

        property real accX: 0
        property real accY: 0
        property bool dragging: false
        property string mode: ""
        property bool moved: false
        property real pan0x: 0
        property real pan0y: 0
        property real px: 0
        property real py: 0
        property var rec: null
        property real rowLock: 0
        property real wLast: 0

        anchors.fill: parent
        cursorShape: root.sel && !root.pinned ? Qt.OpenHandCursor : Qt.ArrowCursor
        hoverEnabled: true

        onDoubleClicked: m => {
            if (root.sel && root.decks.length && (root.hitRec(m.x, m.y) === root.sel || root.pinned))
                root.loadRequested(root.sel.id, root.decks[0].group);
        }
        onExited: {
            if (!pressed && !root.pinned && !root.navMode)
                root.clearSel();
        }
        onPositionChanged: m => {
            if (!pressed) {
                // schweben: die Platte unter dem Zeiger kommt heraus
                if (root.pinned)
                    return;
                if (root.navMode) {
                    if (Math.hypot(m.x - root.navPt.x, m.y - root.navPt.y) < 14)
                        return;
                    root.navMode = false;
                }
                const r = root.hitRec(m.x, m.y);
                if (r)
                    root.select(r);
                return;
            }
            if (!moved && Math.hypot(m.x - px, m.y - py) > 8)
                moved = true;
            if (!moved)
                return;
            if (mode === "pan") {
                root.setPan(pan0x - (m.x - px), pan0y - (m.y - py));
            } else if (mode === "rec") {
                if (!dragging) {
                    dragging = true;
                    root.navMode = false;
                    root.dragStarted(rec.id, rec.pick);
                }
                root.dragMoved(m.x, m.y);
            }
        }
        onPressed: m => {
            root.forceActiveFocus();
            px = m.x;
            py = m.y;
            moved = false;
            dragging = false;
            pan0x = root.panX;
            pan0y = root.panY;
            const r = root.navMode && root.sel && !root.pinned ? root.sel : root.hitRec(m.x, m.y);
            if (r) {
                mode = "rec";
                rec = r;
                if (r !== root.sel) {
                    root.pinned = false;
                    root.select(r);
                }
            } else {
                mode = "pan";
                rec = null;
            }
        }
        onReleased: m => {
            if (dragging) {
                dragging = false;
                root.dragEnded(m.x, m.y);
            } else if (mode === "rec") {
                if (root.sel === rec && !root.pinned)
                    root.pin(true);
            } else if (!moved && root.sel) {
                root.clearSel();
            }
            mode = "";
        }
        // Touchpad: zwei Finger links/rechts blättern Platte für Platte, hoch/runter wechseln die Reihe.
        // Ein Mausrad rastet: eine Raste = eine Reihe, mit Umschalt eine Platte.
        onWheel: w => {
            const now = Date.now();
            if (now - wLast > 160) {
                accX = 0;
                accY = 0;
            }
            wLast = now;
            if (!root.sel) {
                const h = root.hit(w.x, w.y);
                root.nav(h ? h.rec : root.firstVisible());
                return;
            }
            const pixel = w.pixelDelta.x !== 0 || w.pixelDelta.y !== 0;
            let dx = pixel ? -w.pixelDelta.x : -w.angleDelta.x / 120;
            let dy = pixel ? -w.pixelDelta.y : -w.angleDelta.y / 120;
            if ((w.modifiers & Qt.ShiftModifier) && dx === 0) {
                dx = dy;
                dy = 0;
            }
            if (Math.abs(dx) >= Math.abs(dy)) {
                accY = 0;
                if (!pixel) {
                    root.stepSel(Math.sign(dx));
                } else {
                    accX += dx;
                    while (accX > 22) {
                        root.stepSel(1);
                        accX -= 22;
                    }
                    while (accX < -22) {
                        root.stepSel(-1);
                        accX += 22;
                    }
                }
            } else {
                accX = 0;
                if (now - rowLock < (pixel ? 600 : 120))
                    return;
                if (!pixel) {
                    root.rowSel(Math.sign(dy));
                    rowLock = now;
                } else {
                    accY += dy;
                    if (Math.abs(accY) > 70) {
                        root.rowSel(Math.sign(accY));
                        accY = 0;
                        rowLock = now;
                    }
                }
            }
            root.navMode = true;
            root.navPt = Qt.point(w.x, w.y);
        }
    }
    RecordCard {
        id: card

        readonly property int side: root.sel ? root.sideOf(root.sel) : 1

        decks: root.decks
        enabled: root.pinned
        pinned: root.pinned
        rec: root.sel
        rev: root.selRev
        visible: root.sel !== null && !mouse.dragging
        width: root.cardWidth
        x: root.sel ? Math.round(side > 0 ? root.sel.tx - root.wallX + 3 + Logic.COVER + 14 + 76 * root.pinO : root.sel.tx - root.wallX - Logic.COVER - 14 - 76 * root.pinO - width) : 0
        y: root.sel ? Math.round(Math.max(8, Math.min(root.sel.ty - root.wallY - Logic.COVER - 16, root.height - height - 8))) : 0

        onLoad: group => root.loadRequested(root.sel.id, group)
        onPicked: i => {
            root.sel.pick = i;
            root.selRev++;
        }
        onPutBack: root.clearSel()
    }
    // Lage in der Wand, zugleich Schieber
    Rectangle {
        color: Style.line
        height: 3
        visible: root.maxPanX > 0
        width: 180
        x: root.width - width - 14
        y: 8

        Rectangle {
            color: Style.dim
            height: 3
            width: root.lay ? parent.width * Math.min(1, root.width / root.lay.width) : 0
            x: root.lay ? (parent.width - width) * (root.maxPanX ? root.wallX / root.maxPanX : 0) : 0
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -8

            onPositionChanged: m => {
                if (pressed)
                    root.setPan(root.maxPanX * Math.max(0, Math.min(1, (m.x - 8) / parent.width)), root.panY);
            }
            onPressed: m => root.setPan(root.maxPanX * Math.max(0, Math.min(1, (m.x - 8) / parent.width)), root.panY)
        }
    }
    Column {
        anchors.centerIn: parent
        spacing: 10
        visible: root.recordCount === 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Style.fg
            font.family: Style.sansSemi
            font.pixelSize: 20
            text: root.filterText ? "Nichts gefunden" : "Das Regal ist noch leer"
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Style.dim
            font.family: Style.sans
            font.pixelSize: 13
            text: root.filterText ? "Keine Platte passt zu „" + root.filterText + "“." : "In den Einstellungen einen Musikordner hinzufügen, dann füllt es sich."
        }
        TextButton {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Einstellungen"
            visible: !root.filterText

            onClicked: root.preferencesRequested()
        }
    }
}
// [/AI-generated]
