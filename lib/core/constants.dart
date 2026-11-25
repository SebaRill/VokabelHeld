/// Zentrale Konstanten des Lernalgorithmus.
///
/// 0 = Neu, 1 = Unsicher, 2 = Bekannt, 3 = Gut, 4 = Beherrscht
class LearnLevel {
  LearnLevel._();

  static const int min = 0;
  static const int max = 4;

  static const List<String> labels = [
    'Neu',
    'Unsicher',
    'Bekannt',
    'Gut',
    'Beherrscht',
  ];

  /// Begrenzt einen Wert auf den gültigen Bereich 0..4.
  static int clamp(int value) => value < min ? min : (value > max ? max : value);

  static String labelOf(int level) => labels[clamp(level)];
}
