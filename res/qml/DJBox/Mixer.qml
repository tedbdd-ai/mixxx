// [AI-generated] This file was written by an AI agent (Claude, Anthropic).
import Mixxx 1.0 as Mixxx
import QtQuick
import "."

// Vierkanal-Mixer im Club-Layout.
// Je Kanal: Trim, 3-Band-EQ, Pegelkette, Color-Filter, CUE, Kanalfader, Crossfader-Zuweisung.
// Unten der Crossfader, rechts Master, Booth, Beat-FX (Mixxx-Effekteinheit 1) und Kopfhörer.
Rectangle {
    id: root

    readonly property var channels: [
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
    readonly property var fxSlot: Mixxx.EffectsManager.getEffectSlot(1, 1)
    readonly property string fxSlotGroup: fxSlot ? fxSlot.group : "[EffectRack1_EffectUnit1_Effect1]"
    readonly property string fxUnit: "[EffectRack1_EffectUnit1]"
    readonly property int stripWidth: 104

    border.color: "#2a2b2e"
    border.width: 1
    height: 770
    radius: 10
    width: 16 + 4 * stripWidth + 196

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

    Text {
        color: Style.ink
        font.family: Style.sansSemi
        font.letterSpacing: 1.4
        font.pixelSize: 9
        text: "DJBOX  M-4"
        x: 18
        y: 12
    }
    Text {
        color: Style.dim
        font.family: Style.sans
        font.letterSpacing: 1
        font.pixelSize: 7
        text: "4-CHANNEL MIXER"
        x: 18
        y: 24
    }
    // Kanalzüge
    Repeater {
        model: root.channels

        Item {
            id: strip

            readonly property string eq: "[EqualizerRack1_" + group + "_Effect1]"
            readonly property string group: modelData.group
            required property int index
            required property var modelData

            height: 640
            width: root.stripWidth
            x: 16 + index * root.stripWidth
            y: 40

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
                color: "#2a2b2e"
                height: 600
                visible: strip.index > 0
                width: 1
            }
            Text {
                color: Style.fg
                font.family: Style.sansSemi
                font.pixelSize: 22
                text: strip.index + 1
                x: 12
                y: 2
            }
            Text {
                color: Style.dim
                font.family: Style.sansMedium
                font.pixelSize: 8
                text: "DECK " + strip.modelData.label
                x: 12
                y: 30
            }
            Knob {
                group: strip.group
                key: "pregain"
                label: "Trim"
                radius: 12
                x: 70 - width / 2
                y: 2
            }
            Rectangle {
                color: "#2a2b2e"
                height: 1
                width: parent.width - 16
                x: 8
                y: 56
            }
            Text {
                color: Style.dim
                font.family: Style.sansMedium
                font.letterSpacing: 0.6
                font.pixelSize: 7
                text: "EQ"
                x: 12
                y: 62
            }
            Repeater {
                model: [["Hi", "parameter3", 72], ["Mid", "parameter2", 134], ["Low", "parameter1", 196]]

                Knob {
                    required property var modelData

                    group: strip.eq
                    hi: "+6"
                    key: modelData[1]
                    label: modelData[0]
                    lo: "−∞"
                    radius: 15
                    x: 44 - width / 2
                    y: modelData[2]
                }
            }
            // Pegelkette des Kanals
            Meter {
                dot: 8
                gap: 2.6
                group: strip.group
                key: "vu_meter"
                segments: 18
                x: 86
                y: 74
            }
            // Color-Filter
            Rectangle {
                border.color: "#3a3b3e"
                border.width: 1
                color: "transparent"
                height: 70
                radius: 3
                width: parent.width - 16
                x: 8
                y: 262
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: Style.dim
                font.family: Style.sansMedium
                font.letterSpacing: 0.6
                font.pixelSize: 7
                text: "COLOR"
                y: 266
            }
            Knob {
                capColor: "#3a3b3e"
                group: "[QuickEffectRack1_" + strip.group + "]"
                hi: "HPF"
                key: "super1"
                lo: "LPF"
                radius: 17
                x: parent.width / 2 - width / 2
                y: 278
            }
            HwButton {
                height: 26
                lit: pfl.value > 0
                litColor: Style.cue
                text: "CUE"
                textSize: 9
                width: 60
                x: parent.width / 2 - width / 2
                y: 344

                onClicked: pfl.value = pfl.value > 0 ? 0 : 1
            }
            Fader {
                group: strip.group
                key: "volume"
                length: 170
                ticks: 11
                x: parent.width / 2 - width / 2 + 6
                y: 386
            }
            Repeater {
                model: [["10", 0], ["5", 0.5], ["0", 1]]

                Text {
                    required property var modelData

                    color: Style.dim
                    font.family: Style.mono
                    font.pixelSize: 8
                    horizontalAlignment: Text.AlignRight
                    text: modelData[0]
                    width: 14
                    x: parent.width / 2 - 26
                    y: 386 + 13 + 144 * modelData[1] - 5
                }
            }
            SlideSwitch {
                index: Math.round(orientation.value)
                labels: ["A", "THRU", "B"]
                step: 26
                x: parent.width / 2 - width / 2
                y: 570

                onMoved: i => orientation.value = i
            }
        }
    }
    Text {
        anchors.horizontalCenter: cross.horizontalCenter
        color: Style.ink
        font.family: Style.sansMedium
        font.letterSpacing: 1
        font.pixelSize: 7
        text: "CROSSFADER"
        y: 650
    }
    Item {
        id: cross

        height: 40
        width: 4 * root.stripWidth
        x: 16
        y: 666

        Text {
            anchors.verticalCenter: xfader.verticalCenter
            color: Style.ink
            font.family: Style.sansSemi
            font.pixelSize: 11
            text: "A"
            x: xfader.x - 18
        }
        Text {
            anchors.verticalCenter: xfader.verticalCenter
            color: Style.ink
            font.family: Style.sansSemi
            font.pixelSize: 11
            text: "B"
            x: xfader.x + xfader.width + 9
        }
        Fader {
            id: xfader

            center: true
            group: "[Master]"
            horizontal: true
            key: "crossfader"
            length: 230
            ticks: 11
            x: (parent.width - width) / 2
            y: 4
        }
    }
    // rechte Sektion
    Item {
        id: right

        height: root.height
        width: 196
        x: 16 + 4 * root.stripWidth

        Rectangle {
            color: "#2a2b2e"
            height: 690
            width: 1
            y: 40
        }
        Text {
            color: Style.ink
            font.family: Style.sansMedium
            font.letterSpacing: 0.8
            font.pixelSize: 8
            text: "MASTER"
            x: 16
            y: 44
        }
        Knob {
            center: false
            group: "[Master]"
            key: "gain"
            label: "Level"
            radius: 18
            x: 50 - width / 2
            y: 58
        }
        Knob {
            center: false
            group: "[Master]"
            key: "booth_gain"
            label: "Booth"
            radius: 14
            x: 50 - width / 2
            y: 122
        }
        Row {
            spacing: 4
            x: 120
            y: 48

            Meter {
                dot: 9
                gap: 2.4
                group: "[Main]"
                key: "vu_meter_left"
                segments: 18
            }
            Meter {
                dot: 9
                gap: 2.4
                group: "[Main]"
                key: "vu_meter_right"
                segments: 18
            }
        }
        Text {
            color: Style.dim
            font.family: Style.sansMedium
            font.pixelSize: 7
            text: "L    R"
            x: 121
            y: 186
        }
        Rectangle {
            color: "#2a2b2e"
            height: 1
            width: parent.width - 24
            x: 12
            y: 204
        }
        // Beat FX = Mixxx-Effekteinheit 1
        Text {
            color: Style.ink
            font.family: Style.sansMedium
            font.letterSpacing: 0.8
            font.pixelSize: 8
            text: "BEAT FX"
            x: 16
            y: 214
        }
        Rectangle {
            id: fxScreen

            border.color: "#2f3034"
            border.width: 2
            color: Style.screen
            height: 60
            radius: 3
            width: parent.width - 32
            x: 16
            y: 230

            Text {
                color: fxOn.value > 0 ? Style.fx : Style.dim
                font.family: Style.sansMedium
                font.letterSpacing: 0.8
                font.pixelSize: 8
                text: fxOn.value > 0 ? "ON" : "OFF"
                x: 8
                y: 6
            }
            Text {
                color: Style.dim
                font.family: Style.mono
                font.pixelSize: 8
                horizontalAlignment: Text.AlignRight
                text: "UNIT 1"
                width: 60
                x: parent.width - 68
                y: 6
            }
            Text {
                color: Style.fg
                elide: Text.ElideRight
                font.family: Style.sansSemi
                font.pixelSize: 15
                text: root.fxSlot && root.fxSlot.effectName ? root.fxSlot.effectName : "—"
                width: parent.width - 16
                x: 8
                y: 24
            }
        }
        Row {
            spacing: 6
            x: 16
            y: 298

            HwButton {
                text: "◀"
                width: 79

                onPressStarted: fxPrev.value = 1
                onReleased: fxPrev.value = 0
            }
            HwButton {
                text: "▶"
                width: 79

                onPressStarted: fxNext.value = 1
                onReleased: fxNext.value = 0
            }
        }
        Text {
            color: Style.dim
            font.family: Style.sansMedium
            font.letterSpacing: 0.6
            font.pixelSize: 7
            text: "CH SELECT"
            x: 16
            y: 330
        }
        Row {
            spacing: 4
            x: 16
            y: 342

            Repeater {
                model: ["1", "2", "3", "4", "M"]

                HwButton {
                    id: chButton

                    required property int index
                    required property string modelData

                    lit: assign.value > 0
                    litColor: Style.fx
                    text: modelData
                    width: 28

                    onClicked: assign.value = assign.value > 0 ? 0 : 1

                    Mixxx.ControlProxy {
                        id: assign

                        group: root.fxUnit
                        key: chButton.modelData === "M" ? "group_[Master]_enable" : "group_[Channel" + chButton.modelData + "]_enable"
                    }
                }
            }
        }
        Knob {
            center: false
            group: root.fxUnit
            key: "mix"
            label: "Level/Depth"
            radius: 18
            x: 56 - width / 2
            y: 380
        }
        RoundButton {
            lit: fxOn.value > 0
            ringColor: Style.fx
            size: 54
            text: "ON/OFF"
            x: 116
            y: 382

            onPressStarted: fxOn.value = fxOn.value > 0 ? 0 : 1
        }
        Rectangle {
            color: "#2a2b2e"
            height: 1
            width: parent.width - 24
            x: 12
            y: 462
        }
        Text {
            color: Style.ink
            font.family: Style.sansMedium
            font.letterSpacing: 0.8
            font.pixelSize: 8
            text: "HEADPHONES"
            x: 16
            y: 472
        }
        Knob {
            group: "[Master]"
            hi: "MST"
            key: "headMix"
            label: "Mixing"
            lo: "CUE"
            radius: 15
            x: 50 - width / 2
            y: 490
        }
        Knob {
            center: false
            group: "[Master]"
            key: "headGain"
            label: "Level"
            radius: 15
            x: 140 - width / 2
            y: 490
        }
        Knob {
            group: "[Master]"
            hi: "R"
            key: "balance"
            label: "Balance"
            lo: "L"
            radius: 13
            x: 50 - width / 2
            y: 568
        }
        Dots {
            color: "#5a5a5a"
            size: 22
            text: "DJBOX"
            x: 16
            y: 700
        }
    }
    Mixxx.ControlProxy {
        id: fxOn

        group: root.fxSlotGroup
        key: "enabled"
    }
    Mixxx.ControlProxy {
        id: fxPrev

        group: root.fxSlotGroup
        key: "prev_effect"
    }
    Mixxx.ControlProxy {
        id: fxNext

        group: root.fxSlotGroup
        key: "next_effect"
    }
}
// [/AI-generated]
