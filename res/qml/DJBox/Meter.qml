import Mixxx 1.0 as Mixxx
import QtQuick
import "."

// Pegelanzeige als Punktmatrix: grün, oben gelb, ganz oben rot.
Item {
    id: root

    property int columns: 2
    property real dot: 6
    required property string group
    required property string key
    readonly property int lit: Math.round(Math.max(0, Math.min(1, control.value)) * segments)
    property int segments: 16

    height: segments * dot
    width: columns * dot

    onLitChanged: canvas.requestPaint()

    Mixxx.ControlProxy {
        id: control

        group: root.group
        key: root.key
    }
    Canvas {
        id: canvas

        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const d = root.dot, n = root.segments;
            for (let i = 0; i < n; i++) {
                const fromBottom = n - 1 - i, on = fromBottom < root.lit;
                ctx.fillStyle = !on ? "#1c1c1c" : fromBottom >= n - 2 ? Style.ledRed : fromBottom >= n - 5 ? Style.ledAmber : Style.ledGreen;
                for (let c = 0; c < root.columns; c++) {
                    ctx.beginPath();
                    ctx.arc((c + 0.5) * d, (i + 0.5) * d, d * 0.36, 0, Math.PI * 2);
                    ctx.fill();
                }
            }
        }
    }
}
