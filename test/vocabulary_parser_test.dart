import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vokabelheld/data/models/vocabulary_entry.dart';
import 'package:vokabelheld/domain/ocr_corrector.dart';
import 'package:vokabelheld/domain/vocabulary_parser.dart';
import 'package:vokabelheld/domain/weighted_selector.dart';

void main() {
  group('VocabularyParser', () {
    test('Leerzeichen-getrennt', () {
      final r = VocabularyParser.parse('dog Hund\ncat Katze\nhorse Pferd');
      expect(r.map((e) => '${e.english}|${e.german}'),
          ['dog|Hund', 'cat|Katze', 'horse|Pferd']);
      expect(r.any((e) => e.uncertain), isFalse);
    });

    test('Bindestrich-getrennt', () {
      final r = VocabularyParser.parse('dog - Hund\ncat – Katze');
      expect(r.map((e) => '${e.english}|${e.german}'), ['dog|Hund', 'cat|Katze']);
    });

    test('Nummerierung wird entfernt', () {
      final r = VocabularyParser.parse('1 dog Hund\n2. cat Katze');
      expect(r.map((e) => '${e.english}|${e.german}'), ['dog|Hund', 'cat|Katze']);
    });

    test('Mehrwort-Einträge', () {
      final r = VocabularyParser.parse('ice cream Eis\nto run rennen');
      expect(r[0].english, 'ice cream');
      expect(r[0].german, 'Eis');
      expect(r[1].english, 'to run');
      expect(r[1].german, 'rennen');
    });

    test('Spalten (Tab) inkl. Nummer und zwei Paare pro Zeile', () {
      final r = VocabularyParser.parse('1\tdog\tHund\ndog\tHund\tcat\tKatze');
      expect(r.length, 3);
      expect(r[0].english, 'dog');
      expect(r[2].german, 'Katze');
    });

    test('OCR-Fehler wird als unsicher markiert', () {
      final r = VocabularyParser.parse('h0use Haus');
      expect(r.single.uncertain, isTrue);
      expect(OcrCorrector.suggest(r.single.english), 'house');
    });

    test('Seitenzahlen werden ignoriert', () {
      expect(VocabularyParser.parse('42\n\n'), isEmpty);
    });
  });

  group('WeightedSelector', () {
    test('niedrige Level werden häufiger gewählt', () {
      const neu = VocabularyEntry(id: 1, lessonId: 1, englishWord: 'a', germanWord: 'b', level: 0);
      const gut = VocabularyEntry(id: 2, lessonId: 1, englishWord: 'c', germanWord: 'd', level: 4);
      final random = Random(42);
      var neuCount = 0;
      for (var i = 0; i < 5000; i++) {
        if (WeightedSelector.pick([neu, gut], random)!.id == 1) neuCount++;
      }
      expect(neuCount / 5000, greaterThan(0.85)); // erwartet ca. 91 %
    });

    test('excludeId verhindert Wiederholung', () {
      const a = VocabularyEntry(id: 1, lessonId: 1, englishWord: 'a', germanWord: 'b');
      const b = VocabularyEntry(id: 2, lessonId: 1, englishWord: 'c', germanWord: 'd');
      for (var i = 0; i < 50; i++) {
        expect(WeightedSelector.pick([a, b], Random(i), excludeId: 1)!.id, 2);
      }
    });
  });
}
