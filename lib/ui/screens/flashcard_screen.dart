import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/vocabulary_repository.dart';
import '../../providers/study_provider.dart';
import '../widgets/content_width.dart';
import '../widgets/level_chip.dart';
import '../widgets/study_widgets.dart';

/// Lernmodus mit Karteikarten: Antwort aufdecken, dann Richtig/Falsch.
class FlashcardScreen extends StatelessWidget {
  const FlashcardScreen({super.key, required this.lessonId});
  final int lessonId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => StudyProvider(
        lessonId: lessonId,
        repository: c.read<VocabularyRepository>(),
      )..init(),
      child: const _FlashcardView(),
    );
  }
}

class _FlashcardView extends StatelessWidget {
  const _FlashcardView();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<StudyProvider>();

    Widget body;
    if (s.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (s.current == null) {
      body = const StudyMessage(text: 'Diese Lektion hat noch keine Wörter.');
    } else {
      body = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DirectionSelector(direction: s.direction, onChanged: s.setDirection),
            const SizedBox(height: 12),
            SessionScoreBar(correct: s.sessionCorrect, wrong: s.sessionWrong),
            const SizedBox(height: 12),
            Expanded(child: _CardFace(s: s)),
            const SizedBox(height: 16),
            if (s.answerRevealed)
              Row(
                children: [
                  Expanded(
                    child: _AnswerButton(
                      label: '✖ Falsch',
                      color: Colors.red.shade400,
                      onTap: () => s.answer(false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _AnswerButton(
                      label: '✔ Richtig',
                      color: Colors.green.shade600,
                      onTap: () => s.answer(true),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(84),
                      textStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  onPressed: s.reveal,
                  child: const Text('Antwort zeigen'),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lernen')),
      body: ContentWidth(child: body),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.s});
  final StudyProvider s;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: SizedBox.expand(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.promptLanguage,
                    style: TextStyle(fontSize: 20, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Text(s.questionText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 54, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                LevelChip(level: s.current!.level),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(thickness: 2),
                ),
                if (s.answerRevealed)
                  Text(s.answerText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700))
                else
                  const Text('❓', style: TextStyle(fontSize: 46)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(84),
        textStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }
}
