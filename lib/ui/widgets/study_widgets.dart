import 'package:material_ui/material_ui.dart';

import '../../providers/study_provider.dart';

/// Umschalter: Englisch -> Deutsch oder Deutsch -> Englisch.
class DirectionSelector extends StatelessWidget {
  const DirectionSelector({super.key, required this.direction, required this.onChanged});
  final StudyDirection direction;
  final ValueChanged<StudyDirection> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<StudyDirection>(
        showSelectedIcon: false,
        style: const ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(0, 56)),
          textStyle: WidgetStatePropertyAll(
              TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        segments: const [
          ButtonSegment(value: StudyDirection.enToDe, label: Text('English → Deutsch')),
          ButtonSegment(value: StudyDirection.deToEn, label: Text('Deutsch → English')),
        ],
        selected: {direction},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

/// Zeigt die Treffer dieser Lernrunde.
class SessionScoreBar extends StatelessWidget {
  const SessionScoreBar({super.key, required this.correct, required this.wrong});
  final int correct;
  final int wrong;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('✔ $correct', style: style.copyWith(color: Colors.green.shade700)),
        const SizedBox(width: 32),
        Text('✖ $wrong', style: style.copyWith(color: Colors.red.shade600)),
      ],
    );
  }
}

/// Hinweis, wenn keine (oder zu wenige) Wörter vorhanden sind.
class StudyMessage extends StatelessWidget {
  const StudyMessage({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('🤔\n$text',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 28)),
        ),
      );
}
