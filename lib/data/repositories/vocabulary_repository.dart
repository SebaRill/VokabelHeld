import '../database/app_database.dart';
import '../models/vocabulary_entry.dart';

/// Datenzugriff für Vokabeln.
class VocabularyRepository {
  VocabularyRepository(this._db);
  final AppDatabase _db;

  static const _table = 'vocabulary';

  Future<List<VocabularyEntry>> getByLesson(int lessonId) async {
    final db = await _db.database;
    final rows = await db.query(_table,
        where: 'lesson_id = ?', whereArgs: [lessonId], orderBy: 'id ASC');
    return rows.map(VocabularyEntry.fromMap).toList();
  }

  /// Alle Vokabeln (für Multiple-Choice-Ablenker aus anderen Lektionen).
  Future<List<VocabularyEntry>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(_table, orderBy: 'id ASC');
    return rows.map(VocabularyEntry.fromMap).toList();
  }

  Future<int> insert(VocabularyEntry entry) async {
    final db = await _db.database;
    return db.insert(_table, entry.toMap());
  }

  /// Fügt viele Wörter in einer Transaktion ein (z. B. nach der OCR).
  Future<void> insertAll(int lessonId, List<(String, String)> words) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final (english, german) in words) {
      batch.insert(
        _table,
        VocabularyEntry(
                lessonId: lessonId, englishWord: english, germanWord: german)
            .toMap(),
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> update(VocabularyEntry entry) async {
    final db = await _db.database;
    await db.update(_table, entry.toMap(),
        where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
