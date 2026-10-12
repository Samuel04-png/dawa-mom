import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/localization/dawa_localized_material.dart';

import 'dawa_user_preferences_repository.dart';

/// Controls optional, non-clinical feedback used across DawaMom.
///
/// These settings are stored on the device. They do not need health data or a
/// network connection, so a user can change them even while offline.
class DawaAppPreferencesPage extends StatefulWidget {
  const DawaAppPreferencesPage({super.key, this.repository});

  static const routeName = 'AppPreferences';
  static const routePath = '/app-preferences';

  final DawaUserPreferencesRepository? repository;

  @override
  State<DawaAppPreferencesPage> createState() => _DawaAppPreferencesPageState();
}

class _DawaAppPreferencesPageState extends State<DawaAppPreferencesPage> {
  late final DawaUserPreferencesRepository _repository;
  DawaUserPreferences? _preferences;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DawaUserPreferencesRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final preferences = await _repository.load();
      if (!mounted) return;
      setState(() {
        _preferences = preferences;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'App preferences could not be loaded. Please try again.';
      });
    }
  }

  Future<void> _save(DawaUserPreferences value) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await _repository.save(value);
      if (!mounted) return;
      setState(() {
        _preferences = saved;
        _saving = false;
      });
      if (saved.hapticFeedbackEnabled) {
        await HapticFeedback.selectionClick();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App preferences saved.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Your app preferences could not be saved. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => DawaPageScaffold(
        maxWidth: 760,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DawaAppHeader(title: 'App preferences', onBack: context.pop),
            const SizedBox(height: DawaSpacing.sm),
            if (_loading)
              const DawaLoadingSkeleton(
                lines: 4,
                label: 'Loading app preferences',
              )
            else if (_preferences == null)
              DawaErrorState(
                title: 'Preferences unavailable',
                message: _error ?? 'Your app preferences could not be loaded.',
                onRetry: _load,
              )
            else
              _buildPreferences(_preferences!),
          ],
        ),
      );

  Widget _buildPreferences(DawaUserPreferences value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DawaCard(
            color: DawaColors.softBlue,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DawaIconBadge(
                  icon: Icons.tune_rounded,
                  color: DawaColors.primary,
                ),
                const SizedBox(width: DawaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Make Dawa feel right for you',
                          style: context.dawaSectionTitle),
                      const SizedBox(height: DawaSpacing.xxs),
                      Text(
                        'These optional cues make completed actions clearer. Important messages always remain visible, even when they are off.',
                        style: context.dawaBody,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DawaSpacing.md),
          const DawaSectionHeader(
            title: 'Feedback',
            subtitle: 'Choose the feedback you want after actions finish.',
          ),
          const SizedBox(height: DawaSpacing.xs),
          DawaCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _AppPreferenceSwitch(
                  icon: Icons.volume_up_outlined,
                  title: 'Sound effects',
                  subtitle: 'Play short sounds when actions finish.',
                  value: value.soundEffectsEnabled,
                  onChanged: _saving
                      ? null
                      : (enabled) => _save(
                            value.copyWith(soundEffectsEnabled: enabled),
                          ),
                ),
                _AppPreferenceSwitch(
                  icon: Icons.animation_outlined,
                  title: 'Animations',
                  subtitle:
                      'Show movement and celebrations when actions finish.',
                  value: !value.reducedAnimations,
                  onChanged: _saving
                      ? null
                      : (enabled) => _save(
                            value.copyWith(reducedAnimations: !enabled),
                          ),
                ),
                _AppPreferenceSwitch(
                  icon: Icons.vibration_rounded,
                  title: 'Vibration',
                  subtitle: 'Use gentle feedback after a confirmed action.',
                  value: value.hapticFeedbackEnabled,
                  onChanged: _saving
                      ? null
                      : (enabled) => _save(
                            value.copyWith(hapticFeedbackEnabled: enabled),
                          ),
                  showDivider: false,
                ),
              ],
            ),
          ),
          if (_saving) ...[
            const SizedBox(height: DawaSpacing.sm),
            const LinearProgressIndicator(),
          ],
          if (_error != null) ...[
            const SizedBox(height: DawaSpacing.sm),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: context.dawaBody.copyWith(color: DawaColors.danger),
              ),
            ),
          ],
        ],
      );
}

class _AppPreferenceSwitch extends StatelessWidget {
  const _AppPreferenceSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          SwitchListTile(
            secondary: Icon(icon, color: DawaColors.primary),
            title: Text(title, style: context.dawaSectionTitle),
            subtitle: Text(subtitle, style: context.dawaCaption),
            value: value,
            activeTrackColor: DawaColors.primary,
            onChanged: onChanged,
          ),
          if (showDivider) const Divider(height: 1),
        ],
      );
}
