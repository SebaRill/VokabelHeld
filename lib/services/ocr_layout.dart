import 'dart:ui' show Rect;

/// Eine vom OCR erkannte Textzeile mit Position im Bild.
class OcrLine {
  const OcrLine(this.text, this.box);
  final String text;
  final Rect box;
}

/// Ordnet OCR-Zeilen zu Tabellenzeilen.
///
/// Steht "dog" links und "Hund" rechts in einer Spalte, erkennt ML Kit sie
/// oft als getrennte Zeilen. Hier werden Zeilen mit ähnlicher Höhe (y)
/// zusammengefasst und mit Tab getrennt - der Parser macht daraus ein Paar.
class OcrLayout {
  OcrLayout._();

  static String linesToRows(List<OcrLine> lines) {
    if (lines.isEmpty) return '';

    final sorted = [...lines]
      ..sort((a, b) => a.box.center.dy.compareTo(b.box.center.dy));

    final rows = <List<OcrLine>>[];
    for (final line in sorted) {
      if (rows.isNotEmpty) {
        final row = rows.last;
        final rowCenter =
            row.map((l) => l.box.center.dy).reduce((a, b) => a + b) / row.length;
        final tolerance = line.box.height * 0.5;
        if ((line.box.center.dy - rowCenter).abs() <= tolerance) {
          row.add(line);
          continue;
        }
      }
      rows.add([line]);
    }

    return rows.map((row) {
      row.sort((a, b) => a.box.left.compareTo(b.box.left));
      return row.map((l) => l.text.trim()).join('\t');
    }).join('\n');
  }
}
