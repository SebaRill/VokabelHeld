/// Kleine Hilfsfunktionen für die Anzeige.
String wordsLabel(int n) => n == 1 ? '1 Wort' : '$n Wörter';

String percent(double fraction) => '${(fraction * 100).round()} %';
