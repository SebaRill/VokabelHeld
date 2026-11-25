import 'dart:math';

import '../core/constants.dart';
import '../data/models/vocabulary_entry.dart';

/// Gewichtete Zufallsauswahl: Wörter mit niedrigem Level kommen häufiger dran.
class WeightedSelector {
  WeightedSelector._();

  /// Gewicht pro Level 0..4 (Neu, Unsicher, Bekannt, Gut, Beherrscht).
  /// Ein neues Wort wird also 10x so oft gewählt wie ein beherrschtes.
  static const List<double> weights = [10, 7, 4, 2, 1];

  static double weightOf(VocabularyEntry e) => weights[LearnLevel.clamp(e.level)];

  /// Wählt ein Wort. [excludeId] verhindert, dass dasselbe Wort direkt
  /// nochmal kommt (außer es gibt nur ein Wort).
  static VocabularyEntry? pick(
    List<VocabularyEntry> entries,
    Random random, {
    int? excludeId,
  }) {
    if (entries.isEmpty) return null;
    var candidates = entries.where((e) => e.id != excludeId).toList();
    if (candidates.isEmpty) candidates = entries;

    final total = candidates.fold<double>(0, (sum, e) => sum + weightOf(e));
    var r = random.nextDouble() * total;
    for (final e in candidates) {
      r -= weightOf(e);
      if (r <= 0) return e;
    }
    return candidates.last;
  }
}
