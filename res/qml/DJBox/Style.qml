pragma Singleton
import QtQuick

// DJBOX: Farben und Schriften. Monochrom; Farbe tragen nur Cover, Pegel und Tonart.
QtObject {
    readonly property color bg: "#050505"
    readonly property color dim: "#8b8b8b"
    readonly property color faint: "#3a3a3a"
    readonly property color fg: "#ededed"
    readonly property color ink: "#cfcfcf"
    readonly property color ledAmber: "#ffb020"
    readonly property color ledGreen: "#3ddc84"
    readonly property color ledRed: "#ff3b30"
    readonly property color line: "#1f1f1f"
    readonly property string mono: pickFamily(["Geist Mono", "JetBrains Mono", "Ubuntu Mono", "DejaVu Sans Mono", "Menlo", "Courier New"])
    readonly property color panel: "#0a0a0a"
    readonly property string sans: pickFamily(["Geist", "Inter", "Helvetica Neue", "Open Sans", "Ubuntu", "Arial"])
    // Bausteine der Mixxx-Oberfläche mitbenutzen (echte Wellenform). Aus nur in der Testumgebung.
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
