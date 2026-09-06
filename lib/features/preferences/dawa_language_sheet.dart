import 'dart:async';

import '/localization/dawa_localized_material.dart';

import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import 'dawa_user_preferences_repository.dart';

Future<DawaUserPreferences?> showDawaLanguageSheet(
  BuildContext context, {
  required DawaUserPreferences initialValue,
}) =>
    showModalBottomSheet<DawaUserPreferences>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.46),
      builder: (context) => DawaLanguageSheet(initialValue: initialValue),
    );

class DawaLanguageSheet extends StatefulWidget {
  const DawaLanguageSheet({
    super.key,
    required this.initialValue,
  });

  final DawaUserPreferences initialValue;

  @override
  State<DawaLanguageSheet> createState() => _DawaLanguageSheetState();
}

class _DawaLanguageSheetState extends State<DawaLanguageSheet> {
  late String _language;
  late bool _lessonLanguage;
  late bool _rudoLanguage;

  @override
  void initState() {
    super.initState();
    _language = DawaLanguages.names.contains(widget.initialValue.language)
        ? widget.initialValue.language
        : DawaLanguages.english;
    _lessonLanguage = widget.initialValue.lessonLanguageEnabled;
    _rudoLanguage = widget.initialValue.rudoLanguageEnabled;
  }

  @override
  Widget build(BuildContext context) => PopScope<DawaUserPreferences>(
        onPopInvokedWithResult: (didPop, result) {
          if (didPop && result == null) {
            unawaited(
              DawaLocaleController.instance.setLanguage(
                widget.initialValue.language,
                persist: false,
              ),
            );
          }
        },
        child: DawaBottomSheetFrame(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.9,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Choose language', style: context.dawaTitle),
                          const SizedBox(height: 3),
                          Text(
                            'Select the language you’re most comfortable with.',
                            style: context.dawaCaption,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      height: 70,
                      child: Image.asset(
                        DawaArtwork.motherBabyLine,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DawaCard(
                          padding: EdgeInsets.zero,
                          child: RadioGroup<String>(
                            groupValue: _language,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _language = value);
                                unawaited(
                                  DawaLocaleController.instance.setLanguage(
                                    value,
                                    persist: false,
                                  ),
                                );
                              }
                            },
                            child: Column(
                              children: [
                                for (final language in DawaLanguages.names)
                                  _LanguageRow(
                                    language: language,
                                    selected: _language == language,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        DawaCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          child: Column(
                            children: [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                secondary: const Icon(Icons.menu_book_outlined),
                                title:
                                    const Text('Use this language for lessons'),
                                subtitle: const Text(
                                  'Articles and lessons use this preference.',
                                ),
                                value: _lessonLanguage,
                                activeThumbColor: DawaColors.green,
                                onChanged: (value) =>
                                    setState(() => _lessonLanguage = value),
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                secondary: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                ),
                                title:
                                    const Text('Use this language with Rudo'),
                                subtitle: const Text(
                                  'Rudo will use this language when supported.',
                                ),
                                value: _rudoLanguage,
                                activeThumbColor: DawaColors.green,
                                onChanged: (value) =>
                                    setState(() => _rudoLanguage = value),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(
                          context,
                          widget.initialValue.copyWith(
                            language: _language,
                            lessonLanguageEnabled: _lessonLanguage,
                            rudoLanguageEnabled: _rudoLanguage,
                          ),
                        ),
                        child: const Text('Save language'),
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

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.language,
    required this.selected,
  });

  final String language;
  final bool selected;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? DawaColors.softBlue : Colors.transparent,
        child: RadioListTile<String>(
          value: language,
          selected: selected,
          title: Text(
            language,
            style: TextStyle(
              color: selected ? DawaColors.primary : DawaColors.ink,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          secondary: DawaIconBadge(
            icon: Icons.language_rounded,
            size: 34,
            color: selected ? DawaColors.primary : DawaColors.muted,
          ),
          dense: true,
          activeColor: DawaColors.primary,
          controlAffinity: ListTileControlAffinity.trailing,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      );
}
