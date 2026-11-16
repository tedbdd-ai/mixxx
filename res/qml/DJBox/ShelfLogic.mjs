// DJBOX: reine Logik fürs Plattenregal. Keine Abhängigkeit zu Mixxx, damit dieselben
// Funktionen später auch eine andere Quelle (z. B. Navidrome/Subsonic) bedienen können.
// Eine Quelle liefert Zeilen der Form
//   { artist, albumArtist, album, title, year, genre, trackNo, duration, bpm, key, added, color, url, cover }
// und daraus werden "Platten" (Alben) mit Tracklist.

export const ROWS = 3;
export const FW = 254;      // Breite eines Fachs samt Stahlkante
export const T = 4;         // Stärke der Stahlkante
export const IN = 250;      // Innenmaß eines Fachs
export const Y0 = 50;       // oberer Rand der Wand
export const X0 = 60;       // linker Rand der Wand
export const PITCH = 4;     // Abstand von Rücken zu Rücken
export const COVER = 204;   // Kantenlänge der herausgezogenen Hülle

const PAL = [
    ["#e9e2d0", "#1b1b1b", "#c8452f"], ["#f2c230", "#1d1d1b", "#e8e0cf"], ["#2d5c8a", "#e8dfc9", "#d8572a"], ["#151515", "#e7e7e7", "#8a8a8a"],
    ["#d9cdb4", "#5b3a29", "#c98b2b"], ["#7a2e4d", "#f0d9b5", "#1c1c1c"], ["#3c7a5a", "#e6e0cf", "#f08a24"], ["#e85d2a", "#232323", "#f3ead7"],
    ["#b8b2a4", "#2a2a2a", "#d83a34"], ["#1f3b4d", "#e2c044", "#f1ece1"], ["#efe9dc", "#2b4c7e", "#e0a526"], ["#262626", "#ff5a36", "#ededed"],
    ["#c9b28a", "#27412f", "#f4efe2"], ["#5b4a8a", "#f0e6c8", "#f29f3d"], ["#f4f1ea", "#111111", "#2f6f6a"], ["#c8322b", "#f3e9d2", "#1a1a1a"],
    ["#1c8a8a", "#f4e4c1", "#e6532d"], ["#3158c9", "#f5d53a", "#f2eee4"], ["#f08a24", "#27324d", "#f7efe0"]
];
const NEUTRAL = ["#e9e6de", "#dcd6c8", "#f3f1ec", "#151515", "#0d0d0d", "#cfc8b8", "#8d8a84"];

export function hash(s) {
    let h = 2166136261;
    for (let i = 0; i < s.length; i++) {
        h ^= s.charCodeAt(i);
        h = Math.imul(h, 16777619);
    }
    return h >>> 0;
}
export function rng(seed) {
    let a = seed | 0;
    return function() {
        a = a + 0x6D2B79F5 | 0;
        let t = Math.imul(a ^ a >>> 15, 1 | a);
        t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
        return ((t ^ t >>> 14) >>> 0) / 4294967296;
    };
}
// Mixxx liefert je nach Spalte Zahlen oder schon formatierten Text
export function num(v) {
    if (typeof v === "number")
        return isFinite(v) ? v : 0;
    if (v === undefined || v === null)
        return 0;
    const f = parseFloat(String(v).replace(",", "."));
    return isFinite(f) ? f : 0;
}
export function seconds(v) {
    if (typeof v === "number")
        return v;
    const s = String(v === undefined || v === null ? "" : v).trim();
    if (s.indexOf(":") < 0)
        return num(s);
    let total = 0;
    for (const part of s.split(":"))
        total = total * 60 + num(part);
    return total;
}
// "Hinzugefügt" kommt aus Mixxx als Datum; sortierbar wird es als ISO-Text
export function isoDate(v) {
    if (v instanceof Date)
        return isNaN(v.getTime()) ? "" : v.toISOString();
    return v === undefined || v === null ? "" : String(v);
}
export function yearOf(v) {
    const m = /(\d{4})/.exec(String(v === undefined || v === null ? "" : v));
    return m ? parseInt(m[1], 10) : 0;
}
export function colorOf(v) {
    if (typeof v === "number")
        return v >= 0 && v <= 0xffffff ? "#" + Math.round(v).toString(16).padStart(6, "0") : "";
    const s = String(v === undefined || v === null ? "" : v);
    return /^#[0-9a-fA-F]{6}$/.test(s) ? s.toLowerCase() : "";
}
export function fmtTime(s) {
    s = Math.max(0, Math.round(s));
    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
}
function rgbOf(hex) {
    return [parseInt(hex.substr(1, 2), 16), parseInt(hex.substr(3, 2), 16), parseInt(hex.substr(5, 2), 16)];
}
export function lum(hex) {
    const c = rgbOf(hex);
    return (0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]) / 255;
}
export function hslOf(hex) {
    const c = rgbOf(hex).map(v => v / 255), r = c[0], g = c[1], b = c[2];
    const mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2, d = mx - mn;
    let h = 0, s = 0;
    if (d) {
        s = d / (1 - Math.abs(2 * l - 1));
        h = mx === r ? ((g - b) / d) % 6 : mx === g ? (b - r) / d + 2 : (r - g) / d + 4;
        h = (h * 60 + 360) % 360;
    }
    return {
        "h": h,
        "s": s,
        "l": l
    };
}
// Camelot-Rad: jede Tonart bekommt ihre Farbe
export function keyColor(k) {
    const n = parseInt(k, 10);
    if (isNaN(n))
        return "#ededed";
    const major = /B/i.test(String(k));
    return hslToHex(((n - 1) * 30 + 150) % 360, major ? 0.7 : 0.6, major ? 0.68 : 0.62);
}
export function hslToHex(h, s, l) {
    const c = (1 - Math.abs(2 * l - 1)) * s, x = c * (1 - Math.abs((h / 60) % 2 - 1)), m = l - c / 2;
    const rgb = h < 60 ? [c, x, 0] : h < 120 ? [x, c, 0] : h < 180 ? [0, c, x] : h < 240 ? [0, x, c] : h < 300 ? [x, 0, c] : [c, 0, x];
    return "#" + rgb.map(v => Math.round((v + m) * 255).toString(16).padStart(2, "0")).join("");
}

