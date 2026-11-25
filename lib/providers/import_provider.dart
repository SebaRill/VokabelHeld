import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../data/repositories/vocabulary_repository.dart';
import '../domain/vocabulary_parser.dart';
import '../services/ocr_service.dart';

enum ImportStage { pick, processing, review }

/// Bearbeitbarer Entwurf einer Vokabel (vor dem Speichern).
class DraftEntry {
  DraftEntry({
    required this.uid,
    required this.english,
    required this.german,
    required this.uncertain,
  });

  final int uid; // nur für Widget-Keys
  String english;
  String german;
  bool uncertain;

  bool get isComplete => english.trim().isNotEmpty && german.trim().isNotEmpty;
}

/// Ablauf: Foto wählen -> OCR -> Parser -> Korrekturansicht -> Speichern.
class ImportProvider extends ChangeNotifier {
  ImportProvider({
    required OcrService ocr,
    required VocabularyRepository repository,
    ImagePicker? picker,
  })  : _ocr = ocr,
        _repo = repository,
        _picker = picker ?? ImagePicker();

  final OcrService _ocr;
  final VocabularyRepository _repo;
  final ImagePicker _picker;

  ImportStage stage = ImportStage.pick;
  String? imagePath;
  String? error;
  bool isSaving = false;
  List<DraftEntry> drafts = [];
  int _nextUid = 0;

  int get validCount => drafts.where((d) => d.isComplete).length;
  int get uncertainCount => drafts.where((d) => d.uncertain).length;

  Future<void> pickAndRecognize(ImageSource source) async {
    error = null;
    try {
      final file = await _picker.pickImage(
          source: source, imageQuality: 90, maxWidth: 2600);
      if (file == null) {
        notifyListeners();
        return; // Nutzer hat abgebrochen
      }
      imagePath = file.path;
      stage = ImportStage.processing;
      notifyListeners();

      final text = await _ocr.recognizeText(file.path);
      final parsed = VocabularyParser.parse(text);

      drafts = [
        for (final p in parsed)
          DraftEntry(
            uid: _nextUid++,
            english: p.english,
            german: p.german,
            uncertain: p.uncertain,
          ),
      ];
      if (drafts.isEmpty) {
        error = 'Ich konnte keine Vokabeln finden. '
            'Versuche es mit mehr Licht und einem geraden Foto.';
        stage = ImportStage.pick;
      } else {
        stage = ImportStage.review;
      }
    } catch (e) {
      error = 'Das Bild konnte nicht gelesen werden: $e';
      stage = ImportStage.pick;
    }
    notifyListeners();
  }

  void updateEnglish(int uid, String value) {
    final d = drafts.firstWhere((d) => d.uid == uid);
    d.english = value;
    _recheck(d);
    notifyListeners();
  }

  void updateGerman(int uid, String value) {
    final d = drafts.firstWhere((d) => d.uid == uid);
    d.german = value;
    _recheck(d);
    notifyListeners();
  }

  void remove(int uid) {
    drafts.removeWhere((d) => d.uid == uid);
    notifyListeners();
  }

  void addEmpty() {
    drafts.add(DraftEntry(uid: _nextUid++, english: '', german: '', uncertain: true));
    notifyListeners();
  }

  void reset() {
    drafts = [];
    imagePath = null;
    error = null;
    stage = ImportStage.pick;
    notifyListeners();
  }

  /// Speichert alle vollständigen Einträge. Gibt die Anzahl zurück.
  Future<int> save(int lessonId) async {
    final words = <(String, String)>[
      for (final d in drafts)
        if (d.isComplete) (d.english.trim(), d.german.trim()),
    ];
    if (words.isEmpty) return 0;
    isSaving = true;
    notifyListeners();
    await _repo.insertAll(lessonId, words);
    isSaving = false;
    notifyListeners();
    return words.length;
  }

  void _recheck(DraftEntry d) {
    d.uncertain = VocabularyParser.isSuspicious(d.english) ||
        VocabularyParser.isSuspicious(d.german);
  }
}
