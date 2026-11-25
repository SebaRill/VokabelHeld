/// Ein vom Parser erkannter Vokabel-Vorschlag (noch nicht gespeichert).
class ParsedEntry {
  const ParsedEntry({
    required this.english,
    required this.german,
    this.uncertain = false,
  });

  final String english;
  final String german;

  /// true, wenn der Eintrag vom Nutzer geprüft werden sollte
  /// (z. B. Ziffern im Wort wie "h0use" oder unsichere Trennung).
  final bool uncertain;

  @override
  String toString() => '$english | $german${uncertain ? ' (?)' : ''}';
}

/// Wandelt OCR-Text in Vokabelpaare um.
///
/// Mehrere Regelsätze werden der Reihe nach probiert:
///  1. Tab-getrennte Spalten (kommt aus [OcrLayout], wenn Englisch und Deutsch
///     in getrennten Spalten stehen; auch 2 Paare pro Zeile werden erkannt)
///  2. Führende Nummerierung entfernen ("1 dog Hund", "2. cat Katze")
///  3. Explizite Trenner: " - ", " – ", "=", ":", "|", ";"
///  4. Artikel-Regel: Zeilen, die mit to/a/an/the beginnen
///     ("to run rennen" -> "to run" | "rennen")
///  5. Großschreibung: Deutsche Nomen sind groß, englische Wörter klein
///     ("ice cream Eis" -> "ice cream" | "Eis")
///  6. Zwei Wörter -> links Englisch, rechts Deutsch
///  7. Notlösung (als "unsicher" markiert)
class VocabularyParser {
  VocabularyParser._();

  static final RegExp _pureNumber = RegExp(r'^\(?\d{1,3}[.)\]:]?$');
  static final RegExp _leadingNumber = RegExp(r'^\(?\d{1,3}[.)\]:]?\s+');
  static final RegExp _dashSeparator = RegExp(r'\s[-–—]\s');
  static final RegExp _symbolSeparator = RegExp(r'\s*[=|:;]\s*');
  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _validWord =
      RegExp(r"^[A-Za-zÄÖÜäöüß][A-Za-zÄÖÜäöüß\s'’\-\.,()/!?]*$");
  static const Set<String> _leadWords = {'to', 'a', 'an', 'the'};

  /// Parst den kompletten OCR-Text (eine Zeile = ein Eintrag).
  static List<ParsedEntry> parse(String text) {
    final result = <ParsedEntry>[];
    for (final line in text.split(RegExp(r'\r?\n'))) {
      result.addAll(_parseLine(line));
    }
    return result;
  }

  /// Prüft, ob ein Wort nach OCR-Fehler aussieht
  /// (leer, Ziffern oder Sonderzeichen im Wort, z. B. "h0use").
  static bool isSuspicious(String word) {
    final w = word.trim();
    if (w.isEmpty) return true;
    return !_validWord.hasMatch(w);
  }

  // ---------------------------------------------------------------------------

  static List<ParsedEntry> _parseLine(String rawLine) {
    var line = rawLine.trim();
    if (line.isEmpty) return const [];

    // Regel 1: Spalten (Tabs)
    if (line.contains('\t')) {
      final parts = line
          .split('\t')
          .map(_clean)
          .where((p) => p.isNotEmpty && !_pureNumber.hasMatch(p))
          .toList();
      return _fromColumns(parts);
    }

    // Regel 2: Nummerierung entfernen
    line = line.replaceFirst(_leadingNumber, '');

    // Regel 3: explizite Trenner
    final dash = _dashSeparator.firstMatch(line);
    if (dash != null) {
      return _single(line.substring(0, dash.start), line.substring(dash.end));
    }
    final symbol = _symbolSeparator.firstMatch(line);
    if (symbol != null) {
      return _single(
          line.substring(0, symbol.start), line.substring(symbol.end));
    }

    // Ab hier: nur Leerzeichen als Trenner.
    final tokens = line
        .split(_whitespace)
        .map(_clean)
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.length < 2) return const []; // Seitenzahl, Überschrift o. Ä.
    if (tokens.length == 2) return [_entry(tokens[0], tokens[1])];

    // Regel 4: to / a / an / the + Nomen/Verb gehören zum englischen Wort
    if (_leadWords.contains(tokens.first.toLowerCase())) {
      return [_entry('${tokens[0]} ${tokens[1]}', tokens.skip(2).join(' '))];
    }

    // Regel 5: erstes groß geschriebenes Wort = Beginn des deutschen Nomens
    if (_startsLower(tokens.first)) {
      for (var i = 1; i < tokens.length; i++) {
        if (_startsUpper(tokens[i])) {
          return [
            _entry(tokens.sublist(0, i).join(' '), tokens.sublist(i).join(' '))
          ];
        }
      }
    }

    // Regel 7: Notlösung - Hälfte/Hälfte bzw. 1. Wort/Rest, als unsicher.
    if (tokens.length.isEven) {
      final half = tokens.length ~/ 2;
      return [
        _entry(tokens.sublist(0, half).join(' '),
            tokens.sublist(half).join(' '),
            forceUncertain: true)
      ];
    }
    return [
      _entry(tokens.first, tokens.skip(1).join(' '), forceUncertain: true)
    ];
  }

  static List<ParsedEntry> _fromColumns(List<String> parts) {
    if (parts.length < 2) return const [];
    if (parts.length.isEven) {
      // 2 Teile = 1 Paar; 4 Teile = 2 Paare in einer Zeile usw.
      return [
        for (var i = 0; i < parts.length; i += 2) _entry(parts[i], parts[i + 1]),
      ];
    }
    return [
      _entry(parts.first, parts.skip(1).join(' '), forceUncertain: true)
    ];
  }

  static List<ParsedEntry> _single(String english, String german) {
    final en = _clean(english);
    final de = _clean(german);
    if (en.isEmpty && de.isEmpty) return const [];
    return [_entry(en, de)];
  }

  static ParsedEntry _entry(String en, String de, {bool forceUncertain = false}) {
    return ParsedEntry(
      english: en,
      german: de,
      uncertain: forceUncertain || isSuspicious(en) || isSuspicious(de),
    );
  }

  /// Entfernt Aufzählungszeichen vorn sowie Satzzeichen/Leerraum hinten.
  static String _clean(String s) {
    var r = s.replaceAll(_whitespace, ' ').trim();
    r = r.replaceFirst(RegExp(r'^[•·*▪●○■□>\-–—]+\s*'), '');
    r = r.replaceFirst(RegExp(r'[\s.,;:]+$'), '');
    return r;
  }

  static bool _startsLower(String t) {
    final c = t[0];
    return c.toLowerCase() == c && c.toUpperCase() != c;
  }

  static bool _startsUpper(String t) {
    final c = t[0];
    return c.toUpperCase() == c && c.toLowerCase() != c;
  }
}
