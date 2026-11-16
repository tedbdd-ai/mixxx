# DJBOX – Mixxx-Fork

DJBOX ersetzt das Hauptfenster der neuen QML-Oberfläche von Mixxx durch ein Plattenregal
mit davorstehendem Set (Plattenspieler + Mixer). Audio, Bibliothek, Controller-Anbindung
und Einstellungen bleiben unverändert Mixxx.

Basis: `mixxxdj/mixxx` main, Commit `dc4bf99322bb` (2026-11-15).

## Starten

Mixxx wie gewohnt bauen (https://github.com/mixxxdj/mixxx/wiki → Compiling) und mit der
QML-Oberfläche starten:

    mixxx --new-ui --settings-path ~/.mixxx-djbox

Die QML-Oberfläche verlangt ein eigenes Einstellungsprofil; mit dem Profil einer stabilen
Mixxx-Version bricht der Start ab. Deshalb der eigene Ordner.

Schlägt das Laden von DJBOX fehl, startet die normale Mixxx-Oberfläche (siehe `res/qml/main.qml`).

## Was geändert ist

| Datei | Änderung |
|---|---|
| `res/qml/main.qml` | lädt `DJBoxWindow.qml`, bei Fehler `MainWindow.qml` |
| `res/qml/DJBoxWindow.qml` | neu: Gerüst wie `MainWindow.qml` (Menü, Befehle, Anzahl Decks, Einstellungen), Fläche = DJBOX |
| `res/qml/DJBox/` | neu: die Oberfläche |
| `src/qml/qmllibrarytracklistcolumn.h` | sechs zusätzliche Spalten für QML: AlbumArtist, Genre, TrackNumber, Duration, DateTimeAdded, CoverArtColor |

`res/qml/DJBox/`:

- `Main.qml` – Regal + Set, Stapel je Deck, Ziehen aufs Deck
- `Shelf.qml`, `ShelfLogic.mjs` – Regal: Platten bilden, sortieren, einräumen, zeichnen, blättern
- `LibrarySource.qml` – liest die Mixxx-Bibliothek (einziger Ort, der das Bibliotheksmodell kennt)
- `RecordCard.qml` – Karte der herausgezogenen Platte mit Tracklist
- `Turntable.qml`, `Vinyl.qml` – Plattenspieler = Mixxx-Deck
- `MixerPanel.qml` – Kanalzüge, Crossfader, Master
- `Knob.qml`, `Fader.qml`, `Meter.qml`, `SlideSwitch.qml`, `HwButton.qml`, `TextButton.qml`, `DotText.qml`, `CoverArt.qml`, `Style.qml`

## Wie Platten entstehen

Mixxx kennt Tracks, keine Platten. Alle Tracks mit gleichem Album und Album-Interpret sind eine
Platte; die Tracknummer ordnet die Tracklist. Tracks ohne Album sind Singles. Die Rückenfarbe ist
die Hauptfarbe des Covers, die Mixxx beim Einlesen berechnet.

## Bedienung

- Zeiger übers Regal: die Platte darunter kommt heraus.
- Zwei Finger links/rechts: Platte für Platte; hoch/runter: Reihe wechseln. Pfeiltasten ebenso.
- Klick oder Leertaste: Platte festhalten, Track in der Liste wählen, „Track n auf A“.
- Ziehen: Platte aufs Deck tragen. Eingabe: aufs erste Deck.
- Steht das Deck, liegt die neue Platte obenauf und wird geladen. Läuft es, schiebt sie sich
  darunter und ist nach DROP dran.
- Klick auf ein Band der Platte auf dem Teller: Nadel auf diesen Track.

## Belegte Mixxx-Regler

`[ChannelN]`: play, cue_default, eject, bpm, playposition, duration, track_loaded, rate, rate_ratio,
rateRange, rate_temp_up, rate_temp_down, keylock, volume, pregain, pfl, orientation, vu_meter ·
`[EqualizerRack1_[ChannelN]_Effect1]`: parameter1–3 · `[QuickEffectRack1_[ChannelN]]`: super1 ·
`[Master]`: crossfader, gain, balance, booth_gain, headMix, headGain · `[Main]`: vu_meter_left/right

## Stand

Geprüft ist die Oberfläche gegen eine Attrappe des `Mixxx`-QML-Moduls (Qt 6.12, ohne Bildschirm):
Aufbau, Blättern, Festhalten, Trackwahl, Laden, Stapel, DROP, Ziehen, vier Decks, Sortierungen.
**Nicht geprüft: der Lauf in einem echten Mixxx-Build.** Dort zuerst ansehen:

1. Startet `--new-ui` mit DJBOX, erscheinen Menü und Einstellungen?
2. Füllt sich das Regal (Spaltenzugriff, Cover-Adressen, Dauer beim Einlesen großer Sammlungen)?
3. Laden aufs Deck, Reglerwege (Tempo-Richtung, EQ), Pegel.
4. Texte sind fest auf Deutsch, noch nicht über `qsTr`.

## Ausbau: Navidrome

Navidrome spricht die Subsonic-API. Das Regal braucht von einer Quelle nur `rows()` und
`changed()` (siehe Kopf von `LibrarySource.qml`). Eine `NavidromeSource.qml` holt Alben und Tracks
über `getAlbumList2`/`getAlbum`, Cover über `getCoverArt`, und trägt als `url` die Datei im lokalen
Zwischenspeicher ein (`download` bzw. `stream`), weil ein Deck eine lokale Datei lädt.
Offen: BPM/Tonart kennt Navidrome nur, wenn sie in den Tags stehen; sonst analysiert Mixxx nach
dem Laden.
