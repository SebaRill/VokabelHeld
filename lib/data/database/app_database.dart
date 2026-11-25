import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Öffnet die lokale SQLite-Datenbank und legt das Schema an.
/// Alle Daten bleiben auf dem Gerät (keine Cloud, keine Konten).
class AppDatabase {
  static const _dbName = 'vokabelheld.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, _dbName),
      version: _dbVersion,
      // Fremdschlüssel aktivieren, damit beim Löschen einer Lektion
      // automatisch alle Vokabeln mitgelöscht werden (ON DELETE CASCADE).
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE lessons (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE vocabulary (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lesson_id INTEGER NOT NULL,
            english_word TEXT NOT NULL,
            german_word TEXT NOT NULL,
            correct_count INTEGER NOT NULL DEFAULT 0,
            wrong_count INTEGER NOT NULL DEFAULT 0,
            level INTEGER NOT NULL DEFAULT 0,
            last_asked INTEGER,
            FOREIGN KEY (lesson_id) REFERENCES lessons (id) ON DELETE CASCADE
          )''');
        await db.execute(
            'CREATE INDEX idx_vocabulary_lesson ON vocabulary (lesson_id)');
      },
      // Für spätere Versionen: hier Migrationen ergänzen.
    );
  }
}
