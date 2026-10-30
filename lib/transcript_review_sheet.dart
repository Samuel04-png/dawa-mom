import 'package:flutter/material.dart';

enum TranscriptReviewAction { send, rerecord }

class TranscriptReviewResult {
  const TranscriptReviewResult({
    required this.action,
    required this.text,
    required this.edited,
  });

  final TranscriptReviewAction action;

  /// The text to send (already trimmed). Empty only for [TranscriptReviewAction.rerecord].
  final String text;

  /// True if the user changed the transcript. The backend uses this to decide
  /// whether to trust the language heard in the audio or re-detect it from the
  /// edited text.
  final bool edited;
}

/// Shows the transcript in an editable box. Returns null if the user dismisses
/// the sheet (treat that as cancel and send nothing).
Future<TranscriptReviewResult?> showTranscriptReview(
  BuildContext context, {
  required String initialText,
  String? language,
}) {
  return showModalBottomSheet<TranscriptReviewResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _TranscriptReviewSheet(
      initialText: initialText,
      language: language,
    ),
  );
}

class _TranscriptReviewSheet extends StatefulWidget {
  const _TranscriptReviewSheet({
    required this.initialText,
    this.language,
  });

  final String initialText;
  final String? language;

  @override
  State<_TranscriptReviewSheet> createState() => _TranscriptReviewSheetState();
}

class _TranscriptReviewSheetState extends State<_TranscriptReviewSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _text => _controller.text.trim();

  void _send() {
    if (_text.isEmpty) return;
    Navigator.of(context).pop(
      TranscriptReviewResult(
        action: TranscriptReviewAction.send,
        text: _text,
        edited: _text != widget.initialText.trim(),
      ),
    );
  }

  void _rerecord() {
    Navigator.of(context).pop(
      const TranscriptReviewResult(
        action: TranscriptReviewAction.rerecord,
        text: '',
        edited: false,
      ),
    );
  }

  String _languageLabel(String language) {
    if (language.isEmpty) return language;
    return language[0].toUpperCase() + language.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final language = widget.language;

    return Padding(
      // Keep the buttons above the keyboard while editing.
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Check what I heard',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (language != null && language.isNotEmpty)
                    Chip(
                      label: Text(_languageLabel(language)),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Fix any mistakes, then send.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                minLines: 2,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Your message',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _rerecord,
                      icon: const Icon(Icons.mic),
                      label: const Text('Record again'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _text.isEmpty ? null : _send,
                      icon: const Icon(Icons.send),
                      label: const Text('Send'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