// Zeilen der Quelle zu Platten zusammenfassen: gleiche Kombination aus Album und Album-Interpret = eine Platte.
// Tracks ohne Album sind Singles und bekommen jede ihre eigene Hülle.
export function buildRecords(rows) {
    const byKey = new Map();
    const out = [];
    for (const t of rows) {
        const album = (t.album || "").trim();
        const who = (t.albumArtist || t.artist || "").trim();
        const key = album ? who.toLowerCase() + "\u0001" + album.toLowerCase() : "\u0002" + t.url;
        let rec = byKey.get(key);
        if (!rec) {
            rec = {
                "id": out.length,
                "artist": who || "Unbekannt",
                "title": album || t.title || "Ohne Titel",
                "single": !album,
                "tracks": [],
                "genre": "",
                "year": 0,
                "added": "",
                "cover": "",
                "coverColor": "",
                "pick": 0
            };
            byKey.set(key, rec);
            out.push(rec);
        }
        rec.tracks.push({
            "url": t.url,
            "title": t.title || "Ohne Titel",
            "artist": t.artist || "",
            "no": num(t.trackNo),
            "bpm": num(t.bpm),
            "key": t.key ? String(t.key) : "",
            "dur": seconds(t.duration)
        });
        if (!rec.genre && t.genre)
            rec.genre = String(t.genre);
        if (!rec.year)
            rec.year = yearOf(t.year);
        if (t.added && String(t.added) > rec.added)
            rec.added = String(t.added);
        if (!rec.cover && t.cover)
            rec.cover = String(t.cover);
        if (!rec.coverColor)
            rec.coverColor = colorOf(t.color);
    }
    for (const rec of out) {
        rec.tracks.sort((a, b) => (a.no || 999) - (b.no || 999) || a.title.localeCompare(b.title));
        rec.tracks.forEach((t, i) => {
            t.pos = String(t.no || i + 1);
        });
        const first = rec.tracks.find(t => t.bpm > 0) || rec.tracks[0];
        rec.bpm = first.bpm;
        rec.key = (rec.tracks.find(t => t.key) || rec.tracks[0]).key;
        rec.dur = rec.tracks.reduce((s, t) => s + t.dur, 0);
        rec.seed = hash(rec.artist + "|" + rec.title);
        const R = rng(rec.seed);
        rec.pal = PAL[Math.floor(R() * PAL.length)];
        rec.style = Math.floor(R() * 8);
        // Rückenfarbe: die Hauptfarbe des Covers, wenn Mixxx sie kennt, sonst aus der erzeugten Hülle
        rec.color = rec.coverColor || rec.pal[0];
        const full = !!rec.coverColor || R() > 0.2;
        rec.tone = full ? rec.color : NEUTRAL[Math.floor(R() * NEUTRAL.length)];
        rec.hsl = hslOf(rec.tone);
        rec.h = R() > 0.95 ? 198 : 222 + Math.floor(R() * 12);
        rec.band = null;
        if (!full && hslOf(rec.color).s > 0.14)
            rec.band = {
                "y": 0.25 + R() * 0.55,
                "len": 12 + R() * 40,
                "c": rec.color
            };
        else if (full && R() > 0.55)
            rec.band = {
                "y": 0.2 + R() * 0.6,
                "len": 8 + R() * 30,
                "c": rec.pal[1]
            };
    }
    return out;
}

