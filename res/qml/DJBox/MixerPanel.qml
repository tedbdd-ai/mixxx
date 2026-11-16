import Mixxx 1.0 as Mixxx
import QtQuick
import "."

// Der Mixer im Club-Layout: je Deck ein Kanalzug (Trim, 3-Band-EQ, Filter, Cue, Fader),
// der Crossfader unter den Kanälen, rechts die Master-Sektion.
Rectangle {
    id: root

    readonly property int channelWidth: 86
    property var decks: []                       // [{ group, label }], von links nach rechts
    readonly property int masterWidth: 156
    readonly property real stripsWidth: Math.max(1, decks.length) * channelWidth

    border.color: "#262626"
    border.width: 1
    color: "#0c0c0c"
    height: 488
    width: 12 + stripsWidth + masterWidth + 10

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
    Repeater {
        model: root.decks

        Item {
            id: strip

            readonly property string eq: "[EqualizerRack1_" + group + "_Effect1]"
            readonly property string group: modelData.group
            required property int index
            required property var modelData

            height: 440
            width: root.channelWidth
            x: 12 + index * root.channelWidth

            Mixxx.ControlProxy {
                id: pfl

                group: strip.group
                key: "pfl"
            }
            Mixxx.ControlProxy {
                id: orientation

                group: strip.group
                key: "orientation"
            }
            Rectangle {
                color: Style.line
                height: 418
                visible: strip.index > 0
                width: 1
                y: 12
            }
            Text {
                color: Style.fg
                font.family: Style.sans
                font.pixelSize: 20
                font.weight: Font.DemiBold
                text: strip.index + 1
                x: 12
                y: 12
            }
            Text {
                color: Style.dim
                font.family: Style.sans
                font.pixelSize: 9
                font.weight: Font.Medium
                text: "DECK " + strip.modelData.label
                x: 12
                y: 38
            }
            Knob {
                group: strip.group
                key: "pregain"
                label: "Trim"
                radius: 13
                silver: true
                x: 64 - width / 2
                y: 12
            }
            Rectangle {
                color: Style.line
                height: 1
                width: parent.width - 16
                x: 8
                y: 68
            }
            Meter {
                dot: 7
                group: strip.group
                key: "vu_meter"
                segments: 20
                x: 9
                y: 82
            }
            Knob {
                group: strip.eq
                hi: "+"
                key: "parameter3"
                label: "Hi"
                lo: "–"
                x: 56 - width / 2
                y: 76
            }
            Knob {
                group: strip.eq
                hi: "+"
                key: "parameter2"
                label: "Mid"
                lo: "–"
                x: 56 - width / 2
                y: 130
            }
            Knob {
                group: strip.eq
                hi: "+"
                key: "parameter1"
                label: "Low"
                lo: "–"
                x: 56 - width / 2
                y: 184
            }
            Rectangle {
                border.color: Style.faint
                border.width: 1
                color: "transparent"
                height: 60
                width: parent.width - 16
                x: 8
                y: 240
            }
            Knob {
                group: "[QuickEffectRack1_" + strip.group + "]"
                hi: "HI"
                key: "super1"
                label: "Color"
                lo: "LOW"
                radius: 15
                x: 43 - width / 2
                y: 244
            }
            HwButton {
                height: 24
                lit: pfl.value > 0
                litColor: Style.ledAmber
                text: "CUE"
                width: 48
                x: 19
                y: 308

                onClicked: pfl.value = pfl.value > 0 ? 0 : 1
            }
            Fader {
                group: strip.group
                key: "volume"
                length: 84
                x: 28
                y: 342
            }
            Repeater {
                model: [["10", 0], ["5", 0.5], ["0", 1]]

                Text {
                    required property var modelData

                    color: Style.dim
                    font.family: Style.mono
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignRight
                    text: modelData[0]
                    width: 14
                    x: 8
                    y: 342 + 13 + 58 * modelData[1] - 6
                }
            }
            // Crossfader-Zuweisung
            SlideSwitch {
                index: Math.round(orientation.value)
                labels: ["A", "THRU", "B"]
                step: 24
                x: 43 - width / 2
                y: 432

                onMoved: i => orientation.value = i
            }
        }
    }
    // Crossfader unter den Kanälen
    Item {
        id: cross

        readonly property real faderWidth: Math.max(110, Math.min(220, root.stripsWidth - 56))

        height: 30
        width: root.stripsWidth
        x: 12
        y: 456

        Text {
            anchors.verticalCenter: xfader.verticalCenter
            anchors.verticalCenterOffset: 2
            color: Style.ink
            font.family: Style.sans
            font.pixelSize: 10
            font.weight: Font.DemiBold
            text: "A"
            x: xfader.x - 14
        }
        Text {
            anchors.verticalCenter: xfader.verticalCenter
            anchors.verticalCenterOffset: 2
            color: Style.ink
            font.family: Style.sans
            font.pixelSize: 10
            font.weight: Font.DemiBold
            text: "B"
            x: xfader.x + xfader.width + 7
        }
        Fader {
            id: xfader

            center: true
            group: "[Master]"
            horizontal: true
            key: "crossfader"
            length: cross.faderWidth
            ticks: 9
            x: (parent.width - width) / 2
            y: 0
        }
    }
    // Master
    Item {
        id: master

        height: root.height
        width: root.masterWidth
        x: 12 + root.stripsWidth

        Rectangle {
            color: Style.line
            height: root.height - 24
            width: 1
            y: 12
        }
        Text {
            color: Style.ink
            font.family: Style.sans
            font.letterSpacing: 0.6
            font.pixelSize: 9
            font.weight: Font.Medium
            text: "MASTER LEVEL"
            x: 14
            y: 14
        }
        Knob {
            center: false
            group: "[Master]"
            key: "gain"
            radius: 19
            x: 50 - width / 2
            y: 34
        }
        Meter {
            columns: 1
            dot: 8
            group: "[Main]"
            key: "vu_meter_left"
            segments: 20
            x: 104
            y: 30
        }
        Meter {
            columns: 1
            dot: 8
            group: "[Main]"
            key: "vu_meter_right"
            segments: 20
            x: 118
            y: 30
        }
        Repeater {
            model: [["0", 2], ["–6", 6], ["–12", 10], ["–24", 16]]

            Text {
                required property var modelData

                color: Style.dim
                font.family: Style.mono
                font.pixelSize: 8
                text: modelData[0]
                x: 131
                y: 30 + modelData[1] * 8 - 5
            }
        }
        Text {
            color: Style.dim
            font.family: Style.sans
            font.pixelSize: 8
            text: "L"
            x: 106
            y: 194
        }
        Text {
            color: Style.dim
            font.family: Style.sans
            font.pixelSize: 8
            text: "R"
            x: 120
            y: 194
        }
        DotText {
            color: Style.dim
            dot: 2
            text: "DJBOX"
            x: 14
            y: 438
        }
        Text {
            color: Style.dim
            font.family: Style.sans
            font.letterSpacing: 0.6
            font.pixelSize: 8
            text: "MX-" + root.decks.length + "  ·  MIXXX ENGINE"
            x: 14
            y: 460
        }
        Knob {
            group: "[Master]"
            hi: "R"
            key: "balance"
            label: "Balance"
            lo: "L"
            radius: 13
            x: 40 - width / 2
            y: 222
        }
        Knob {
            center: false
            group: "[Master]"
            key: "booth_gain"
            label: "Booth"
            radius: 13
            x: 114 - width / 2
            y: 222
        }
        Rectangle {
            color: Style.line
            height: 1
            width: parent.width - 24
            x: 12
            y: 290
        }
        Text {
            color: Style.ink
            font.family: Style.sans
            font.letterSpacing: 0.6
            font.pixelSize: 9
            font.weight: Font.Medium
            text: "HEADPHONES"
            x: 14
            y: 300
        }
        Knob {
            group: "[Master]"
            hi: "MST"
            key: "headMix"
            label: "Mixing"
            lo: "CUE"
            radius: 13
            x: 40 - width / 2
            y: 322
        }
        Knob {
            center: false
            group: "[Master]"
            key: "headGain"
            label: "Level"
            radius: 13
            x: 114 - width / 2
            y: 322
        }
    }
}
