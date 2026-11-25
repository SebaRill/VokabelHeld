import '../../core/constants.dart';
import 'vocabulary_entry.dart';

/// Eine Lektion, z. B. "Unit 1 Animals".
class Lesson {
  const Lesson({this.id, required this.name, required this.createdAt});

  final int? id;
  final String name;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Lesson.fromMap(Map<String, Object?> m) => Lesson(
        id: m['id'] as int,
        name: m['name'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );
}

/// Lernstatistik einer Lektion.
class LessonStats {
  const LessonStats({
    this.wordCount = 0,
    this.masteredCount = 0,
    this.totalLevel = 0,
    this.correct = 0,
    this.wrong = 0,
  });

  /// Berechnet die Statistik direkt aus einer Wortliste.
  factory LessonStats.fromEntries(List<VocabularyEntry> entries) {
    var mastered = 0, total = 0, correct = 0, wrong = 0;
    for (final e in entries) {
      if (e.level >= LearnLevel.max) mastered++;
      total += e.level;
      correct += e.correctCount;
      wrong += e.wrongCount;
    }
    return LessonStats(
      wordCount: entries.length,
      masteredCount: mastered,
      totalLevel: total,
      correct: correct,
      wrong: wrong,
    );
  }

  final int wordCount;

  /// Wörter auf Level 4 ("Beherrscht").
  final int masteredCount;

  /// Summe aller Level (für den Fortschritt).
  final int totalLevel;
  final int correct;
  final int wrong;

  /// Lernfortschritt 0..1 = Summe der Level / (Wörter * Maximal-Level).
  double get progress =>
      wordCount == 0 ? 0 : totalLevel / (wordCount * LearnLevel.max);

  /// Fehlerquote 0..1 = falsche Antworten / alle Antworten.
  double get errorRate {
    final total = correct + wrong;
    return total == 0 ? 0 : wrong / total;
  }
}

/// Lektion + Statistik (für die Übersichtsliste).
class LessonWithStats {
  const LessonWithStats(this.lesson, this.stats);
  final Lesson lesson;
  final LessonStats stats;
}
