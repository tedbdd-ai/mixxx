<!-- [AI-generated] This document was written by an AI agent (Claude, Anthropic). -->
# DJBOX – Mixxx-Fork

DJBOX ersetzt das Hauptfenster der neuen QML-Oberfläche von Mixxx: oben die Bibliothek als
Plattenregal und als Trackliste, darunter das Set aus Playern und einem Vierkanal-Mixer im
Club-Layout. Audio, Bibliothek, Controller-Anbindung und Einstellungen bleiben Mixxx.

Basis: `mixxxdj/mixxx` main, Commit `dc4bf99322bb` (2026-11-15).

## Bauen und starten (macOS)

    git clone -b djbox-ui https://github.com/tedbdd-ai/mixxx.git
    cd mixxx
    source tools/macos_buildenv.sh setup
    mkdir build && cd build
    cmake ..
    cmake --build . --parallel $(sysctl -n hw.ncpu)
    ./mixxx --new-ui --settings-path ~/.mixxx-djbox

Die QML-Oberfläche verlangt ein eigenes Einstellungsprofil; mit dem Profil einer stabilen
Mixxx-Version bricht der Start ab. Deshalb der eigene Ordner. Schlägt das Laden von DJBOX
fehl, startet die normale Mixxx-Oberfläche (siehe `res/qml/main.qml`).

## Aufbau des Bildschirms

- **Kopfzeile:** Ansicht (Regal, Regal + Liste, Liste), Sortierung, Suche (⌃F), Zähler,
  „+ Player“, „Set“ ein/aus, Einstellungen.
- **Bibliothek:** Regal und Liste zeigen dieselbe Sammlung in derselben Reihenfolge.
  Suche filtert beide. Ein Track in der Liste zieht seine Platte im Regal heraus; eine Platte
  im Regal markiert ihre Tracks in der Liste. Ein Klick auf einen Spaltenkopf sortiert die
  Liste nach dieser Spalte, ein dritter Klick kehrt zur Regal-Reihenfolge zurück.
- **Griff** zwischen Bibliothek und Set: ziehen verteilt die Höhe, das Set skaliert mit.
- **Player** (je Mixxx-Deck): Display mit Titel, Interpret, Platte, Track-Wahl, großer
  Wellenform, Restzeit, Tempo, Tonart, BPM und Übersicht; Hot Cues A–H (Rechtsklick löscht),
  Loop IN/OUT/RELOOP, 4/8-Beat-Loop, TRACK ◀ ▶, Spulen, CUE, PLAY, Jograd, SYNC, MASTER,
  MT (Key Lock), Tempobereich, Tempofader, DROP.
- **Mixer:** Kanäle 1–4 (Trim, Hi/Mid/Low, Pegelkette, Color, CUE, Fader, A/THRU/B),
  Crossfader, Master Level, Booth, Pegel L/R, Beat FX (Effekteinheit 1: Effekt wählen,
  Kanalzuweisung, Level/Depth, ON/OFF), Kopfhörer Mixing/Level, Balance.

## Bedienung

- Zeiger übers Regal: die Platte darunter kommt heraus.
- Zwei Finger links/rechts: Platte für Platte; hoch/runter: Reihe wechseln. Pfeiltasten ebenso.
- Klick oder Leertaste: Platte festhalten, Track in der Liste wählen, „Track n auf A“.
- Ziehen aus Regal oder Liste: Platte auf einen Player tragen. Doppelklick in der Liste und
  Eingabe laden aufs erste Deck.
- Steht der Player, liegt die neue Platte obenauf und wird geladen. Läuft er, schiebt sie sich
  darunter und ist nach DROP dran.
- Jograd: oben anfassen = scratchen, am Ring drehen = Tempo biegen.

## Was geändert ist

| Datei | Änderung |
|---|---|
| `res/qml/main.qml` | lädt `DJBoxWindow.qml`, bei Fehler `MainWindow.qml` |
| `res/qml/DJBoxWindow.qml` | Gerüst wie `MainWindow.qml` (Menü, Befehle, Anzahl Decks, Einstellungen) |
| `res/qml/DJBox/` | die Oberfläche |
| `res/qml/DJBox/fonts/` | Geist, Geist Mono und eine Punktmatrix-Schrift aus Doto (SIL OFL 1.1) |
| `src/qml/qmllibrarytracklistcolumn.h` | sechs zusätzliche Spalten für QML |

`res/qml/DJBox/`: `Main.qml` (Aufbau, Stapel, Ziehen), `Library.qml`, `Shelf.qml`,
`ShelfLogic.mjs`, `TrackList.qml`, `RecordCard.qml`, `LibrarySource.qml` (einziger Ort, der
das Bibliotheksmodell kennt), `Player.qml`, `JogWheel.qml`, `Mixer.qml` und Bausteine
(`Knob`, `Fader`, `Meter`, `HwButton`, `RoundButton`, `SlideSwitch`, `TextButton`, `Dots`,
`CoverArt`, `Vinyl`, `Style`). `FakeWave.qml` wird nur in der Testumgebung ohne Mixxx benutzt.

## Leistung

Alles, was sich während des Spielens bewegt, besteht aus einfachen Elementen: Ziffern sind
eine Schrift, Pegel und Regler Rechtecke, das Regal wird spaltenweise und nur sichtbar gebaut.
Gezeichnet (Canvas) werden nur noch die Ersatzhüllen für Platten ohne Cover, einmal je Platte.

## Diagnose

Beim Einräumen schreibt das Regal eine Zeile ins Mixxx-Log:

    DJBOX shelf: 62 Platten in 2 Fächern, je Fach: 39,23

## Stand

Geprüft gegen eine Attrappe des `Mixxx`-QML-Moduls (Qt 6.12, ohne Bildschirm). Nicht geprüft
in einem echten Mixxx-Lauf: Wellenformen, Effektnamen, Scratchen, Hot-Cue-Farben,
Tempo-Richtung. Texte sind fest auf Deutsch, noch nicht über `qsTr`.

## Ausbau: Navidrome

Navidrome spricht die Subsonic-API. Das Regal braucht von einer Quelle nur `rows()` und
`changed()` (siehe Kopf von `LibrarySource.qml`). Eine `NavidromeSource.qml` holt Alben und
Tracks über `getAlbumList2`/`getAlbum`, Cover über `getCoverArt`, und trägt als `url` die
Datei im lokalen Zwischenspeicher ein, weil ein Deck eine lokale Datei lädt.
<!-- [/AI-generated] -->
