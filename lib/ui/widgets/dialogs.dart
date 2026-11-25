import 'package:material_ui/material_ui.dart';

/// Dialog mit einem Textfeld. Gibt den eingegebenen Text zurück (oder null).
Future<String?> promptText(
  BuildContext context, {
  required String title,
  String initial = '',
  String label = 'Name',
  String confirm = 'Speichern',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextPromptDialog(
        title: title, initial: initial, label: label, confirm: confirm),
  );
}

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.initial,
    required this.label,
    required this.confirm,
  });
  final String title, initial, label, confirm;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(fontSize: 24),
        decoration: InputDecoration(labelText: widget.label),
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(onPressed: _submit, child: Text(widget.confirm)),
      ],
    );
  }
}

/// Dialog mit zwei Feldern (Englisch / Deutsch). Gibt (englisch, deutsch) zurück.
Future<(String, String)?> promptWord(
  BuildContext context, {
  String english = '',
  String german = '',
  String title = 'Neues Wort',
}) {
  return showDialog<(String, String)>(
    context: context,
    builder: (_) => _WordDialog(title: title, english: english, german: german),
  );
}

class _WordDialog extends StatefulWidget {
  const _WordDialog({required this.title, required this.english, required this.german});
  final String title, english, german;

  @override
  State<_WordDialog> createState() => _WordDialogState();
}

class _WordDialogState extends State<_WordDialog> {
  late final TextEditingController _en = TextEditingController(text: widget.english);
  late final TextEditingController _de = TextEditingController(text: widget.german);

  @override
  void dispose() {
    _en.dispose();
    _de.dispose();
    super.dispose();
  }

  void _submit() {
    final en = _en.text.trim();
    final de = _de.text.trim();
    if (en.isNotEmpty && de.isNotEmpty) Navigator.pop(context, (en, de));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _en,
            autofocus: true,
            style: const TextStyle(fontSize: 24),
            decoration: const InputDecoration(labelText: 'Englisch'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _de,
            style: const TextStyle(fontSize: 24),
            decoration: const InputDecoration(labelText: 'Deutsch'),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(onPressed: _submit, child: const Text('Speichern')),
      ],
    );
  }
}

/// Ja/Nein-Abfrage (z. B. vor dem Löschen).
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirm = 'Löschen',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message, style: const TextStyle(fontSize: 20)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}
