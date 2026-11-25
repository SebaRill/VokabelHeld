import '../database/app_database.dart';
import '../models/lesson.dart';

/// Datenzugriff für Lektionen.
class LessonRepository {
  LessonRepository(this._db);
  final AppDatabase _db;

  /// Alle Lektionen inkl. Statistik (eine SQL-Abfrage).
  Future<List<LessonWithStats>> getAllWithStats() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT l.id, l.name, l.created_at,
             COUNT(v.id) AS word_count,
             COALESCE(SUM(CASE WHEN v.level = 4 THEN 1 ELSE 0 END), 0) AS mastered,
             COALESCE(SUM(v.level), 0) AS total_level,
             COALESCE(SUM(v.correct_count), 0) AS correct,
             COALESCE(SUM(v.wrong_count), 0) AS wrong
      FROM lessons l
      LEFT JOIN vocabulary v ON v.lesson_id = l.id
      GROUP BY l.id
      ORDER BY l.created_at ASC, l.id ASC
    ''');
    return rows.map((m) {
      int n(String key) => (m[key] as num).toInt();
      return LessonWithStats(
        Lesson.fromMap(m),
        LessonStats(
          wordCount: n('word_count'),
          masteredCount: n('mastered'),
          totalLevel: n('total_level'),
          correct: n('correct'),
          wrong: n('wrong'),
        ),
      );
    }).toList();
  }

  Future<int> create(String name) async {
    final db = await _db.database;
    return db.insert(
        'lessons', Lesson(name: name, createdAt: DateTime.now()).toMap());
  }

  Future<void> rename(int id, String name) async {
    final db = await _db.database;
    await db.update('lessons', {'name': name}, where: 'id = ?', whereArgs: [id]);
  }

  /// Löscht die Lektion; zugehörige Vokabeln folgen per CASCADE.
  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('lessons', where: 'id = ?', whereArgs: [id]);
  }
}
