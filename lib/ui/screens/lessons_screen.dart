import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../data/models/lesson.dart';
import '../../providers/lesson_provider.dart';
import '../widgets/content_width.dart';
import '../widgets/dialogs.dart';
import 'lesson_detail_screen.dart';

/// Startseite: Liste aller Lektionen.
class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  Future<void> _create(BuildContext context) async {
    final provider = context.read<LessonProvider>();
    final name = await promptText(
      context,
      title: 'Neue Lektion',
      label: 'Name (z. B. Unit 1 Animals)',
      confirm: 'Anlegen',
    );
    if (name != null) await provider.addLesson(name);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LessonProvider>();

    Widget body;
    if (provider.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (provider.lessons.isEmpty) {
      body = const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            '🦸\nWillkommen, Vokabelheld!\nLege deine erste Lektion an.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30),
          ),
        ),
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: provider.lessons.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _LessonCard(item: provider.lessons[i]),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('🦸 Vokabelheld')),
      body: ContentWidth(child: body),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.add, size: 32),
        label: const Text('Neue Lektion'),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.item});
  final LessonWithStats item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stats = item.stats;
    final shape = BorderRadius.circular(28);

    return Card(
      elevation: 0,
      color: scheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: shape),
      child: InkWell(
        borderRadius: shape,
        onTap: () async {
          final provider = context.read<LessonProvider>();
          await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => LessonDetailScreen(lesson: item.lesson),
          ));
          await provider.load(); // Statistik nach Rückkehr aktualisieren
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white,
                child: Text('📚', style: TextStyle(fontSize: 30)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.lesson.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${wordsLabel(stats.wordCount)} · ${percent(stats.progress)} gelernt',
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: stats.progress,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                iconSize: 34,
                onSelected: (value) => _onMenu(context, value),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('Umbenennen')),
                  PopupMenuItem(value: 'delete', child: Text('Löschen')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onMenu(BuildContext context, String value) async {
    final provider = context.read<LessonProvider>();
    final id = item.lesson.id!;
    if (value == 'rename') {
      final name = await promptText(
        context,
        title: 'Lektion umbenennen',
        initial: item.lesson.name,
        label: 'Neuer Name',
      );
      if (name != null) await provider.rename(id, name);
    } else {
      final ok = await confirmDialog(
        context,
        title: 'Lektion löschen?',
        message:
            '„${item.lesson.name}“ und alle ${wordsLabel(item.stats.wordCount)} darin werden gelöscht.',
      );
      if (ok) await provider.delete(id);
    }
  }
}