function sortKey(r, mode) {
    if (mode === "az") {
        const c = (r.artist[0] || "#").toUpperCase();
        return /[A-ZÄÖÜ]/.test(c) ? c : "#";
    }
    if (mode === "genre")
        return r.genre || "Ohne Genre";
    if (mode === "bpm")
        return r.bpm ? String(Math.floor(r.bpm / 10) * 10) : "?";
    if (mode === "neu")
        return yearOf(r.added) ? String(yearOf(r.added)) : "?";
    if (mode === "jahr")
        return r.year ? String(Math.floor(r.year / 10) * 10) + "er" : "?";
    return "";
}
export function sortRecords(list, mode) {
    const cmp = (a, b) => (a.artist + a.title).toLowerCase().localeCompare((b.artist + b.title).toLowerCase());
    if (mode === "az")
        list.sort(cmp);
    else if (mode === "genre")
        list.sort((a, b) => (a.genre || "~").localeCompare(b.genre || "~") || cmp(a, b));
    else if (mode === "bpm")
        list.sort((a, b) => (a.bpm || 999) - (b.bpm || 999));
    else if (mode === "neu")
        list.sort((a, b) => b.added.localeCompare(a.added));
    else if (mode === "jahr")
        list.sort((a, b) => (a.year || 9999) - (b.year || 9999) || cmp(a, b));
    else if (mode === "zufall")
        for (let i = list.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            const tmp = list[i];
            list[i] = list[j];
            list[j] = tmp;
        }
    else
        list.sort((a, b) => {
            const A = a.hsl, B = b.hsl;
            const ga = A.s < 0.14 || A.l < 0.1 || A.l > 0.92, gb = B.s < 0.14 || B.l < 0.1 || B.l > 0.92;
            if (ga !== gb)
                return ga ? 1 : -1;
            if (ga)
                return A.l - B.l;
            return ((A.h + 20) % 360) - ((B.h + 20) % 360) || A.l - B.l;
        });
}

export function fachX(f) {
    return X0 + Math.floor(f / ROWS) * FW + T;
}
export function fachYB(f) {
    return Y0 + T + IN + (f % ROWS) * FW;
}

// Platten in die Fächer stellen. Die Wand wächst mit der Sammlung: so viele Spalten wie nötig.
export function layout(records, mode) {
    const list = records.filter(r => !r.away);
    sortRecords(list, mode);
    const cols = Math.max(7, Math.ceil(list.length / (ROWS * 52)) + 1);
    const fachs = [];
    for (let f = 0; f < cols * ROWS; f++)
        fachs.push({
            "f": f,
            "recs": [],
            "dividers": [],
            "label": ""
        });
    const reserve = f => (hash("fach" + f) % 5) * 9;
    let f = 0, x = 0, last = null;
    for (const r of list) {
        const key = sortKey(r, mode);
        if (key !== last && key !== "") {
            if (x + 8 + PITCH > IN - 8 - reserve(f)) {
                f++;
                x = 0;
            }
            if (f < fachs.length) {
                fachs[f].dividers.push({
                    "x": fachX(f) + 4 + x,
                    "label": key
                });
                x += 6;
            }
            last = key;
        }
        if (x + PITCH > IN - 8 - reserve(f)) {
            f++;
            x = 0;
        }
        if (f >= fachs.length) {
            r.f = -1;
            continue;
        }
        r.f = f;
        r.tx = fachX(f) + 4 + x;
        r.ty = fachYB(f);
        r.rot = 0;
        fachs[f].recs.push(r);
        x += PITCH;
    }
    const two = (p, q) => p === q ? p : p + " – " + q;
    for (const fa of fachs) {
        const n = fa.recs.length;
        if (!n)
            continue;
        const a = fa.recs[0], b = fa.recs[n - 1];
        // am Fachende lehnen ein paar Platten schräg, wenn Luft ist
        if (fachX(fa.f) + IN - 4 - (b.tx + 4) > 22 && n > 6)
            for (let i = Math.max(0, n - 4); i < n; i++) {
                fa.recs[i].rot = -0.11;
                fa.recs[i].tx += 22;
            }
        fa.dividers.forEach((d, i) => {
            const nx = fa.dividers[i + 1];
            d.maxW = (nx ? nx.x : fachX(fa.f) + IN) - d.x - 2;
        });
        fa.label = mode === "az" ? a.artist.slice(0, 2) + "–" + b.artist.slice(0, 2) : mode === "genre" ? two(a.genre || "Ohne Genre", b.genre || "Ohne Genre") : mode === "bpm" ? (a.bpm ? a.bpm.toFixed(0) : "?") + "–" + (b.bpm ? b.bpm.toFixed(0) : "?") + " BPM" : mode === "neu" ? two(String(yearOf(a.added) || "?"), String(yearOf(b.added) || "?")) : mode === "jahr" ? two(String(a.year || "?"), String(b.year || "?")) : "";
    }
    return {
        "cols": cols,
        "fachs": fachs,
        "count": list.length,
        "width": X0 * 2 + cols * FW + T,
        "height": Y0 + ROWS * FW + 30
    };
}

