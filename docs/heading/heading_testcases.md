# Heading-PR — Testfälle (Tokenizer · SpanBuilder · Parser)

Jeder Block enthält den **Eingabe-String** (in einem Code-Fence, damit Marker
nicht gerendert werden), gefolgt von einem Kommentar: was erwartet wird und —
bei den Verdachtsfällen — warum die aktuelle Implementierung wahrscheinlich
abweicht. Verweise auf konkrete Code-Stellen sind in Klammern.

Konvention: `␣` = Leerzeichen (wo Whitespace relevant und sonst unsichtbar ist),
`⏎` = `\n`, `␍` = `\r`. In den realen Eingabe-Strings stehen echte Zeichen.

---

## A · Wahrscheinliche Fehler (test-first — sollten VOR dem Fix fehlschlagen)

### A1 — Sieben Hashes: kein Heading, aber wird zerstückelt

```
####### Titel
```

Erwartet (CommonMark): 7+ `#` sind **kein** Heading. Die gesamte Sequenz
`####### Titel` ist Plain-Text.

Vermutetes Ist-Verhalten: Die Zähl-Schleife stoppt bei `count == 6`
(`while (count < 6 …)`). Danach sucht `markerLength` ab `pos+6` nach einem Space,
findet aber das **siebte `#`** → `markerLength == count == 6` → `pos++; continue;`.
Ein `#` wird verschluckt, die restlichen sechs `#` + ` Titel` bleiben. Ergebnis:
zerstückelter Text statt unverändertem Plain-Text. Im Editor zuckt das sichtbar,
während der User das siebte `#` tippt.

---

### A2 — Hash ohne Space: Hashtag-artiger Text

```
#kein-space
```

Erwartet: kein Heading (ATX verlangt mindestens einen Space nach den `#`).
Die komplette Zeile bleibt unveränderter Plain-Text `#kein-space`.

Vermutetes Ist-Verhalten: `markerLength == count` (kein Space gefunden) →
`pos++; continue;`. Dieser Pfad umgeht die Schleifen-Schluss-Sicherung
(`if (pos == startPosInLoop …)`) und committet **kein** `addTextToken`. Korrektheit
hängt allein daran, dass `textStart` nie zurückgesetzt wurde. Prüfen: bleibt der
String exakt erhalten, auch in Kombination (siehe A3)?

---

### A3 — Hash ohne Space, gefolgt von Inline-Marker

```
#tag *kursiv*
```

Erwartet: `#tag ` bleibt Plain-Text, `*kursiv*` wird kursiv gerendert.
Zeichenzahl im Editor exakt = Eingabelänge (1:1-Invariante).

Vermutetes Ist-Verhalten: Kritischer Kombinationsfall für den `pos++; continue;`-
Pfad aus A2. Wenn das `#` über `continue` übersprungen wird, ohne `addTextToken`,
muss der nachfolgende `*`-Zweig das `#tag ` über sein eigenes
`addTextToken(textStart, pos)` mitnehmen. Verifizieren, dass `textStart` dabei
noch korrekt **vor** dem `#` steht und kein Zeichen doppelt/verloren geht.

---

### A4 — CRLF vor Hash (Windows / eingefügter Text)

```
Zeile1␍⏎# Titel
```

(Echte Eingabe: `Zeile1\r\n# Titel`)

Erwartet: `# Titel` ist ein gültiges H1 — der Zeilenanfang gilt auch nach `\r\n`.

Vermutetes Ist-Verhalten: `atLineStart` prüft nur
`text.codeUnitAt(pos - 1) == kNewline`. Bei `\r\n` ist das Zeichen direkt vor `#`
ein `\r`, nicht `\n` → `atLineStart == false` → **kein** Heading. CRLF-Blindheit.
Read-only und Editor sind hier konsistent falsch (gleicher Tokenizer), aber für
einen `#`-Anspruch ist es ein echter Bug.

---

### A5 — Offener Inline-Marker in Heading-Zeile (Editor, Zwischenzustand)

```
# Titel **fett
```

Erwartet (Editor, Cursor am Ende): 1:1-Invariante hält; `# ` als Heading-Marker
sichtbar/gedimmt; `**` als gedimmter Marker; `fett` im Heading-Stil. Nach einem
später getippten `⏎` fällt der Folgetext auf `baseStyle` zurück — **nicht** auf
einen Heading-kontaminierten Stil.

