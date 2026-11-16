import Mixxx 1.0 as Mixxx
import QtQuick
import "ShelfLogic.mjs" as Logic

// Woher die Platten kommen: hier die Mixxx-Bibliothek.
// Das Regal kennt nur rows() und changed(). Eine weitere Quelle (Navidrome über die Subsonic-API)
// liefert dieselben Zeilen und kann daneben gestellt werden, ohne dass sich am Regal etwas ändert:
//   { artist, title, album, albumArtist, year, genre, trackNo, duration, bpm, key, added, color, url, cover }
// url ist das, was ein Deck laden kann. Für Navidrome heißt das: Datei zuerst in den lokalen
// Zwischenspeicher holen und deren Adresse eintragen.
Item {
    id: root

    property var model: null

    signal changed

    function rows() {
        const m = model || (model = tree.allTracks());
        if (!m)
            return [];
        const n = m.rowCount(), rows = [], coverRole = Mixxx.LibraryTrackListModel.CoverArt;
        for (let r = 0; r < n; r++) {
            const d = c => m.data(m.index(r, c), Qt.DisplayRole);
            const cover = m.data(m.index(r, 0), coverRole);
            rows.push({
                "artist": d(0),
                "title": d(1),
                "album": d(2),
                "albumArtist": d(3),
                "year": d(4),
                "genre": d(5),
                "trackNo": d(6),
                "duration": d(7),
                "bpm": d(8),
                "key": d(9),
                "added": Logic.isoDate(m.data(m.index(r, 10), Qt.ToolTipRole)),
                "color": d(11),
                "url": String(m.getUrl(r)),
                "cover": cover ? String(cover) : ""
            });
        }
        return rows;
    }

    Mixxx.LibrarySourceTree {
        id: tree

        defaultColumns: [
            Mixxx.TrackListColumn {
                columnIdx: Mixxx.TrackListColumn.SQLColumns.Artist
            },
            Mixxx.TrackListColumn {
                columnIdx: Mixxx.TrackListColumn.SQLColumns.Title
            },
            Mixxx.TrackListColumn {
                columnIdx: Mixxx.TrackListColumn.SQLColumns.Album
            },
            Mixxx.TrackListColumn {
                columnIdx: Mixxx.TrackListColumn.SQLColumns.AlbumArtist
            },
            Mixxx.TrackListColumn {
                columnIdx: Mixxx.TrackListColumn.SQLColumns.Year
            },
            Mixxx.TrackListColumn {
                columnIdx: Mixxx.TrackListColumn.SQLColumns.Genre
            },
            Mixxx.TrackListColumn {
                columnIdx: Mixxx.TrackListColumn.SQLColumns.TrackNumber
            },
            Mixxx.TrackListColumn {
                columnIdx: Mixxx.TrackListColumn.SQLColumns.Duration
            },
            Mixxx.TrackListColumn {
                columnIdx: Mixxx.TrackListColumn.SQLColumns.Bpm
            },
            Mixxx.TrackListColumn {
                columnIdx: Mixxx.TrackListColumn.SQLColumns.Key
            },
            Mixxx.TrackListColumn {
                columnIdx: Mixxx.TrackListColumn.SQLColumns.DateTimeAdded
            },
            Mixxx.TrackListColumn {
                columnIdx: Mixxx.TrackListColumn.SQLColumns.CoverArtColor
            }
        ]

        Mixxx.LibraryAllTrackSource {
            columns: tree.defaultColumns
            label: "DJBOX"
        }
    }
    Connections {
        function onModelReset() {
            root.changed();
        }

        ignoreUnknownSignals: true
        target: root.model
    }
}