// Erzeugte Hülle für Platten ohne Coverbild: zeichnet in einen 2D-Kontext der Kantenlänge s
export function drawSleeve(ctx, rec, s) {
    const R = rng(rec.seed), a = rec.pal[0], b = rec.pal[1], d = rec.pal[2], st = rec.style;
    ctx.fillStyle = a;
    ctx.fillRect(0, 0, s, s);
    if (st === 0) {
        const cx = s * (0.3 + R() * 0.4), cy = s * (0.3 + R() * 0.4);
        for (let i = 7; i > 0; i--) {
            ctx.fillStyle = i % 2 ? b : d;
            ctx.beginPath();
            ctx.arc(cx, cy, i * s * 0.075, 0, Math.PI * 2);
            ctx.fill();
        }
    } else if (st === 1) {
        ctx.save();
        ctx.translate(s / 2, s / 2);
        ctx.rotate((R() - 0.5) * 1.6);
        const w = s * (0.05 + R() * 0.08);
        for (let i = -s; i < s; i += w * 2) {
            ctx.fillStyle = R() > 0.8 ? d : b;
            ctx.fillRect(i, -s, w, 2 * s);
        }
        ctx.restore();
    } else if (st === 2) {
        const n = 9 + Math.floor(R() * 8), ph = R() * 3;
        ctx.fillStyle = b;
        for (let i = 0; i < n; i++)
            for (let j = 0; j < n; j++) {
                const r = (s / n) * 0.48 * Math.abs(Math.sin(i * 0.6 + ph) * Math.cos(j * 0.5 + ph));
                ctx.beginPath();
                ctx.arc((i + 0.5) * s / n, (j + 0.5) * s / n, r, 0, Math.PI * 2);
                ctx.fill();
            }
    } else if (st === 3) {
        for (let i = 0; i < 5; i++) {
            ctx.fillStyle = [b, d, a][i % 3];
            ctx.fillRect(R() * s * 0.7, R() * s * 0.7, s * (0.2 + R() * 0.5), s * (0.2 + R() * 0.5));
        }
    } else if (st === 4) {
        let y = s * 0.12;
        while (y < s * 0.8) {
            const h = s * (0.02 + R() * 0.1);
            ctx.fillStyle = R() > 0.5 ? b : d;
            ctx.fillRect(0, y, s, h);
            y += h + s * (0.02 + R() * 0.05);
        }
    } else if (st === 5) {
        for (let i = 0; i < 9; i++) {
            ctx.fillStyle = [b, d][i % 2];
            ctx.beginPath();
            ctx.moveTo(R() * s, R() * s);
            ctx.lineTo(R() * s, R() * s);
            ctx.lineTo(R() * s, R() * s);
            ctx.fill();
        }
    } else if (st === 6) {
        // Lochhülle: man sieht das Label
        ctx.fillStyle = "#050505";
        ctx.beginPath();
        ctx.arc(s / 2, s / 2, s * 0.17, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = d;
        ctx.beginPath();
        ctx.arc(s / 2, s / 2, s * 0.15, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = "#050505";
        ctx.beginPath();
        ctx.arc(s / 2, s / 2, s * 0.012, 0, Math.PI * 2);
        ctx.fill();
    } else {
        ctx.strokeStyle = b;
        ctx.lineWidth = s * 0.012;
        for (let i = 0; i < 16; i++) {
            ctx.beginPath();
            for (let k = 0; k <= s; k += 4) {
                const y = s * (0.1 + i * 0.052) + Math.sin(k * 0.04 * (256 / s) + i * 0.5) * s * 0.03 * (1 + i * 0.15);
                if (k)
                    ctx.lineTo(k, y);
                else
                    ctx.moveTo(k, y);
            }
            ctx.stroke();
        }
    }
    if (st !== 6) {
        const top = R() > 0.5, y0 = top ? s * 0.06 : s * 0.78;
        ctx.fillStyle = a;
        ctx.fillRect(s * 0.05, y0, s * 0.9, s * 0.16);
        ctx.fillStyle = lum(a) > 0.55 ? "#141414" : "#f2efe6";
        ctx.textBaseline = "top";
        ctx.font = "bold " + Math.round(s * 0.066) + "px sans-serif";
        ctx.fillText(rec.artist.toUpperCase().slice(0, 20), s * 0.07, y0 + s * 0.012);
        ctx.font = Math.round(s * 0.05) + "px sans-serif";
        ctx.fillText(rec.title.slice(0, 28), s * 0.07, y0 + s * 0.09);
    }
}
