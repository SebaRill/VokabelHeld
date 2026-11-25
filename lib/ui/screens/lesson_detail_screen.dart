import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../data/models/lesson.dart';
import '../../data/models/vocabulary_entry.dart';
import '../../data/repositories/vocabulary_repository.dart';
import '../../providers/lesson_detail_provider.dart';
import '../widgets/content_width.dart';
import '../widgets/dialogs.dart';
import '../widgets/level_chip.dart';
import '../widgets/stats_card.dart';
import 'flashcard_screen.dart';
import 'import_screen.dart';
import 'quiz_screen.dart';

/// Eine Lektion: Statistik, Lernen, Quiz, Foto-Import und Wortliste.
class LessonDetailScreen extends StatelessWidget {
  const LessonDetailScreen({super.key, required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => LessonDetailProvider(
        lessonId: lesson.id!,
        repository: c.read<VocabularyRepository>(),
      )..load(),
      child: _DetailView(lesson: lesson),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.lesson});
  final Lesson lesson;

  /// Öffnet einen Bildschirm und lädt danach die Daten neu.
  Future<void> _open(BuildContext context, Widget screen) async {
    final provider = context.read<LessonDetailProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await Navigator.of(context)
        .push<Object?>(MaterialPageRoute<Object?>(builder: (_) => screen));
    await provider.load();
    if (result is int && result > 0) {
      messenger.showSnackBar(
          SnackBar(content: Text('${wordsLabel(result)} gespeichert 🎉')));
    }
  }

  Future<void> _addWord(BuildContext context) async {
    final provider = context.read<LessonDetailProvider>();
    final word = await promptWord(context);
    if (word != null) await provider.add(word.$1, word.$2);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<LessonDetailProvider>();
    final id = lesson.id!;

    return Scaffold(
      appBar: AppBar(title: Text(lesson.name)),
      body: ContentWidth(
        child: p.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  StatsCard(stats: p.stats),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: p.entries.isEmpty
                            ? null
                            : () => _open(context, FlashcardScreen(lessonId: id)),
                        icon: const Icon(Icons.style, size: 30),
                        label: const Text('Lernen'),
                      ),
                      FilledButton.icon(
                        onPressed: p.entries.length < 2
                            ? null
                            : () => _open(context, QuizScreen(lessonId: id)),
                        icon: const Icon(Icons.quiz, size: 30),
                        label: const Text('Quiz'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _open(
                            context, ImportScreen(lessonId: id, lessonName: lesson.name)),
                        icon: const Icon(Icons.photo_camera, size: 30),
                        label: const Text('Foto scannen'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _addWord(context),
                        icon: const Icon(Icons.add, size: 30),
                        label: const Text('Wort hinzufügen'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Wörter (${p.entries.length})',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (p.entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Noch keine Wörter. Mach ein Foto von deiner Vokabelseite '
                        'oder tippe sie von Hand ein!',
                        style: TextStyle(fontSize: 22),
                      ),
                    ),
                  for (final e in p.entries) _WordTile(entry: e),
                ],
              ),
      ),
    );
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({required this.entry});
  final VocabularyEntry entry;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<LessonDetailProvider>();
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text('${entry.englishWord}  →  ${entry.germanWord}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            ),
            LevelChip(level: entry.level),
            IconButton(
              iconSize: 30,
              tooltip: 'Bearbeiten',
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final word = await promptWord(
                  context,
                  title: 'Wort bearbeiten',
                  english: entry.englishWord,
                  german: entry.germanWord,
                );
                if (word != null) await provider.edit(entry, word.$1, word.$2);
              },
            ),
            IconButton(
              iconSize: 30,
              tooltip: 'Löschen',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await confirmDialog(
                  context,
                  title: 'Wort löschen?',
                  message: '„${entry.englishWord} → ${entry.germanWord}“ wirklich löschen?',
                );
                if (ok) await provider.remove(entry);
              },
            ),
          ],
        ),
      ),
    );
  }
}
