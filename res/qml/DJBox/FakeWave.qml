// [AI-generated] This file was written by an AI agent (Claude, Anthropic).
import QtQuick
import "ShelfLogic.mjs" as Logic

// Ersatz-Wellenform nur für die Testumgebung ohne Mixxx. In Mixxx zeichnet Mixxx selbst.
Canvas {
    id: root

    property real position: 0
    property int seed: 0
    property real zoom: 1

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        if (!visible || !seed)
            return;
        const R = Logic.rng(seed), n = 900, amp = [];
        for (let i = 0; i < n; i++)
            amp.push(0.25 + 0.75 * Math.abs(Math.sin(i * 0.05 + R() * 0.4)) * (0.6 + 0.4 * R()) * (i % 64 < 4 ? 0.3 : 1));
        const span = n / zoom, start = zoom > 1 ? position * n - span / 2 : 0, w = width / span, mid = height / 2;
        for (let k = 0; k < span; k++) {
            const i = Math.floor(start + k);
            if (i < 0 || i >= n)
                continue;
            const a = amp[i], played = i < position * n;
            ctx.fillStyle = played && zoom === 1 ? "#4a4a4a" : "#2154d7";
            ctx.fillRect(k * w, mid - a * mid * 0.95, Math.max(1, w - (zoom > 1 ? 1 : 0)), a * mid * 1.9);
            ctx.fillStyle = played && zoom === 1 ? "#6a6a6a" : "#d5c2a2";
            ctx.fillRect(k * w, mid - a * mid * 0.35, Math.max(1, w - (zoom > 1 ? 1 : 0)), a * mid * 0.7);
        }
        ctx.fillStyle = "#ffffff";
        ctx.fillRect(zoom > 1 ? width / 2 - 1 : position * width - 1, 0, 2, height);
    }
    onPositionChanged: if (visible)
        requestPaint()
    onSeedChanged: requestPaint()
    onVisibleChanged: requestPaint()
}
// [/AI-generated]
