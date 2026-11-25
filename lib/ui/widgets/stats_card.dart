import 'package:material_ui/material_ui.dart';

import '../../core/formatters.dart';
import '../../data/models/lesson.dart';

/// Statistik einer Lektion: Wörter, Beherrscht, Fortschritt, Fehlerquote.
class StatsCard extends StatelessWidget {
  const StatsCard({super.key, required this.stats});
  final LessonStats stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.tertiaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistik 📊',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatTile(emoji: '📚', label: 'Wörter', value: '${stats.wordCount}'),
                _StatTile(emoji: '🏆', label: 'Beherrscht', value: '${stats.masteredCount}'),
                _StatTile(emoji: '🚀', label: 'Lernfortschritt', value: percent(stats.progress)),
                _StatTile(emoji: '❌', label: 'Fehlerquote', value: percent(stats.errorRate)),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: stats.progress,
              minHeight: 14,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.emoji, required this.label, required this.value});
  final String emoji;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          Text(value,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
