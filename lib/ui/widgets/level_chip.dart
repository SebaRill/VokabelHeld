import 'package:material_ui/material_ui.dart';

import '../../core/constants.dart';

const List<Color> _levelColors = [
  Color(0xFF78909C), // 0 Neu
  Color(0xFFEF5350), // 1 Unsicher
  Color(0xFFFFA000), // 2 Bekannt
  Color(0xFF7CB342), // 3 Gut
  Color(0xFF2E7D32), // 4 Beherrscht
];

/// Kleines farbiges Etikett für den Lernstatus eines Wortes.
class LevelChip extends StatelessWidget {
  const LevelChip({super.key, required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    final color = _levelColors[LearnLevel.clamp(level)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        LearnLevel.labelOf(level),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
