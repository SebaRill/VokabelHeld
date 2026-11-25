import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_ui/material_ui.dart';

import 'core/theme.dart';
import 'ui/screens/lessons_screen.dart';

/// Wurzel-Widget der App (Material 3, deutsche Oberfläche).
class VokabelheldApp extends StatelessWidget {
  const VokabelheldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vokabelheld',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const LessonsScreen(),
    );
  }
}
