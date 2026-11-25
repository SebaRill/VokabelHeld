/// Einfache Korrekturvorschläge für typische OCR-Verwechslungen
/// (Ziffer statt Buchstabe), z. B. "h0use" -> "house".
class OcrCorrector {
  OcrCorrector._();

  static const Map<String, String> _lookAlikes = {
    '0': 'o',
    '1': 'l',
    '5': 's',
    '3': 'e',
    '8': 'b',
    '|': 'l',
  };

  static final RegExp _hasLetter = RegExp(r'[A-Za-zÄÖÜäöüß]');

  /// Liefert einen Vorschlag oder null, wenn nichts zu korrigieren ist.
  /// Reine Zahlen (ohne Buchstaben) bleiben unverändert.
  static String? suggest(String text) {
    var changed = false;
    final fixed = text.split(' ').map((token) {
      if (!_hasLetter.hasMatch(token)) return token;
      final buffer = StringBuffer();
      for (final ch in token.split('')) {
        final replacement = _lookAlikes[ch];
        if (replacement != null) {
          buffer.write(replacement);
          changed = true;
        } else {
          buffer.write(ch);
        }
      }
      return buffer.toString();
    }).join(' ');
    return changed ? fixed : null;
  }
}
