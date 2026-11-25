import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../data/models/vocabulary_entry.dart';
import '../data/repositories/vocabulary_repository.dart';
import '../domain/weighted_selector.dart';

enum StudyDirection { enToDe, deToEn }

/// Gemeinsamer Zustand für Lernmodus (Karteikarten) und Multiple Choice.
class StudyProvider extends ChangeNotifier {
  StudyProvider({
    required this.lessonId,
    required VocabularyRepository repository,
    Random? random,
  })  : _repo = repository,
        _random = random ?? Random();

  final int lessonId;
  final VocabularyRepository _repo;
  final Random _random;

  List<VocabularyEntry> _entries = []; // Wörter dieser Lektion
  List<VocabularyEntry> _others = []; // Wörter anderer Lektionen (Ablenker)
  bool _busy = false;

  bool isLoading = true;
  VocabularyEntry? current;
  StudyDirection direction = StudyDirection.enToDe;

  // Karteikarten
  bool answerRevealed = false;

  // Multiple Choice
  List<String> options = [];
  String? selectedOption;

  // Ergebnis dieser Sitzung
  int sessionCorrect = 0;
  int sessionWrong = 0;

  Future<void> init() async {
    final all = await _repo.getAll();
    _entries = all.where((e) => e.lessonId == lessonId).toList();
    _others = all.where((e) => e.lessonId != lessonId).toList();
    isLoading = false;
    _prepareNext();
    notifyListeners();
  }

  // --- Anzeige-Texte ---------------------------------------------------------

  bool get _enToDe => direction == StudyDirection.enToDe;

  String get questionText => current == null
      ? ''
      : (_enToDe ? current!.englishWord : current!.germanWord);

  String get answerText => current == null ? '' : _answerOf(current!);

  String get promptLanguage => _enToDe ? 'Englisch' : 'Deutsch';

  String get quizQuestion => _enToDe
      ? 'Was bedeutet „$questionText“?'
      : 'Wie heißt „$questionText“ auf Englisch?';

  bool get canQuiz => options.length >= 2;
  bool get hasAnswered => selectedOption != null;
  bool get lastWasCorrect => selectedOption == answerText;

  String _answerOf(VocabularyEntry e) => _enToDe ? e.germanWord : e.englishWord;

  // --- Aktionen --------------------------------------------------------------

  void setDirection(StudyDirection value) {
    if (value == direction) return;
    direction = value;
    answerRevealed = false;
    selectedOption = null;
    if (current != null) options = _buildOptions(current!);
    notifyListeners();
  }

  void reveal() {
    answerRevealed = true;
    notifyListeners();
  }

  /// Karteikarten-Modus: Nutzer meldet "Richtig" oder "Falsch".
  Future<void> answer(bool correct) async {
    if (current == null || _busy) return;
    _busy = true;
    await _record(correct);
    _busy = false;
    _prepareNext();
    notifyListeners();
  }

  /// Multiple-Choice-Modus: Nutzer tippt eine Antwort an.
  Future<void> selectOption(String option) async {
    if (current == null || hasAnswered || _busy) return;
    _busy = true;
    selectedOption = option;
    notifyListeners();
    await _record(option == answerText);
    _busy = false;
    notifyListeners();
  }

  /// Multiple Choice: nächste Frage nach der Rückmeldung.
  void next() {
    _prepareNext();
    notifyListeners();
  }

  // --- Intern ----------------------------------------------------------------

  /// Lernalgorithmus: richtig = Level +1, falsch = Level -1 (Grenzen 0..4).
  Future<void> _record(bool correct) async {
    final e = current!;
    final updated = e.copyWith(
      correctCount: e.correctCount + (correct ? 1 : 0),
      wrongCount: e.wrongCount + (correct ? 0 : 1),
      level: LearnLevel.clamp(e.level + (correct ? 1 : -1)),
      lastAsked: DateTime.now(),
    );
    await _repo.update(updated);
    final i = _entries.indexWhere((x) => x.id == e.id);
    if (i >= 0) _entries[i] = updated;
    current = updated;
    if (correct) {
      sessionCorrect++;
    } else {
      sessionWrong++;
    }
  }

  void _prepareNext() {
    answerRevealed = false;
    selectedOption = null;
    current = WeightedSelector.pick(_entries, _random, excludeId: current?.id);
    options = current == null ? [] : _buildOptions(current!);
  }

  /// Richtige Antwort + bis zu 3 falsche Antworten, gemischt.
  /// Ablenker kommen zuerst aus der Lektion, dann aus anderen Lektionen.
  List<String> _buildOptions(VocabularyEntry entry) {
    final correct = _answerOf(entry);
    final seen = <String>{correct.toLowerCase()};
    final distractors = <String>[];

    void collect(List<VocabularyEntry> source) {
      final shuffled = [...source]..shuffle(_random);
      for (final e in shuffled) {
        if (distractors.length >= 3) return;
        final text = _answerOf(e);
        if (seen.add(text.toLowerCase())) distractors.add(text);
      }
    }

    collect(_entries);
    if (distractors.length < 3) collect(_others);

    return [correct, ...distractors]..shuffle(_random);
  }
}
