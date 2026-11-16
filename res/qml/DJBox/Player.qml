// [AI-generated] This file was written by an AI agent (Claude, Anthropic).
import Mixxx 1.0 as Mixxx
import QtQuick
import "."
import "ShelfLogic.mjs" as Logic

// Ein Player im Club-Layout = ein Mixxx-Deck.
// Oben das Display mit Titel, großer Wellenform, Zeit, BPM, Tonart und Übersicht;
// darunter Hot Cues und Loops, links PLAY und CUE, in der Mitte das Jograd, rechts das Tempo.
// Auf dem Player liegt ein Stapel Platten; die oberste läuft. TRACK ◀ ▶ blättert durch ihre Tracks.
Rectangle {
    id: root

    readonly property var current: player ? player.currentTrack : null
    required property string group
    property bool highlight: false               // eine Platte schwebt gerade darüber
    required property string label
    readonly property bool loadedTrack: loaded.value > 0
    readonly property string loadedUrl: current ? String(current.trackLocationUrl) : ""
    readonly property int pick: {
        rev;
        return topRec ? topRec.pick : -1;
    }
    readonly property var player: Mixxx.PlayerManager.getPlayer(group)
    readonly property bool playing: play.value > 0
    property bool removable: false
    property int rev: 0                          // zählt hoch, wenn sich am Stapel oder am gewählten Track etwas ändert
    property var stack: []
    readonly property var topRec: stack.length ? stack[stack.length - 1] : null
    readonly property var track: topRec && pick >= 0 ? topRec.tracks[pick] : null
    readonly property string trackArtist: current && current.artist ? current.artist : topRec ? topRec.artist : ""
    readonly property string trackTitle: current && current.title ? current.title : track ? track.title : ""

    signal dropRequested
    signal pickRequested(int index)
    signal removeRequested

    border.color: root.highlight ? Style.fg : "#2a2b2e"
    border.width: root.highlight ? 2 : 1
    height: 770
    radius: 10
    width: 520

    gradient: Gradient {
        GradientStop {
            color: Style.bodyHi
            position: 0
        }
        GradientStop {
            color: Style.body
            position: 0.4
        }
        GradientStop {
            color: Style.bodyLo
            position: 1
        }
    }

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
        id: rateDir

        group: root.group
        key: "rate_dir"
    }
    Mixxx.ControlProxy {
        id: keylock

        group: root.group
        key: "keylock"
    }
    Mixxx.ControlProxy {
        id: keyText

        group: root.group
        key: "key"
    }
    Mixxx.ControlProxy {
        id: syncEnabled

        group: root.group
        key: "sync_enabled"
    }
    Mixxx.ControlProxy {
        id: syncLeader

        group: root.group
        key: "sync_leader"
    }
    Mixxx.ControlProxy {
        id: loopEnabled

        group: root.group
        key: "loop_enabled"
    }

    // Kopfleiste
    Text {
        color: Style.fg
        font.family: Style.sansSemi
        font.pixelSize: 22
        text: root.label
        x: 18
        y: 8
    }
    Text {
        color: Style.ink
        font.family: Style.sansSemi
        font.letterSpacing: 1.4
        font.pixelSize: 9
        text: "DJBOX  P-1"
        x: 44
        y: 12
    }
    Text {
        color: Style.dim
        font.family: Style.sans
        font.letterSpacing: 1
        font.pixelSize: 7
        text: "MEDIA PLAYER  ·  DECK " + root.group.replace(/\D/g, "")
        x: 44
        y: 24
    }
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 16
        spacing: 6
        y: 9

        HwButton {
            enabled: root.removable
            text: "ABBAUEN"
            visible: root.removable
            width: 62

            onClicked: root.removeRequested()
        }
        HwButton {
            enabled: root.stack.length > 0 || root.loadedTrack
            lit: root.stack.length > 1
            litColor: Style.fg
            text: root.stack.length > 1 ? "DROP  ×" + root.stack.length : "DROP"
            width: 70

            onClicked: root.dropRequested()
        }
    }
    // Display
    Rectangle {
        id: screen

        border.color: "#2f3034"
        border.width: 2
        clip: true
        color: Style.screen
        height: 300
        radius: 4
        width: parent.width - 32
        x: 16
        y: 42

        Text {
            id: titleText

            color: root.loadedTrack ? Style.fg : Style.faint
            elide: Text.ElideRight
            font.family: Style.sansSemi
            font.pixelSize: 19
            text: root.loadedTrack ? root.trackTitle : "Platte aus dem Regal hierher ziehen"
            width: parent.width - 24
            x: 12
            y: 8
        }
        Text {
            color: Style.dim
            elide: Text.ElideRight
            font.family: Style.sans
            font.pixelSize: 12
            text: root.loadedTrack ? root.trackArtist + (root.topRec && !root.topRec.single ? "  ·  " + root.topRec.title : "") : ""
            width: parent.width - 24
            x: 12
            y: 33
        }
        // die Tracks der Platte: antippen setzt die Nadel
        Row {
            spacing: 4
            visible: root.topRec !== null && root.topRec.tracks.length > 1
            x: 12
            y: 54

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: Style.dim
                font.family: Style.sansMedium
                font.letterSpacing: 0.6
                font.pixelSize: 8
                rightPadding: 4
                text: "TRACK"
            }
            Repeater {
                model: root.topRec ? root.topRec.tracks : []

                Rectangle {
                    required property int index
                    required property var modelData

                    border.color: index === root.pick ? Style.fg : "#3a3a3a"
                    border.width: 1
                    color: index === root.pick ? Style.fg : chipArea.containsMouse ? "#1e1e1e" : "transparent"
                    height: 16
                    radius: 2
                    width: Math.max(18, chipText.implicitWidth + 8)

                    Text {
                        id: chipText

                        anchors.centerIn: parent
                        color: parent.index === root.pick ? "#000000" : Style.ink
                        font.family: Style.monoBold
                        font.pixelSize: 9
                        text: parent.modelData.pos
                    }
                    MouseArea {
                        id: chipArea

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: root.pickRequested(parent.index)
                    }
                }
            }
        }
        // große Wellenform
        Rectangle {
            id: waveBox

            color: "#050505"
            height: 108
            width: parent.width - 4
            x: 2
            y: 76

            Loader {
                id: waveform

                active: Style.stockWidgets
                anchors.fill: parent

                Component.onCompleted: {
                    if (Style.stockWidgets)
                        setSource(Qt.resolvedUrl("../WaveformDisplay.qml"), {
                            "group": root.group
                        });
                }
            }
            FakeWave {
                anchors.fill: parent
                position: position.value
                seed: root.track ? Logic.hash(root.track.url) : 0
                visible: !Style.stockWidgets && root.loadedTrack
                zoom: 16
            }
        }
        // Zeit, Tempo, BPM, Tonart
        Item {
            height: 60
            width: parent.width - 24
            x: 12
            y: 190

            Column {
                spacing: 1

                Text {
                    color: Style.dim
                    font.family: Style.sansMedium
                    font.letterSpacing: 0.8
                    font.pixelSize: 8
                    text: "REMAIN"
                }
                Dots {
                    color: root.loadedTrack ? (duration.value * (1 - position.value) < 30 && root.playing ? Style.ledRed : Style.fg) : Style.faint
                    size: 34
                    text: root.loadedTrack ? "-" + Logic.fmtTime(duration.value * (1 - position.value)) : "-:--"
                }
            }
            Column {
                spacing: 1
                x: 170

                Text {
                    color: Style.dim
                    font.family: Style.sansMedium
                    font.letterSpacing: 0.8
                    font.pixelSize: 8
                    text: "TEMPO" + (keylock.value > 0 ? "   MT" : "")
                }
                Dots {
                    readonly property real pct: (rateRatio.value - 1) * 100

                    color: Math.abs(pct) < 0.005 ? Style.dim : Style.fg
                    size: 22
                    text: (pct >= 0 ? "+" : "-") + Math.abs(pct).toFixed(2) + "%"
                }
                Text {
                    color: Style.dim
                    font.family: Style.mono
                    font.pixelSize: 9
                    text: "±" + Math.round(rateRange.value * 100) + "%"
                }
            }
            Column {
                anchors.right: parent.right
                spacing: 1

                Text {
                    anchors.right: parent.right
                    color: Style.dim
                    font.family: Style.sansMedium
                    font.letterSpacing: 0.8
                    font.pixelSize: 8
                    text: "BPM"
                }
                Dots {
                    anchors.right: parent.right
                    color: root.loadedTrack ? Style.fg : Style.faint
                    size: 34
                    text: root.loadedTrack && bpm.value > 0 ? bpm.value.toFixed(1) : "---.-"
                }
            }
            Dots {
                readonly property string k: root.track && root.track.key ? root.track.key : root.current && root.current.keyText ? root.current.keyText : ""

                color: k ? Logic.keyColor(k) : Style.faint
                size: 22
                text: k ? k.slice(0, 4) : "--"
                x: 300
                y: 11
            }
        }
        // Übersicht über den ganzen Track
        Rectangle {
            color: "#0b0b0b"
            height: 34
            width: parent.width - 24
            x: 12
            y: 256

            Loader {
                id: overview

                active: Style.stockWidgets
                anchors.fill: parent

                Component.onCompleted: {
                    if (Style.stockWidgets)
                        setSource(Qt.resolvedUrl("../WaveformOverview.qml"), {
                            "group": root.group
                        });
                }
            }
            FakeWave {
                anchors.fill: parent
                position: position.value
                seed: root.track ? Logic.hash(root.track.url) : 0
                visible: !Style.stockWidgets && root.loadedTrack
                zoom: 1
            }
            MouseArea {
                anchors.fill: parent
                enabled: !Style.stockWidgets && root.loadedTrack

                onClicked: m => position.value = m.x / width
            }
        }
    }
    // Hot Cues
    Row {
        spacing: 6
        x: 16
        y: 354

        Repeater {
            model: 8

            Rectangle {
                id: pad

                readonly property color cueColor: colorControl.value < 0 ? Style.cue : "#" + Math.round(colorControl.value).toString(16).padStart(6, "0")
                required property int index
                readonly property bool isSet: status.value > 0

                border.color: isSet ? cueColor : "#3a3b3d"
                border.width: isSet ? 1.5 : 1
                color: padArea.pressed ? "#2a2b2d" : isSet ? Qt.rgba(cueColor.r * 0.3, cueColor.g * 0.3, cueColor.b * 0.3, 1) : "#17181a"
                height: 30
                radius: 3
                width: (screen.width - 7 * 6) / 8

                Mixxx.ControlProxy {
                    id: activate

                    group: root.group
                    key: "hotcue_" + (pad.index + 1) + "_activate"
                }
                Mixxx.ControlProxy {
                    id: status

                    group: root.group
                    key: "hotcue_" + (pad.index + 1) + "_status"
                }
                Mixxx.ControlProxy {
                    id: colorControl

                    group: root.group
                    key: "hotcue_" + (pad.index + 1) + "_color"
                }
                Mixxx.ControlProxy {
                    id: clear

                    group: root.group
                    key: "hotcue_" + (pad.index + 1) + "_clear"
                }
                Text {
                    anchors.centerIn: parent
                    color: pad.isSet ? pad.cueColor : Style.dim
                    font.family: Style.sansSemi
                    font.pixelSize: 11
                    text: String.fromCharCode(65 + pad.index)
                }
                MouseArea {
                    id: padArea

                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    anchors.fill: parent

                    onPressed: m => {
                        if (m.button === Qt.RightButton)
                            clear.value = 1;
                        else
                            activate.value = 1;
                    }
                    onReleased: m => {
                        if (m.button === Qt.RightButton)
                            clear.value = 0;
                        else
                            activate.value = 0;
                    }
                }
            }
        }
    }
    Text {
        color: Style.dim
        font.family: Style.sansMedium
        font.letterSpacing: 0.8
        font.pixelSize: 7
        text: "HOT CUE   ·   RECHTSKLICK LÖSCHT"
        x: 16
        y: 388
    }
    // Loops
    Row {
        spacing: 6
        x: 16
        y: 402

        Repeater {
            model: [["IN", "loop_in", false], ["OUT", "loop_out", false], ["RELOOP", "reloop_toggle", false], ["4 BEAT", "beatloop_4_toggle", true], ["8 BEAT", "beatloop_8_toggle", true]]

            HwButton {
                id: loopButton

                required property var modelData

                lit: modelData[1] === "reloop_toggle" ? loopEnabled.value > 0 : modelData[2] ? beatloop.value > 0 : false
                litColor: Style.ledGreen
                text: modelData[0]
                width: 56

                onPressStarted: control.value = 1
                onReleased: control.value = 0

                Mixxx.ControlProxy {
                    id: control

                    group: root.group
                    key: loopButton.modelData[1]
                }
                Mixxx.ControlProxy {
                    id: beatloop

                    group: root.group
                    key: loopButton.modelData[2] ? loopButton.modelData[1].replace("_toggle", "_enabled") : "loop_enabled"
                }
            }
        }
    }
    // Track-Suche durch die Platte, Spulen
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 16
        spacing: 6
        y: 402

        HwButton {
            enabled: root.topRec !== null && root.pick > 0
            text: "◀ TRACK"
            width: 60

            onClicked: root.pickRequested(root.pick - 1)
        }
        HwButton {
            enabled: root.topRec !== null && root.pick < root.topRec.tracks.length - 1
            text: "TRACK ▶"
            width: 60

            onClicked: root.pickRequested(root.pick + 1)
        }
    }
    // links: Spulen, CUE und PLAY
    Column {
        spacing: 6
        x: 16
        y: 446

        Repeater {
            model: [["◀◀", "back"], ["▶▶", "fwd"]]

            HwButton {
                id: searchButton

                required property var modelData

                text: modelData[0]
                width: 46

                onPressStarted: searchControl.value = 1
                onReleased: searchControl.value = 0

                Mixxx.ControlProxy {
                    id: searchControl

                    group: root.group
                    key: searchButton.modelData[1]
                }
            }
        }
    }
    RoundButton {
        blink: !root.playing
        lit: root.loadedTrack
        ringColor: Style.cue
        size: 76
        text: "CUE"
        x: 20
        y: 576

        onPressStarted: cue.value = 1
        onReleased: cue.value = 0
    }
    RoundButton {
        blink: !root.playing
        lit: root.loadedTrack
        ringColor: Style.play
        size: 76
        text: "▶ ❙❙"
        x: 20
        y: 670

        onPressStarted: {
            if (root.loadedTrack)
                play.value = play.value > 0 ? 0 : 1;
        }
    }
    JogWheel {
        group: root.group
        rec: root.topRec
        size: 318
        x: 112
        y: 440
    }
    // rechts: Sync, Master Tempo, Bereich, Tempofader
    Column {
        spacing: 6
        x: root.width - 16 - 64
        y: 446

        HwButton {
            lit: syncEnabled.value > 0
            litColor: Style.fx
            text: "SYNC"
            width: 64

            onClicked: syncEnabled.value = syncEnabled.value > 0 ? 0 : 1
        }
        HwButton {
            lit: syncLeader.value > 0
            litColor: Style.cue
            text: "MASTER"
            width: 64

            onClicked: syncLeader.value = syncLeader.value > 0 ? 0 : 1
        }
        HwButton {
            lit: keylock.value > 0
            litColor: Style.ledRed
            text: "MT"
            width: 64

            onClicked: keylock.value = keylock.value > 0 ? 0 : 1
        }
        HwButton {
            readonly property var modes: [0.06, 0.08, 0.10, 0.16, 1]

            text: rateRange.value >= 0.99 ? "WIDE" : "±" + Math.round(rateRange.value * 100)
            width: 64

            onClicked: {
                let i = 0;
                for (let k = 0; k < modes.length; k++) {
                    if (Math.abs(modes[k] - rateRange.value) < Math.abs(modes[i] - rateRange.value))
                        i = k;
                }
                rateRange.value = modes[(i + 1) % modes.length];
            }
        }
    }
    Fader {
        id: pitch

        center: true
        group: root.group
        inverted: true
        key: "rate"
        length: 190
        ticks: 17
        x: root.width - 16 - 34
        y: 568
    }
    // oben am Fader liegt rate = −1; welches Vorzeichen das hat, entscheidet rate_dir
    Text {
        color: Style.dim
        font.family: Style.mono
        font.pixelSize: 9
        horizontalAlignment: Text.AlignRight
        text: (rateDir.value < 0 ? "+" : "−")
        width: 12
        x: pitch.x - 16
        y: pitch.y + 6
    }
    Text {
        color: Style.dim
        font.family: Style.mono
        font.pixelSize: 9
        horizontalAlignment: Text.AlignRight
        text: "0"
        width: 12
        x: pitch.x - 16
        y: pitch.y + pitch.length / 2 - 6
    }
    Text {
        color: Style.dim
        font.family: Style.mono
        font.pixelSize: 9
        horizontalAlignment: Text.AlignRight
        text: (rateDir.value < 0 ? "−" : "+")
        width: 12
        x: pitch.x - 16
        y: pitch.y + pitch.length - 16
    }
    Text {
        color: Style.ink
        font.family: Style.sansMedium
        font.letterSpacing: 0.8
        font.pixelSize: 8
        text: "TEMPO"
        x: pitch.x + 2
        y: pitch.y + pitch.length + 2
    }
}
// [/AI-generated]
