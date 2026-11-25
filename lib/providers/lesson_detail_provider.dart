import 'package:flutter/foundation.dart';

import '../data/models/lesson.dart';
import '../data/models/vocabulary_entry.dart';
import '../data/repositories/vocabulary_repository.dart';

/// Zustand einer einzelnen Lektion: Wortliste + Statistik.
class LessonDetailProvider extends ChangeNotifier {
  LessonDetailProvider({
    required this.lessonId,
    required VocabularyRepository repository,
  }) : _repo = repository;

  final int lessonId;
  final VocabularyRepository _repo;

  List<VocabularyEntry> entries = [];
  bool isLoading = true;

  LessonStats get stats => LessonStats.fromEntries(entries);

  Future<void> load() async {
    entries = await _repo.getByLesson(lessonId);
    isLoading = false;
    notifyListeners();
  }

  Future<void> add(String english, String german) async {
    if (english.trim().isEmpty || german.trim().isEmpty) return;
    await _repo.insert(VocabularyEntry(
      lessonId: lessonId,
      englishWord: english.trim(),
      germanWord: german.trim(),
    ));
    await load();
  }

  Future<void> edit(VocabularyEntry entry, String english, String german) async {
    if (english.trim().isEmpty || german.trim().isEmpty) return;
    await _repo.update(
        entry.copyWith(englishWord: english.trim(), germanWord: german.trim()));
    await load();
  }

  Future<void> remove(VocabularyEntry entry) async {
    await _repo.delete(entry.id!);
    await load();
  }
}
