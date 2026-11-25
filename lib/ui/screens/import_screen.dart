import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../data/repositories/vocabulary_repository.dart';
import '../../domain/ocr_corrector.dart';
import '../../providers/import_provider.dart';
import '../../services/ocr_service.dart';
import '../widgets/content_width.dart';

/// Foto aufnehmen -> OCR -> Wörter prüfen/korrigieren -> speichern.
class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key, required this.lessonId, required this.lessonName});
  final int lessonId;
  final String lessonName;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => ImportProvider(
        ocr: c.read<OcrService>(),
        repository: c.read<VocabularyRepository>(),
      ),
      child: _ImportView(lessonId: lessonId),
    );
  }
}

class _ImportView extends StatelessWidget {
  const _ImportView({required this.lessonId});
  final int lessonId;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ImportProvider>();
    final title = p.stage == ImportStage.review ? 'Wörter prüfen' : 'Foto scannen';

    final Widget body = switch (p.stage) {
      ImportStage.pick => const _PickView(),
      ImportStage.processing => const _ProcessingView(),
      ImportStage.review => _ReviewView(lessonId: lessonId),
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ContentWidth(child: body),
    );
  }
}

class _PickView extends StatelessWidget {
  const _PickView();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ImportProvider>();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📷', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 12),
            Text('Fotografiere eine Vokabelseite',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'Tipp: Gutes Licht, Seite gerade halten und nur die Wörterliste ins Bild nehmen.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => p.pickAndRecognize(ImageSource.camera),
                icon: const Icon(Icons.photo_camera, size: 32),
                label: const Text('Foto aufnehmen'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => p.pickAndRecognize(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, size: 32),
                label: const Text('Aus Galerie wählen'),
              ),
            ),
            if (p.error != null) ...[
              const SizedBox(height: 24),
              Text(p.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20, color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProcessingView extends StatelessWidget {
  const _ProcessingView();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 6),
            SizedBox(height: 24),
            Text('Ich lese die Seite … 🔍', style: TextStyle(fontSize: 26)),
          ],
        ),
      );
}

class _ReviewView extends StatelessWidget {
  const _ReviewView({required this.lessonId});
  final int lessonId;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ImportProvider>();
    final hint = p.uncertainCount > 0
        ? '⚠️ ${p.uncertainCount} bitte prüfen'
        : '✅ Alles sieht gut aus';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              if (p.imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(File(p.imagePath!),
                      width: 80, height: 80, fit: BoxFit.cover),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('${p.drafts.length} Einträge gefunden\n$hint',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: p.drafts.length,
              itemBuilder: (_, i) =>
                  _DraftRow(key: ValueKey(p.drafts[i].uid), draft: p.drafts[i]),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: p.addEmpty,
                  icon: const Icon(Icons.add),
                  label: const Text('Zeile'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: p.reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Neues Foto'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (p.validCount == 0 || p.isSaving)
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      final count = await p.save(lessonId);
                      navigator.pop(count);
                    },
              icon: const Icon(Icons.check, size: 30),
              label: Text('${wordsLabel(p.validCount)} speichern'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Eine bearbeitbare Zeile mit Korrekturvorschlägen bei unsicherer Erkennung.
class _DraftRow extends StatefulWidget {
  const _DraftRow({super.key, required this.draft});
  final DraftEntry draft;

  @override
  State<_DraftRow> createState() => _DraftRowState();
}

class _DraftRowState extends State<_DraftRow> {
  late final TextEditingController _en =
      TextEditingController(text: widget.draft.english);
  late final TextEditingController _de =
      TextEditingController(text: widget.draft.german);

  @override
  void dispose() {
    _en.dispose();
    _de.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<ImportProvider>();
    final d = widget.draft;
    final suggestEn = OcrCorrector.suggest(d.english);
    final suggestDe = OcrCorrector.suggest(d.german);

    return Card(
      elevation: 0,
      color: d.uncertain ? Colors.orange.shade50 : Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: d.uncertain ? Colors.orange.shade400 : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _en,
                    style: const TextStyle(fontSize: 22),
                    decoration: const InputDecoration(labelText: 'Englisch'),
                    onChanged: (v) => p.updateEnglish(d.uid, v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _de,
                    style: const TextStyle(fontSize: 22),
                    decoration: const InputDecoration(labelText: 'Deutsch'),
                    onChanged: (v) => p.updateGerman(d.uid, v),
                  ),
                ),
                IconButton(
                  iconSize: 30,
                  tooltip: 'Zeile löschen',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => p.remove(d.uid),
                ),
              ],
            ),
            if (d.uncertain) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('⚠️ Bitte prüfen', style: TextStyle(fontSize: 18)),
                  if (suggestEn != null)
                    ActionChip(
                      label: Text('Englisch: „$suggestEn“?',
                          style: const TextStyle(fontSize: 18)),
                      onPressed: () {
                        _en.text = suggestEn;
                        p.updateEnglish(d.uid, suggestEn);
                      },
                    ),
                  if (suggestDe != null)
                    ActionChip(
                      label: Text('Deutsch: „$suggestDe“?',
                          style: const TextStyle(fontSize: 18)),
                      onPressed: () {
                        _de.text = suggestDe;
                        p.updateGerman(d.uid, suggestDe);
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
