import 'package:flutter/foundation.dart';

import '../data/models/lesson.dart';
import '../data/repositories/lesson_repository.dart';

/// Zustand der Lektionsliste (Startseite).
class LessonProvider extends ChangeNotifier {
  LessonProvider(this._repo);
  final LessonRepository _repo;

  List<LessonWithStats> _lessons = [];
  bool _isLoading = true;

  List<LessonWithStats> get lessons => _lessons;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _lessons = await _repo.getAllWithStats();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addLesson(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _repo.create(trimmed);
    await load();
  }

  Future<void> rename(int id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _repo.rename(id, trimmed);
    await load();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await load();
  }
}
