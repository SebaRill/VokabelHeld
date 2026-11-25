/// Eine einzelne Vokabel (gehört zu genau einer Lektion).
class VocabularyEntry {
  const VocabularyEntry({
    this.id,
    required this.lessonId,
    required this.englishWord,
    required this.germanWord,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.level = 0,
    this.lastAsked,
  });

  final int? id;
  final int lessonId;
  final String englishWord;
  final String germanWord;
  final int correctCount;
  final int wrongCount;

  /// Lernstatus 0..4 (siehe LearnLevel).
  final int level;
  final DateTime? lastAsked;

  VocabularyEntry copyWith({
    String? englishWord,
    String? germanWord,
    int? correctCount,
    int? wrongCount,
    int? level,
    DateTime? lastAsked,
  }) {
    return VocabularyEntry(
      id: id,
      lessonId: lessonId,
      englishWord: englishWord ?? this.englishWord,
      germanWord: germanWord ?? this.germanWord,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      level: level ?? this.level,
      lastAsked: lastAsked ?? this.lastAsked,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'lesson_id': lessonId,
        'english_word': englishWord,
        'german_word': germanWord,
        'correct_count': correctCount,
        'wrong_count': wrongCount,
        'level': level,
        'last_asked': lastAsked?.millisecondsSinceEpoch,
      };

  factory VocabularyEntry.fromMap(Map<String, Object?> m) => VocabularyEntry(
        id: m['id'] as int,
        lessonId: m['lesson_id'] as int,
        englishWord: m['english_word'] as String,
        germanWord: m['german_word'] as String,
        correctCount: m['correct_count'] as int,
        wrongCount: m['wrong_count'] as int,
        level: m['level'] as int,
        lastAsked: m['last_asked'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(m['last_asked'] as int),
      );
}
