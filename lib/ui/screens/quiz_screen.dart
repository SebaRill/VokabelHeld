import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/vocabulary_repository.dart';
import '../../providers/study_provider.dart';
import '../widgets/content_width.dart';
import '../widgets/study_widgets.dart';

/// Multiple Choice: eine Frage, vier gemischte Antworten.
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key, required this.lessonId});
  final int lessonId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => StudyProvider(
        lessonId: lessonId,
        repository: c.read<VocabularyRepository>(),
      )..init(),
      child: const _QuizView(),
    );
  }
}

class _QuizView extends StatelessWidget {
  const _QuizView();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<StudyProvider>();

    Widget body;
    if (s.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (s.current == null || !s.canQuiz) {
      body = const StudyMessage(text: 'Für das Quiz brauchst du mindestens 2 Wörter.');
    } else {
      body = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DirectionSelector(direction: s.direction, onChanged: s.setDirection),
            const SizedBox(height: 12),
            SessionScoreBar(correct: s.sessionCorrect, wrong: s.sessionWrong),
            const SizedBox(height: 16),
            Text(s.quizQuestion,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  for (final option in s.options)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OptionButton(option: option, s: s),
                    ),
                ],
              ),
            ),
            if (s.hasAnswered) ...[
              Text(
                s.lastWasCorrect
                    ? 'Super! 🎉'
                    : 'Leider falsch. Richtig ist: ${s.answerText}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: s.lastWasCorrect ? Colors.green.shade700 : Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(76)),
                  onPressed: s.next,
                  child: const Text('Weiter ➜'),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: ContentWidth(child: body),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({required this.option, required this.s});
  final String option;
  final StudyProvider s;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color background = scheme.primaryContainer;
    Color foreground = scheme.onPrimaryContainer;

    if (s.hasAnswered) {
      if (option == s.answerText) {
        background = Colors.green.shade500;
        foreground = Colors.white;
      } else if (option == s.selectedOption) {
        background = Colors.red.shade400;
        foreground = Colors.white;
      }
    }

    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        minimumSize: const Size.fromHeight(76),
        textStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      // Nach der Antwort ignoriert der Provider weitere Taps.
      onPressed: () => s.selectOption(option),
      child: Text(option, textAlign: TextAlign.center),
    );
  }
}