Vermutetes Ist-Verhalten: `endHeading()` re-resolved den gesamten `formatStack`
gegen `baseStyle` als Wurzel. Solange `**` vor dem `\n` schließt, ist der Stack
beim `endHeading()` leer → harmlos. Hier ist `**` aber **offen**, wenn das
Newline-Handling in `appendText` greift oder ein zweites Heading-Token folgt →
`endHeading()` läuft mit nicht-leerem Stack und resolved gegen die falsche Wurzel
(`baseStyle` statt `_headingStyle`). Die Opening-Marker-Logik nutzt dagegen
`currentStyle()` (= `_headingStyle` bei leerem Stack) als Wurzel. Die beiden
Stellen teilen **nicht** dieselbe Wurzel-Annahme → reproduzierbarer Stil-Bug.

---

### A6 — Zwei Headings in Folge, zweites ohne abgeschlossenes erstes

```
# Eins **noch offen
## Zwei
```

Erwartet: Jede Zeile eigenständig korrekt; offener `**` aus Zeile 1 darf Zeile 2
nicht einfärben; Zeichenzahl exakt.

Vermutetes Ist-Verhalten: Spitzt A5 zu. Beim Treffen des zweiten `HeadingToken`
läuft `endHeading()` mit dem noch offenen `**` auf dem Stack. Genau der Pfad, in
dem die Wurzel-Verwechslung sichtbar wird. Prüfen: kein Style-Bleed über die
Zeilengrenze, keine Verschiebung der Marker-Slots.

---

### A7 — Sechs Hashes ohne Space (genau an der Grenze)

```
###### no-space
```

Erwartet: kein Heading (kein Space), kompletter Plain-Text bleibt erhalten.

Vermutetes Ist-Verhalten: `count` läuft auf 6 hoch, kein Space → `markerLength ==
count` → `pos++; continue;`. Gleicher fragiler Pfad wie A2, aber an der oberen
Level-Grenze. Verifiziert, dass die `continue`-Logik auch bei maximaler
Hash-Zahl keinen Slot verliert.

---

### A8 — Führende Whitespace vor Hash

```
␣␣␣# Eingerückt
```

(Echte Eingabe: `   # Eingerückt`)

