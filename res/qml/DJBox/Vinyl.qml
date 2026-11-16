// [AI-generated] This file was written by an AI agent (Claude, Anthropic).
import QtQuick
import "."
import "ShelfLogic.mjs" as Logic

// Eine Schallplatte von oben: Rillen, je Track ein Band, in der Mitte das Label.
// Das gewählte Band ist heller, damit man sieht, wo die Nadel liegt.
Canvas {
    id: root

    readonly property real innerR: 0.48      // Anteil des Radius, an dem die Rillen enden
    readonly property real outerR: 0.95
    property int pick: -1                    // gewählter Track oder -1
    property var rec: null
    property real size: 200

    // Welches Band liegt unter dem Punkt (x, y)? -1, wenn keins.
    function bandAt(x, y) {
        const n = rec && rec.tracks ? rec.tracks.length : 0;
        if (!n)
            return -1;
        const rf = Math.hypot(x - size / 2, y - size / 2) / (size / 2);
        if (rf <= innerR - 0.02 || rf > outerR + 0.02)
            return -1;
        return Math.max(0, Math.min(n - 1, Math.floor((outerR - rf) / (outerR - innerR) * n)));
    }

    height: size
    width: size

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const c = size / 2, R = size / 2;
        ctx.fillStyle = "#070707";
        ctx.beginPath();
        ctx.arc(c, c, R, 0, Math.PI * 2);
        ctx.fill();
        if (!rec)
            return;
        const n = rec.tracks.length, R0 = R * outerR, R1 = R * innerR, total = rec.tracks.reduce((s, t) => s + (t.dur || 240), 0);
        const rr = Logic.rng(rec.seed);
        // Rillen
        ctx.lineWidth = 0.5;
        for (let r = R1; r < R0; r += 1.6) {
            ctx.strokeStyle = "rgba(255,255,255," + (0.035 + rr() * 0.05).toFixed(3) + ")";
            ctx.beginPath();
            ctx.arc(c, c, r, 0, Math.PI * 2);
            ctx.stroke();
        }
        // gewähltes Band
        if (pick >= 0 && pick < n) {
            const a = R0 - (R0 - R1) * pick / n, b = R0 - (R0 - R1) * (pick + 1) / n;
            ctx.strokeStyle = "rgba(255,255,255,0.2)";
            ctx.lineWidth = a - b - 2;
            ctx.beginPath();
            ctx.arc(c, c, (a + b) / 2, 0, Math.PI * 2);
            ctx.stroke();
        }
        // Leerrillen zwischen den Tracks
        ctx.strokeStyle = "#000000";
        ctx.lineWidth = 1.6;
        for (let i = 1; i < n; i++) {
            ctx.beginPath();
            ctx.arc(c, c, R0 - (R0 - R1) * i / n, 0, Math.PI * 2);
            ctx.stroke();
        }
        // Glanz
        const g = ctx.createLinearGradient(0, 0, size, size);
        g.addColorStop(0.3, "rgba(255,255,255,0)");
        g.addColorStop(0.5, "rgba(255,255,255,0.07)");
        g.addColorStop(0.7, "rgba(255,255,255,0)");
        ctx.fillStyle = g;
        ctx.beginPath();
        ctx.arc(c, c, R0, 0, Math.PI * 2);
        ctx.fill();
        // Label
        const L = R * 0.36;
        ctx.fillStyle = rec.pal[0];
        ctx.beginPath();
        ctx.arc(c, c, L, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = rec.pal[2];
        ctx.beginPath();
        ctx.arc(c, c, L, Math.PI * (0.1 + rr()), Math.PI * (1.1 + rr()));
        ctx.fill();
        ctx.strokeStyle = rec.pal[1];
        ctx.lineWidth = Math.max(1, L * 0.05);
        ctx.beginPath();
        ctx.arc(c, c, L * 0.62, 0, Math.PI * 2);
        ctx.stroke();
        ctx.fillStyle = "#050505";
        ctx.beginPath();
        ctx.arc(c, c, Math.max(1.5, R * 0.018), 0, Math.PI * 2);
        ctx.fill();
    }
    onPickChanged: requestPaint()
    onRecChanged: requestPaint()
    onSizeChanged: requestPaint()
}
// [/AI-generated]
