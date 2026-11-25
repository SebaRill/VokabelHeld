import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/database/app_database.dart';
import 'data/repositories/lesson_repository.dart';
import 'data/repositories/vocabulary_repository.dart';
import 'providers/lesson_provider.dart';
import 'services/ocr_service.dart';

/// Einstiegspunkt: Datenbank öffnen, Abhängigkeiten bereitstellen, App starten.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);

  final database = AppDatabase();
  await database.database; // früh öffnen, damit Fehler sofort auffallen

  runApp(
    MultiProvider(
      providers: [
        // Datenhaltung
        Provider<AppDatabase>.value(value: database),
        Provider<LessonRepository>(create: (c) => LessonRepository(c.read<AppDatabase>())),
        Provider<VocabularyRepository>(
            create: (c) => VocabularyRepository(c.read<AppDatabase>())),
        // Services
        Provider<OcrService>(
          create: (_) => OcrService(),
          dispose: (_, service) => service.dispose(),
        ),
        // Zustand der Startseite
        ChangeNotifierProvider<LessonProvider>(
          create: (c) => LessonProvider(c.read<LessonRepository>())..load(),
        ),
      ],
      child: const VokabelheldApp(),
    ),
  );
}
