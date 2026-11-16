import QtQuick
import "."
import "ShelfLogic.mjs" as Logic

// Das Plattenregal: die Mixxx-Bibliothek als Wand voller Platten.
// Schweben zieht eine Platte heraus, Scrollen blättert (links/rechts) und wechselt die Reihe (hoch/runter),
// ein Klick hält die Platte fest, Ziehen trägt sie zu einem Deck.
Item {
    id: root

    readonly property int cardWidth: 448
    property var deckRecords: ({})                  // Gruppe → Platte, die gerade auf dem Deck liegt
    property var decks: []                          // [{ group: "[Channel1]", label: "A" }]
    property var lay: null
    property int layRev: 0
    readonly property alias librarySource: source
    readonly property real maxPanX: lay ? Math.max(0, lay.width - width) : 0
    readonly property real maxPanY: lay ? Math.max(0, lay.height - visibleBottom) : 0
    property bool navMode: false                    // Auswahl kam vom Scrollen; der Zeiger ruht
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
    property int trackCount: 0
    property var urlIndex: ({})                     // Datei → { rec, i }
    property real visibleBottom: height             // darunter liegt das Set
    property real wallX: panX
    property real wallY: panY

    signal dragEnded(real x, real y)
    signal dragMoved(real x, real y)
    // Platten gehen als Nummer (Index in records) durch Signale: als Objekt kämen sie als Kopie an
    signal dragStarted(int id)
    signal loadRequested(int id, string group)
    signal preferencesRequested
    signal reloaded

    function clearSel() {
        sel = null;
        pinned = false;
        navMode = false;
    }
    function ensureVisible() {
        if (!sel)
            return;
        const sx = sel.tx - panX;
        if (sx > width * 0.52)
            setPan(panX + sx - width * 0.52, panY);
        else if (sx < 150)
            setPan(panX + sx - 150, panY);
        const top = Logic.Y0 + (sel.f % Logic.ROWS) * Logic.FW, bot = top + Logic.FW + 26;
        let y = panY;
        if (bot - y > visibleBottom)
            y = bot - visibleBottom;
        if (top - y < 48)
            y = top - 48;
        setPan(panX, y);
    }
    function firstVisible() {
        if (!lay)
            return null;
        for (const fa of lay.fachs) {
            if (fa.recs.length && Logic.fachX(fa.f) - panX >= 0 && Logic.fachYB(fa.f) - panY <= visibleBottom)
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
        if (!rec)
            return;
        select(rec);
        navMode = true;
        navPt = Qt.point(mouse.mouseX, mouse.mouseY);
        ensureVisible();
    }
    function paintColumn(ctx, col) {
        const X0 = Logic.X0, Y0 = Logic.Y0, FW = Logic.FW, T = Logic.T, IN = Logic.IN, ROWS = Logic.ROWS;
        ctx.reset();
        if (!lay)
            return;
        const x0 = X0 + col * FW, bot = Y0 + ROWS * FW + T;
        ctx.translate(-x0, 0);
        if (col < lay.cols) {
            for (let row = 0; row < ROWS; row++) {
                const fa = lay.fachs[col * ROWS + row], x = Logic.fachX(fa.f), yb = Logic.fachYB(fa.f);
                ctx.fillStyle = "#0b0b0b";
                ctx.fillRect(x, yb - IN, IN, IN);
                for (const r of fa.recs) {
                    ctx.save();
                    ctx.translate(r.tx, r.ty);
                    if (r.rot)
                        ctx.rotate(r.rot);
                    ctx.fillStyle = r.tone;
                    ctx.fillRect(0, -r.h, 3, r.h);
                    if (r.band) {
                        ctx.fillStyle = r.band.c;
                        ctx.fillRect(0, -r.h * r.band.y, 3, r.band.len);
                    }
                    ctx.fillStyle = "rgba(255,255,255,0.2)";
                    ctx.fillRect(0, -r.h, 3, 1);
                    ctx.fillStyle = "rgba(0,0,0,0.32)";
                    ctx.fillRect(2.4, -r.h, 0.6, r.h);
                    ctx.restore();
                }
                // Trennkarten mit Reiter
                ctx.font = "bold 10px \"" + Style.sans + "\"";
                ctx.textBaseline = "middle";
                for (const d of fa.dividers) {
                    ctx.fillStyle = "#e4e4e4";
                    ctx.fillRect(d.x, yb - 226, 1.5, 226);
                    const w = Math.max(4, Math.min(ctx.measureText(d.label).width + 10, d.maxW));
                    ctx.fillRect(d.x, yb - 240, w, 15);
                    ctx.save();
                    ctx.beginPath();
                    ctx.rect(d.x, yb - 240, w, 15);
                    ctx.clip();
                    ctx.fillStyle = "#000000";
                    ctx.fillText(d.label, d.x + 5, yb - 232);
                    ctx.restore();
                }
                const g = ctx.createLinearGradient(0, yb - IN, 0, yb - IN + 40);
                g.addColorStop(0, "rgba(0,0,0,0.75)");
                g.addColorStop(1, "rgba(0,0,0,0)");
                ctx.fillStyle = g;
                ctx.fillRect(x, yb - IN, IN, 40);
                ctx.font = "10px \"" + Style.mono + "\"";
                ctx.fillStyle = "#6c6c6c";
                ctx.fillText(String(fa.f + 1).padStart(2, "0"), x + 2, yb + 13);
                if (fa.label) {
                    ctx.font = "11px \"" + Style.sans + "\"";
                    ctx.fillStyle = "#a5a5a5";
                    ctx.fillText(fa.label, x + 24, yb + 13);
                }
            }
            // Böden
            for (let r = 0; r <= ROWS; r++) {
                ctx.fillStyle = "#1b1b1c";
                ctx.fillRect(x0, Y0 + r * FW, FW, T);
                ctx.fillStyle = "rgba(255,255,255,0.1)";
                ctx.fillRect(x0, Y0 + r * FW, FW, 1);
            }
        }
        // Stütze
        ctx.fillStyle = "#1b1b1c";
        ctx.fillRect(x0, Y0, T, bot - Y0);
        ctx.fillStyle = "rgba(255,255,255,0.1)";
        ctx.fillRect(x0, Y0, 1, bot - Y0);
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
        lay = Logic.layout(records, sortMode);
        layRev++;
        setPan(panX, panY);
    }

    // Bibliothek aus der Quelle lesen und zu Platten zusammenfassen
    function reload() {
        const rows = source.rows();
        // die herausgezogene Platte übersteht das Neueinlesen
        const keepUrl = sel ? sel.tracks[sel.pick].url : "", keepPinned = pinned;
        trackCount = rows.length;
        records = Logic.buildRecords(rows);
        const idx = {};
        for (const rec of records) {
            rec.tracks.forEach((t, i) => {
                idx[t.url] = {
                    "rec": rec,
                    "i": i
                };
            });
        }
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
    onSelChanged: {
        pullAnim.stop();
        pull.o = 0;
        if (sel)
            pullAnim.start();
    }
    onSortModeChanged: relayout()
    onVisibleBottomChanged: {
        if (sel && (pinned || navMode))
            ensureVisible();
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
    Rectangle {
        anchors.fill: parent
        color: "#060606"
    }
    ListView {
        id: wallView

        cacheBuffer: 800
        contentX: root.wallX - Logic.X0
        height: root.lay ? root.lay.height : 0
        interactive: false
        model: root.lay ? root.lay.cols + 1 : 0
        orientation: ListView.Horizontal
        width: root.width
        y: -root.wallY

        delegate: Canvas {
            required property int index
            property int rev: root.layRev

            height: wallView.height
            width: Logic.FW

            onPaint: root.paintColumn(getContext("2d"), index)
            onRevChanged: requestPaint()
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
                    root.dragStarted(rec.id);
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
        y: root.sel ? Math.round(Math.max(48, Math.min(root.sel.ty - root.wallY - Logic.COVER - 16, root.visibleBottom - height - 8))) : 0

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
        width: 220
        x: root.width - width - 18
        y: 44

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
        anchors.verticalCenterOffset: -root.height / 2 + root.visibleBottom / 2
        spacing: 10
        visible: root.records.length === 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Style.fg
            font.family: Style.sans
            font.pixelSize: 20
            font.weight: Font.DemiBold
            text: "Das Regal ist noch leer"
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Style.dim
            font.family: Style.sans
            font.pixelSize: 13
            text: "In den Einstellungen einen Musikordner hinzufügen, dann füllt es sich."
        }
        TextButton {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Einstellungen"

            onClicked: root.preferencesRequested()
        }
    }
}
