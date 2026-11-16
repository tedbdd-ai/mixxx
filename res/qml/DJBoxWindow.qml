import "." as Skin
import "DJBox" as DJBox
import Mixxx 1.0 as Mixxx
import QtQuick
import QtQuick.Controls
import QtQuick.Window

// DJBOX als Hauptfenster von Mixxx. Das Gerüst (Menü, Befehle, Anzahl der Decks, Einstellungen)
// entspricht MainWindow.qml; die Fläche darüber ist das Plattenregal mit dem Set.
Item {
    id: root

    required property ApplicationWindow applicationWindow
    property alias menuBar: nativeApplicationMenuLoader.item
    readonly property int numDecks: 4
    readonly property int numPreviewDecks: 1
    readonly property int numSamplers: 16
    readonly property int waveformOverviewTypeRgb: 2

    Loader {
        id: nativeApplicationMenuLoader

        active: Qt.platform.os === "osx" || (Mixxx.Application.supportsGlobalMenuBar && root.applicationWindow.visibility !== Window.FullScreen)

        sourceComponent: Skin.MainMenuBar {
            actions: applicationMenuActions
        }
    }
    Skin.ApplicationMenuCommands {
        id: applicationMenuCommands

        applicationWindow: root.applicationWindow

        onShowDeveloperToolsRequested: {
            devToolsWindow.show();
            devToolsWindow.raise();
            devToolsWindow.requestActivate();
        }
    }
    Skin.ApplicationMenuActions {
        id: applicationMenuActions

        applicationWindow: root.applicationWindow
        commands: applicationMenuCommands
        numberOfDecks: djbox.deckCount

        onFocusLibrarySearchRequested: djbox.shelf.forceActiveFocus()
    }
    Skin.LibraryScanSummaryDialog {
    }
    Skin.DeveloperToolsWindow {
        id: devToolsWindow

        height: 480
        width: 640
    }
    // Ohne diese Werte legt Mixxx keine Decks an
    Mixxx.ControlProxy {
        group: "[App]"
        key: "num_decks"

        onInitializedChanged: {
            value = root.numDecks;
        }
    }
    Mixxx.ControlProxy {
        group: "[App]"
        key: "num_samplers"

        onInitializedChanged: {
            value = root.numSamplers;
        }
    }
    Mixxx.ControlProxy {
        group: "[App]"
        key: "num_preview_decks"

        onInitializedChanged: {
            value = root.numPreviewDecks;
        }
    }
    Mixxx.ControlProxy {
        group: "[Waveform]"
        key: "WaveformOverviewType"

        onInitializedChanged: {
            value = root.waveformOverviewTypeRgb;
        }
    }
    DJBox.Main {
        id: djbox

        anchors.fill: parent

        onPreferencesRequested: settingsPopup.open()
    }
    Skin.Settings {
        id: settingsPopup

        height: Math.min(840, parent.height)
        modal: true
        width: Math.min(1400, parent.width)
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)

        Overlay.modal: Rectangle {
            color: Qt.rgba(0, 0, 0, 0.6)
        }
    }
}
