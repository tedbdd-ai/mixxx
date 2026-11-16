// [AI-generated] This file was written by an AI agent (Claude, Anthropic).
pragma Singleton
import QtQuick

// DJBOX: Farben und Schriften.
// Die Bibliothek ist monochrom; Farbe tragen Cover, Pegel, Tonart und die Leuchttasten am Gerät.
QtObject {
    id: root

    readonly property color bg: "#050505"

    // Gerät
    readonly property color body: "#151617"
    readonly property color bodyHi: "#1f2022"
    readonly property color bodyLo: "#0c0d0e"
    readonly property color cue: "#ff8a1e"
    readonly property color dim: "#8b8b8b"
    readonly property string dots: dotsFont.status === FontLoader.Ready ? dotsFont.name : mono
    readonly property FontLoader dotsFont: FontLoader {
        source: Qt.resolvedUrl("fonts/DJBoxDots-Bold.ttf")
    }
    readonly property color faint: "#3a3a3a"
    readonly property color fg: "#ededed"
    readonly property color fx: "#2f8bff"
    readonly property color ink: "#c9c9c9"            // Aufdruck auf dem Gerät
    readonly property color ledAmber: "#ffb020"
    readonly property color ledGreen: "#2fe07a"
    readonly property color ledRed: "#ff3b30"
    readonly property color line: "#1f1f1f"
    readonly property string mono: monoFont.status === FontLoader.Ready ? monoFont.name : pickFamily(["Menlo", "DejaVu Sans Mono", "Courier New"])
    readonly property string monoBold: monoBoldFont.status === FontLoader.Ready ? monoBoldFont.name : mono
    readonly property FontLoader monoBoldFont: FontLoader {
        source: Qt.resolvedUrl("fonts/GeistMono-SemiBold.ttf")
    }
    readonly property FontLoader monoFont: FontLoader {
        source: Qt.resolvedUrl("fonts/GeistMono-Regular.ttf")
    }
    readonly property color panel: "#0a0a0a"
    readonly property color play: "#33e07a"
    readonly property string sans: sansFont.status === FontLoader.Ready ? sansFont.name : pickFamily(["Helvetica Neue", "Inter", "Open Sans", "Arial"])
    readonly property FontLoader sansFont: FontLoader {
        source: Qt.resolvedUrl("fonts/Geist-Regular.ttf")
    }
    readonly property string sansMedium: sansMediumFont.status === FontLoader.Ready ? sansMediumFont.name : sans
    readonly property FontLoader sansMediumFont: FontLoader {
        source: Qt.resolvedUrl("fonts/Geist-Medium.ttf")
    }
    readonly property string sansSemi: sansSemiFont.status === FontLoader.Ready ? sansSemiFont.name : sans
    readonly property FontLoader sansSemiFont: FontLoader {
        source: Qt.resolvedUrl("fonts/Geist-SemiBold.ttf")
    }
    readonly property color screen: "#000000"
    // Bausteine der Mixxx-Oberfläche mitbenutzen (Wellenformen). Aus nur in der Testumgebung.
    property bool stockWidgets: true

    function pickFamily(names) {
        const have = Qt.fontFamilies();
        for (const n of names) {
            if (have.indexOf(n) >= 0)
                return n;
        }
        return Qt.application.font.family;
    }
}
// [/AI-generated]
