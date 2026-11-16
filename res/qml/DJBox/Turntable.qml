import Mixxx 1.0 as Mixxx
import QtQuick
import "."
import "ShelfLogic.mjs" as Logic

// Ein Plattenspieler = ein Mixxx-Deck. Auf dem Teller liegt ein Stapel Platten; die oberste läuft.
// Ein Klick auf ein Band der Platte setzt die Nadel auf diesen Track.
Rectangle {
    id: root

    readonly property var current: player ? player.currentTrack : null
    required property string group
    property bool highlight: false               // eine Platte schwebt gerade darüber
    required property string label
    readonly property string loadedUrl: current ? String(current.trackLocationUrl) : ""
    readonly property int pick: {
        rev;
        return topRec ? topRec.pick : -1;
    }
    readonly property rect platterRect: Qt.rect(platter.x, platter.y, platter.width, platter.height)
    readonly property var player: Mixxx.PlayerManager.getPlayer(group)
    readonly property bool playing: play.value > 0
    property bool removable: false
    property int rev: 0                          // zählt hoch, wenn sich am Stapel oder am gewählten Track etwas ändert
    property var stack: []
    readonly property var topRec: stack.length ? stack[stack.length - 1] : null
    readonly property var track: topRec && pick >= 0 ? topRec.tracks[pick] : null

    signal dropRequested
    signal pickRequested(int index)
    signal removeRequested

    border.color: root.highlight ? Style.fg : "#262626"
    border.width: 1
    color: "#0c0c0c"
    height: 488
    width: 620

    Mixxx.ControlProxy {
        id: play

        group: root.group
        key: "play"
    }
    Mixxx.ControlProxy {
        id: cue

        group: root.group
        key: "cue_default"
    }
    Mixxx.ControlProxy {
        id: eject

        group: root.group
        key: "eject"
    }
    Mixxx.ControlProxy {
        id: bpm

        group: root.group
        key: "bpm"
    }
    Mixxx.ControlProxy {
        id: position

        group: root.group
        key: "playposition"
    }
    Mixxx.ControlProxy {
        id: duration

        group: root.group
        key: "duration"
    }
    Mixxx.ControlProxy {
        id: loaded

        group: root.group
        key: "track_loaded"
    }
    Mixxx.ControlProxy {
        id: rateRatio

        group: root.group
        key: "rate_ratio"
    }
    Mixxx.ControlProxy {
        id: rateRange

        group: root.group
        key: "rateRange"
    }
    Mixxx.ControlProxy {
        id: nudgeDown

        group: root.group
        key: "rate_temp_down"
    }
    Mixxx.ControlProxy {
        id: nudgeUp

        group: root.group
        key: "rate_temp_up"
    }
    Mixxx.ControlProxy {
        id: keylock

        group: root.group
        key: "keylock"
    }
    // Schrauben
    Repeater {
        model: 4

        Rectangle {
            required property int index

            border.color: "#3a3a3a"
            border.width: 1
            color: "#161616"
            height: 7
            radius: 3.5
            width: 7
            x: index % 2 ? root.width - 14 : 7
            y: index < 2 ? 7 : root.height - 14
        }
    }
    Text {
        color: Style.fg
        font.family: Style.sans
        font.pixelSize: 22
        font.weight: Font.DemiBold
        text: root.label
        x: 22
        y: 14
    }
    Text {
        color: Style.dim
        font.family: Style.sans
        font.letterSpacing: 1.2
        font.pixelSize: 8
        text: "DIRECT DRIVE  ·  DECK " + root.group.replace(/\D/g, "")
        x: 46
        y: 25
    }
    Item {
        id: platter

        height: 416
        width: 416
        x: 24
        y: 48

        Rectangle {
            anchors.fill: parent
            border.color: "#4a4a4a"
            border.width: 1
            radius: width / 2

            gradient: Gradient {
                GradientStop {
                    color: "#2b2b2b"
                    position: 0
                }
                GradientStop {
                    color: "#0e0e0e"
                    position: 1
                }
            }
        }
        // Stroboskop-Punkte am Tellerrand, drehen mit
        Canvas {
            anchors.fill: parent
            rotation: disc.rotation

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const c = width / 2;
                ctx.fillStyle = "rgba(216,216,216,0.7)";
                for (let ring = 0; ring < 3; ring++) {
                    const r = c - 3.5 - ring * 3.4, n = 176 - ring * 6;
                    for (let i = 0; i < n; i++) {
                        const a = i / n * Math.PI * 2;
                        ctx.beginPath();
                        ctx.arc(c + Math.cos(a) * r, c + Math.sin(a) * r, 1, 0, Math.PI * 2);
                        ctx.fill();
                    }
                }
            }
        }
        Rectangle {
            anchors.centerIn: parent
            border.color: "#1d1d1d"
            border.width: 1
            color: "#090909"
            height: width
            radius: width / 2
            width: parent.width - 26
        }
        // die Platten darunter
        Repeater {
            model: Math.max(0, root.stack.length - 1)

            Vinyl {
                required property int index
                readonly property int off: (root.stack.length - 1 - index) * 5

                opacity: 0.85
                rec: root.stack[index]
                size: disc.size
                x: disc.x - off
                y: disc.y + off
            }
        }
        Vinyl {
            id: disc

            pick: root.pick
            rec: root.topRec
            // wie auf dem echten Teller: 33⅓ Umdrehungen pro Minute, an der Abspielposition festgemacht
            rotation: (position.value * duration.value / 1.8 * 360) % 360
            size: platter.width - 34
            visible: root.topRec !== null
            x: 17
            y: 17
        }
        Rectangle {
            anchors.centerIn: parent
            color: "#d0d0d0"
            height: 8
            radius: 4
            width: 8
        }
        // Platte, die nicht aus dem Regal kam (z. B. über den Controller geladen)
        Rectangle {
            anchors.centerIn: parent
            border.color: "#2a2a2a"
            border.width: 1
            color: "#060606"
            height: width
            radius: width / 2
            visible: root.topRec === null && loaded.value > 0
            width: disc.size

            Rectangle {
                anchors.centerIn: parent
                color: "#bdbdbd"
                height: width
                radius: width / 2
                rotation: disc.rotation
                width: parent.width * 0.36

                Rectangle {
                    color: "#060606"
                    height: 3
                    width: parent.width * 0.3
                    x: parent.width * 0.6
                    y: parent.height / 2 - 1
                }
            }
        }
        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 54
            color: Style.dim
            font.family: Style.sans
            font.pixelSize: 12
            text: "Platte aus dem Regal hierher ziehen"
            visible: root.topRec === null && loaded.value <= 0
        }
        Rectangle {
            color: Style.fg
            height: 20
            visible: root.stack.length > 1
            width: chip.implicitWidth + 12
            x: parent.width - width - 8
            y: 8

            Text {
                id: chip

                anchors.centerIn: parent
                color: "#000000"
                font.family: Style.mono
                font.pixelSize: 11
                font.weight: Font.Bold
                text: "×" + root.stack.length
            }
        }
        MouseArea {
            anchors.fill: disc
            cursorShape: root.topRec && disc.bandAt(mouseX, mouseY) >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
            enabled: root.topRec !== null
            hoverEnabled: true

            onClicked: m => {
                const i = disc.bandAt(m.x, m.y);
                if (i >= 0)
                    root.pickRequested(i);
            }
        }
    }
    HwButton {
        height: 38
        lit: root.playing
        litColor: Style.ledGreen
        text: "START · STOP"
        width: 92
        x: 14
        y: root.height - 52

        onClicked: {
            if (loaded.value > 0)
                play.value = play.value > 0 ? 0 : 1;
        }
    }
    // rechte Spalte: Anzeige, Tasten, Tempo
    Rectangle {
        id: screen

        border.color: "#2a2a2a"
        border.width: 1
        color: "#000000"
        height: 168
        width: 148
        x: 458
        y: 20

        Text {
            color: root.playing ? Style.ledGreen : Style.dim
            font.family: Style.sans
            font.letterSpacing: 0.8
            font.pixelSize: 9
            font.weight: Font.DemiBold
            text: loaded.value <= 0 ? "EMPTY" : root.playing ? "PLAY" : "CUE"
            x: 10
            y: 9
        }
        Text {
            color: Style.dim
            font.family: Style.sans
            font.letterSpacing: 0.8
            font.pixelSize: 9
            horizontalAlignment: Text.AlignRight
            text: root.track && root.topRec.tracks.length > 1 ? "TRACK " + root.track.pos + "/" + root.topRec.tracks.length : ""
            width: 70
            x: screen.width - 80
            y: 9
        }
        DotText {
            color: loaded.value > 0 ? Style.fg : Style.faint
            dot: 4
            text: loaded.value > 0 && bpm.value > 0 ? bpm.value.toFixed(1).padStart(5, " ") : "---.-"
            x: 10
            y: 28
        }
        Text {
            color: Style.dim
            font.family: Style.sans
            font.pixelSize: 8
            text: "BPM"
            x: 128
            y: 49
        }
        DotText {
            readonly property string keyText: root.track && root.track.key ? root.track.key : root.current && root.current.keyText ? root.current.keyText : ""

            color: keyText ? Logic.keyColor(keyText) : Style.faint
            dot: 3
            text: keyText ? keyText.slice(0, 3) : "--"
            x: 10
            y: 68
        }
        DotText {
            readonly property real pct: (rateRatio.value - 1) * 100

            color: Math.abs(pct) < 0.005 ? Style.dim : Style.fg
            dot: 2.5
            text: (pct >= 0 ? "+" : "-") + Math.abs(pct).toFixed(1) + "%"
            x: screen.width - 10 - width
            y: 71.5
        }
        DotText {
            color: loaded.value > 0 ? Style.fg : Style.faint
            dot: 3
            text: loaded.value > 0 ? "-" + Logic.fmtTime(duration.value * (1 - position.value)) : "-:--"
            x: 10
            y: 98
        }
        Text {
            color: Style.fg
            elide: Text.ElideRight
            font.family: Style.sans
            font.pixelSize: 11
            text: root.track ? root.track.title + "  ·  " + root.topRec.artist : root.current ? root.current.title + "  ·  " + root.current.artist : ""
            width: screen.width - 20
            x: 10
            y: 126
        }
        // Übersicht: die echte Wellenform aus Mixxx, sonst ein Balken
        Rectangle {
            color: "#161616"
            height: 14
            width: screen.width - 20
            x: 10
            y: 146

            Rectangle {
                color: Style.dim
                height: parent.height
                visible: overview.status !== Loader.Ready
                width: parent.width * Math.max(0, Math.min(1, position.value))
            }
            Loader {
                id: overview

                anchors.fill: parent

                Component.onCompleted: {
                    if (Style.stockWidgets)
                        setSource(Qt.resolvedUrl("../WaveformOverview.qml"), {
                            "group": root.group
                        });
                }
            }
        }
    }
    Grid {
        columnSpacing: 6
        columns: 2
        rowSpacing: 6
        x: 458
        y: 198

        HwButton {
            lit: pressed
            text: "CUE"
            width: 71

            onPressStarted: cue.value = 1
            onReleased: cue.value = 0
        }
        HwButton {
            enabled: root.stack.length > 0 || loaded.value > 0
            text: "DROP"
            width: 71

            onClicked: root.dropRequested()
        }
        HwButton {
            text: "◀ NUDGE"
            width: 71

            onPressStarted: nudgeDown.value = 1
            onReleased: nudgeDown.value = 0
        }
        HwButton {
            text: "NUDGE ▶"
            width: 71

            onPressStarted: nudgeUp.value = 1
            onReleased: nudgeUp.value = 0
        }
        HwButton {
            lit: keylock.value > 0
            text: "KEY LOCK"
            width: 71

            onClicked: keylock.value = keylock.value > 0 ? 0 : 1
        }
        HwButton {
            enabled: root.removable
            text: "ABBAUEN"
            visible: root.removable
            width: 71

            onClicked: root.removeRequested()
        }
    }
    // Tempo: wie am Plattenspieler, unten ist schneller
    Fader {
        id: pitch

        center: true
        group: root.group
        inverted: true
        key: "rate"
        length: 150
        ticks: 17
        x: 516
        y: 312
    }
    Repeater {
        model: [["–", 0], ["0", 0.5], ["+", 1]]

        Text {
            required property var modelData

            color: Style.dim
            font.family: Style.mono
            font.pixelSize: 10
            horizontalAlignment: Text.AlignRight
            text: modelData[0] === "0" ? "0" : modelData[0] + Math.round(rateRange.value * 100)
            width: 30
            x: 476
            y: 312 + 13 + pitch.travel * modelData[1] - 7
        }
    }
    Text {
        color: Style.ink
        font.family: Style.sans
        font.letterSpacing: 0.6
        font.pixelSize: 9
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignHCenter
        text: "TEMPO ±" + Math.round(rateRange.value * 100) + " %"
        width: 148
        x: 458
        y: 468
    }
}
