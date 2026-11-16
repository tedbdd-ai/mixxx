// [AI-generated] This file was written by an AI agent (Claude, Anthropic).
import Mixxx 1.0 as Mixxx
import QtQuick
import "."

// Jograd: außen der Ring mit Griffmulden, oben die Teller-Fläche, in der Mitte ein rundes Display
// mit dem Cover der Platte und der drehenden Positionsmarke.
// Oben anfassen = scratchen (scratch2), am Ring drehen = Tempo biegen (jog).
Item {
    id: root

    readonly property real angle: (position.value * duration.value / 1.8 * 360) % 360   // 33⅓ U/min
    required property string group
    property var rec: null
    property real size: 300

    height: size
    width: size

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
        id: scratchEnable

        group: root.group
        key: "scratch2_enable"
    }
    Mixxx.ControlProxy {
        id: scratch

        group: root.group
        key: "scratch2"
    }
    Mixxx.ControlProxy {
        id: jog

        group: root.group
        key: "jog"
    }
    // Gehäusering
    Rectangle {
        anchors.fill: parent
        border.color: "#2c2d30"
        border.width: 1
        color: "#0d0e0f"
        radius: width / 2
    }
    // Griffring mit Mulden: dreht mit
    Item {
        anchors.fill: parent
        rotation: root.angle

        Rectangle {
            anchors.centerIn: parent
            border.color: "#3b3c40"
            border.width: 1
            height: width
            radius: width / 2
            width: root.size - 10

            gradient: Gradient {
                GradientStop {
                    color: "#3a3b3f"
                    position: 0
                }
                GradientStop {
                    color: "#1b1c1e"
                    position: 1
                }
            }
        }
        Repeater {
            model: 48

            Rectangle {
                required property int index

                antialiasing: true
                color: "#141516"
                height: 9
                radius: 3
                rotation: index * 7.5
                transformOrigin: Item.Center
                width: 6
                x: root.size / 2 - 3 + Math.sin(index * 7.5 * Math.PI / 180) * (root.size / 2 - 14)
                y: root.size / 2 - 4.5 - Math.cos(index * 7.5 * Math.PI / 180) * (root.size / 2 - 14)
            }
        }
    }
    // Tellerfläche
    Rectangle {
        anchors.centerIn: parent
        border.color: "#000000"
        border.width: 2
        height: width
        radius: width / 2
        width: root.size - 44

        gradient: Gradient {
            GradientStop {
                color: "#2a2b2e"
                position: 0
            }
            GradientStop {
                color: "#0a0a0b"
                position: 0.5
            }
            GradientStop {
                color: "#1c1d20"
                position: 1
            }
        }
    }
    // Display in der Mitte
    Rectangle {
        id: display

        anchors.centerIn: parent
        border.color: "#48494d"
        border.width: 2
        color: "#000000"
        height: width
        radius: width / 2
        width: root.size * 0.42

        CoverArt {
            anchors.centerIn: parent
            height: width
            rec: root.rec
            visible: root.rec !== null
            width: display.width * 0.6
        }
        Item {
            anchors.fill: parent
            rotation: root.angle

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#ffffff"
                height: display.width * 0.13
                radius: 1.5
                width: 3
                y: 3
            }
        }
    }
    MouseArea {
        id: touch

        property real acc: 0
        property real last: 0
        property string mode: ""

        function angleAt(x, y) {
            return Math.atan2(y - root.size / 2, x - root.size / 2) * 180 / Math.PI;
        }

        anchors.fill: parent

        onPositionChanged: m => {
            if (!pressed)
                return;
            const a = angleAt(m.x, m.y);
            let d = a - last;
            if (d > 180)
                d -= 360;
            if (d < -180)
                d += 360;
            last = a;
            acc += d;
        }
        onPressed: m => {
            const r = Math.hypot(m.x - root.size / 2, m.y - root.size / 2);
            if (r > root.size / 2) {
                m.accepted = false;
                return;
            }
            mode = r < root.size / 2 - 26 ? "touch" : "ring";
            last = angleAt(m.x, m.y);
            acc = 0;
            if (mode === "touch") {
                scratch.value = 0;
                scratchEnable.value = 1;
            }
            tick.start();
        }
        onReleased: {
            tick.stop();
            if (mode === "touch")
                scratchEnable.value = 0;
            jog.value = 0;
            mode = "";
        }

        Timer {
            id: tick

            interval: 16
            repeat: true

            onTriggered: {
                // 200 °/s entsprechen 33⅓ U/min, also normaler Geschwindigkeit
                if (touch.mode === "touch")
                    scratch.value = touch.acc / (interval / 1000) / 200;
                else if (touch.acc !== 0)
                    jog.value = touch.acc / 4;
                touch.acc = 0;
            }
        }
    }
}
// [/AI-generated]