Erwartet (falls „CommonMark-style" beansprucht): bis zu 3 führende Spaces sind
erlaubt → gültiges H1.

Vermutetes Ist-Verhalten: Zeichen vor `#` ist ein Space → `atLineStart == false`
→ kein Heading. Vertretbare Vereinfachung — aber dann darf weder Doku noch
PR-Beschreibung „CommonMark" behaupten. Dieser Test fixiert die getroffene
Entscheidung explizit (egal welche), damit sie nicht versehentlich driftet.

---

### A9 — Hash am String-Ende ohne folgende Zeichen

```
#
```

Erwartet: einzelnes `#`, kein Space, kein Heading → Plain-Text `#`.

Vermutetes Ist-Verhalten: `count == 1`, `markerLength`-Schleife terminiert sofort
(`pos + markerLength < length` falsch) → `markerLength == count` → `pos++;
continue;`. Am Stringende greift danach `addTextToken(textStart, pos)`. Prüfen,
dass das `#` exakt einmal im Output landet.

---

### A10 — Heading-Marker, dann nur Whitespace bis Zeilenende

```
###␣␣␣
```

(Echte Eingabe: `###   ` — drei Hashes, drei Spaces, kein Inhalt)

Erwartet: Definitionsentscheidung nötig — leeres H3 oder Plain-Text? CommonMark
erlaubt leere ATX-Headings. Festlegen und testen.

Vermutetes Ist-Verhalten: `markerLength > count` (Spaces gefunden) → `HeadingToken`
mit `length == 6` wird emittiert, danach kein Inhalt. Im Read-only wird der Marker
konsumiert → leere Zeile. Im Editor bleiben `###   ` als Slots. Verifizieren, dass
beide Modi die Leerzeichen-Slots korrekt behandeln (1:1 im Editor).

---

## B · Pflicht-Testfälle (müssen grün sein und bleiben)

### B1 — Einfaches H1 bis H6

```
# H1
## H2
### H3
#### H4
##### H5
###### H6
```

Read-only: jeweils Heading-Stil pro Level, Marker konsumiert.
Editor: Marker sichtbar/gedimmt, 1:1-Invariante pro Zeile.
Resolver liefert für jedes Level den erwarteten Stil (Default-Skala).

---

### B2 — Heading mit Inline-Formatierung (wohlgeformt)

```
# Titel mit **fett** und *kursiv*
```

Erwartet: Inline-Marker innerhalb der Heading-Zeile erben den Heading-Stil als
Wurzel (`currentStyle()` → `_headingStyle`). `**fett**` ist fett **und** im
Heading-Stil (Größe/Gewicht mergen, nicht ersetzen). Schließt vor `\n` → kein
`endHeading()`-Wurzelproblem. Das ist der Gegenpol zu A5: hier MUSS es korrekt
sein.

---

### B3 — Heading gefolgt von normalem Absatz

```
# Überschrift
Normaler Text danach.
```

Erwartet: Nach dem `\n` endet der Heading-Stil sauber; „Normaler Text danach."
in `baseStyle`. Read-only und Editor identisch im Style-Übergang.

---

### B4 — Mehrere Headings mit dazwischenliegendem Text

```
# Erste
Absatz eins.
## Zweite
Absatz zwei.
```

Erwartet: Jeder Heading-Stil endet exakt an seinem `\n`; kein Bleed in die
Absätze; Absätze in `baseStyle`. Stellt sicher, dass `beginHeading`/`endHeading`
sauber paaren.

---

### B5 — Heading nicht am Zeilenanfang

```
Text # mitten in der Zeile
```

Erwartet: kein Heading. `#` ist Plain-Text (Zeichen davor ist kein Newline).
Komplette Zeile in `baseStyle`.

---

### B6 — Escapetes Hash am Zeilenanfang

```
\# kein Heading
```

(Echte Eingabe: `\# kein Heading`)

Erwartet: `\#` → literales `#` (Escape greift, `kHash` ist in der Escape-Whitelist).
Kein Heading. Read-only: `#` sichtbar ohne Backslash. Editor: Backslash als
gedimmter `EscapeMarkerToken`-Slot, dann `#`. 1:1-Invariante.

---

### B7 — 1:1-Invariante: Heading mit Emoji-Inhalt (Editor)

```
# Titel 🚀 mit Emoji
```

Erwartet (Editor): Gesamtzahl der Character-Slots == `text.length` (UTF-16
Code-Units). Das Emoji belegt 2 Code-Units; der SpanBuilder muss das (über den
bestehenden Grapheme-/Surrogate-Pfad) korrekt abbilden, auch im Heading-Stil.
Kein Cursor-Misalignment.

---

### B8 — Heading-Inhalt mit Link

```
# Siehe [Doku](https://example.com)
```

Erwartet: Heading-Stil auf „Siehe ", Link korrekt verarbeitet, Link-Stil auf
Heading-Wurzel gemerged. Editor: alle Link-Marker-Slots (`[`, `](`, URL, `)`)
erhalten, 1:1.

---

### B9 — Reiner Plain-Text ohne jedes Hash (Regression)

```
Ganz normaler Text ohne Sonderzeichen.
```

Erwartet: Fast-Path (`!FormattingUtils.hasFormatting`) greift weiterhin; ein
einziger `TextSpan`. Sicherstellen, dass die Heading-Erweiterung den Fast-Path
nicht aushebelt (Performance-Regression).

---

### B10 — Konsistenz read-only ⇄ editor: gleiche Erkennung

```
# Eins
####### Sieben
#kein-space
```

Erwartet: Für **jede** Zeile erkennen Read-only-Parser und Editor-SpanBuilder
dieselben `HeadingToken`s (Erkennung ist `allowNewlineCrossing`-unabhängig — nur
die Darstellung unterscheidet sich: Marker konsumiert vs. sichtbar). Dieser Test
fixiert genau diese Garantie. Zeile 2 und 3 sind zugleich die Verdachtsfälle
A1/A2 — hier als Konsistenz-Anker.

---

### B11 — Heading-Stil-Resolution: Override via TextfOptions/Resolver

```
## Überschrift mit Custom-Stil
```

Erwartet: `resolveHeadingStyle(level, baseStyle)` liefert den Default-Stil für
Level 2; bei gesetztem Custom-Heading-Stil (Default vs. Custom-Pfad der PR) wird
dieser korrekt gemerged statt ersetzt. Beide Pfade testen.

---

## C · Hinweise zur Verwendung dieser Datei

- Die A-Fälle sind so gewählt, dass sie nach der Code-Analyse **wahrscheinlich**
  fehlschlagen. Test-first: zuerst als erwartetes Verhalten formulieren, rot
  sehen, dann fixen.
- Die B-Fälle sind Akzeptanzkriterien — sie müssen vor **und** nach jeder
  Heading-Änderung grün sein.
- Für Editor-Fälle immer zusätzlich die 1:1-Invariante prüfen
  (Σ Slots == `text.length` in UTF-16 Code-Units), nicht nur den visuellen Stil.
- A1, A2, A4, A7, A9 betreffen den Tokenizer-Pfad rund um `pos++; continue;` und
  die `count < 6`-Grenze. A5, A6 betreffen den `endHeading()`-Wurzelkonflikt im
  SpanBuilder. Das sind zwei getrennte Fehlerquellen — getrennt halten.
