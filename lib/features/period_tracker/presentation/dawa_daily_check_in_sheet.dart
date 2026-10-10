import '/localization/dawa_localized_material.dart';
import 'package:intl/intl.dart';

import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';

/// Callback invoked when the user confirms a check-in log.
///
/// Exposed as a dedicated typedef so both the cycle tracker and the home
/// dashboard can share the same save contract.
typedef DawaDailyCheckInSave = Future<void> Function({
  required List<String> symptoms,
  required double pain,
  required String feeling,
  required String note,
});

/// Presents the daily "How are you feeling" check-in sheet and returns
/// whether the user saved their log.
Future<bool> showDawaDailyCheckInSheet(
  BuildContext context, {
  required DateTime date,
  required Map<String, dynamic>? existing,
  required DawaDailyCheckInSave onSave,
}) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.46),
      builder: (context) => DawaDailyCheckInSheet(
        date: date,
        existing: existing,
        onSave: onSave,
      ),
    ) ??
    false;

class DawaDailyCheckInSheet extends StatefulWidget {
  const DawaDailyCheckInSheet({
    super.key,
    required this.date,
    required this.existing,
    required this.onSave,
  });

  final DateTime date;
  final Map<String, dynamic>? existing;
  final DawaDailyCheckInSave onSave;

  @override
  State<DawaDailyCheckInSheet> createState() => _DawaDailyCheckInSheetState();
}

class _DawaDailyCheckInSheetState extends State<DawaDailyCheckInSheet> {
  static const _symptoms = [
    ('Cramps', Icons.gesture_rounded),
    ('Headache', Icons.psychology_outlined),
    ('Nausea', Icons.sick_outlined),
    ('Discharge', Icons.water_drop_outlined),
    ('Mood', Icons.sentiment_satisfied_outlined),
    ('Energy', Icons.bolt_rounded),
    ('Appetite', Icons.restaurant_outlined),
    ('Sleep', Icons.bedtime_outlined),
  ];
  static const _feelings = ['Great', 'Good', 'Okay', 'Poor', 'Very poor'];

  late final Set<String> _selected;
  final _note = TextEditingController();
  double _pain = 1;
  String _feeling = 'Good';
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(
      widget.existing?['symptoms'] as List? ?? const [],
    );
    final notes =
        List<String>.from(widget.existing?['notes'] as List? ?? const []);
    for (final value in notes) {
      if (value.startsWith('Pain:')) {
        _pain = double.tryParse(
              RegExp(r'\d+').firstMatch(value)?.group(0) ?? '',
            ) ??
            1;
      } else if (value.startsWith('Overall feeling:')) {
        _feeling = value.split(':').last.trim();
      } else {
        _note.text = value;
      }
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSave(
        symptoms: _selected.toList()..sort(),
        pain: _pain,
        feeling: _feeling,
        note: _note.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Your check-in could not be saved. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => DawaBottomSheetFrame(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How are you feeling today?',
                          style: context.dawaTitle,
                        ),
                        Text(
                          DateFormat('EEEE, d MMMM').format(widget.date),
                          style: context.dawaCaption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close check-in',
                    onPressed:
                        _busy ? null : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: DawaSpacing.xs),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DawaCard(
                        color: DawaColors.softBlue,
                        radius: DawaRadii.small,
                        padding: const EdgeInsets.all(DawaSpacing.xs),
                        child: Row(
                          children: [
                            const DawaIconBadge(
                              icon: Icons.water_drop_rounded,
                              color: DawaColors.pink,
                              size: 36,
                            ),
                            const SizedBox(width: DawaSpacing.xs),
                            Expanded(
                              child: Text(
                                'A quick check-in can help you notice patterns over time.',
                                style: context.dawaCaption,
                              ),
                            ),
                            SizedBox(
                              width: 46,
                              height: 50,
                              child: Image.asset(
                                DawaArtwork.cycleCramps,
                                fit: BoxFit.contain,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DawaSpacing.sm),
                      Text('Overall feeling', style: context.dawaSectionTitle),
                      const SizedBox(height: DawaSpacing.xs),
                      Wrap(
                        spacing: DawaSpacing.xs,
                        runSpacing: DawaSpacing.xs,
                        children: [
                          for (final feeling in _feelings)
                            ChoiceChip(
                              avatar: Icon(
                                _feelingIcon(feeling),
                                color:
                                    feeling == 'Poor' || feeling == 'Very poor'
                                        ? DawaColors.danger
                                        : DawaColors.greenDark,
                                size: 17,
                              ),
                              label: Text(feeling),
                              selected: _feeling == feeling,
                              onSelected: (_) =>
                                  setState(() => _feeling = feeling),
                            ),
                        ],
                      ),
                      const SizedBox(height: DawaSpacing.md),
                      Text('Select any symptoms you’re experiencing',
                          style: context.dawaSectionTitle),
                      const SizedBox(height: DawaSpacing.xs),
                      Wrap(
                        spacing: DawaSpacing.xs,
                        runSpacing: DawaSpacing.xs,
                        children: [
                          for (final symptom in _symptoms)
                            FilterChip(
                              avatar: Icon(symptom.$2, size: 17),
                              label: Text(symptom.$1),
                              selected: _selected.contains(symptom.$1),
                              onSelected: (selected) => setState(() {
                                selected
                                    ? _selected.add(symptom.$1)
                                    : _selected.remove(symptom.$1);
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: DawaSpacing.md),
                      DawaCard(
                        radius: DawaRadii.small,
                        color: DawaColors.warmSurface,
                        padding: const EdgeInsets.fromLTRB(
                          DawaSpacing.sm,
                          DawaSpacing.xs,
                          DawaSpacing.sm,
                          DawaSpacing.xxs,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Pain level',
                                      style: context.dawaSectionTitle),
                                ),
                                Text(
                                  '${_pain.round()} / 10',
                                  style: context.dawaSectionTitle.copyWith(
                                    color: DawaColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _pain,
                              min: 1,
                              max: 10,
                              divisions: 9,
                              label: '${_pain.round()}',
                              onChanged: (value) =>
                                  setState(() => _pain = value),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DawaSpacing.sm),
                      TextField(
                        controller: _note,
                        maxLength: 250,
                        minLines: 2,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Add a note (optional)',
                          hintText: 'Anything else you want to remember?',
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: context.dawaCaption
                                .copyWith(color: DawaColors.danger),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed:
                        _busy ? null : () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : _save,
                      child: _busy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save log'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

IconData _feelingIcon(String feeling) => switch (feeling) {
      'Great' => Icons.sentiment_very_satisfied_rounded,
      'Good' => Icons.sentiment_satisfied_rounded,
      'Okay' => Icons.sentiment_neutral_rounded,
      'Poor' => Icons.sentiment_dissatisfied_rounded,
      _ => Icons.sentiment_very_dissatisfied_rounded,
    };
