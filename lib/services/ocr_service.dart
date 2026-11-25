import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ocr_layout.dart';

/// Lokale Texterkennung mit Google ML Kit (läuft komplett on-device).
class OcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Liest den Text eines Bildes und gibt ihn zeilenweise zurück.
  Future<String> recognizeText(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(input);

    final lines = <OcrLine>[
      for (final block in result.blocks)
        for (final line in block.lines) OcrLine(line.text, line.boundingBox),
    ];
    return OcrLayout.linesToRows(lines);
  }

  Future<void> dispose() => _recognizer.close();
}
