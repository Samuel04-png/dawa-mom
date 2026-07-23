import 'package:flutter/material.dart';

import '/auth/login/login_widget.dart';
import '/auth/supabase_auth/auth_util.dart';
import '/components/period_setup/period_setup_flow.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/features/learning/data/dawa_learning_repository.dart';
import '/features/learning/presentation/dawa_quest_pages.dart';
import '/features/onboarding/dawa_mom_walkthrough.dart';
import '/features/preferences/dawa_language_sheet.dart';
import '/features/preferences/dawa_user_preferences_repository.dart';
import '/features/profile/data/health_profile_repository.dart';
import '/features/profile/profile_completion_page.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/navbar/edit_profile/edit_profile_widget.dart';

class DawaMomSettingsPage extends StatefulWidget {
  const DawaMomSettingsPage({
    super.key,
    HealthProfileRepository? profileRepository,
  }) : _profileRepository = profileRepository;

  static const routeName = 'Settings';
  static const routePath = '/settings';

  final HealthProfileRepository? _profileRepository;

  @override
  State<DawaMomSettingsPage> createState() => _DawaMomSettingsPageState();
}

class _DawaMomSettingsPageState extends State<DawaMomSettingsPage> {
  late final HealthProfileRepository _profiles;
  late Future<HealthProfileSnapshot> _profile;
  late final DawaUserPreferencesRepository _preferencesRepository;
  late Future<DawaUserPreferences> _preferences;
  late final DawaLearningRepository _learningRepository;
  late Future<DawaLearningState> _learningState;

  @override
  void initState() {
    super.initState();
    _profiles = widget._profileRepository ?? HealthProfileRepository();
    _profile = _profiles.load();
    _preferencesRepository = DawaUserPreferencesRepository();
    _preferences = _preferencesRepository.load();
    _learningRepository = DawaLearningRepository();
    _learningState = _learningRepository.load();
  }

  Future<void> _refresh() async {
    final future = _profiles.load();
    setState(() => _profile = future);
    await future;
  }

  Future<void> _editProfile() async {
    await context.pushNamed(EditProfileWidget.routeName);
    if (mounted) await _refresh();
  }

  Future<void> _openCompletionHub() async {
    await context.pushNamed(ProfileCompletionPage.routeName);
    if (mounted) await _refresh();
  }

  Future<void> _chooseLanguage(DawaUserPreferences value) async {
    final result = await showDawaLanguageSheet(
      context,
      initialValue: value,
    );
    if (result == null) return;
    final saved = await _preferencesRepository.save(result);
    if (mounted) setState(() => _preferences = Future.value(saved));
  }

  Future<void> _showRewards(DawaLearningState value) async {
    final next = await showDawaRewardDialog(
      context,
      repository: _learningRepository,
      state: value,
    );
    if (next != null && mounted) {
      setState(() => _learningState = Future.value(next));
    }
  }

  Future<void> _setupPeriod(HealthProfileSnapshot profile) async {
    final result = await showPeriodSetupFlow(
      context,
      allowSkip: true,
      initialStartDate: profile.lastPeriodStart,
      initialCycleLength:
          profile.periodSettings?['averageCycleLength'] as int? ?? 28,
      initialPeriodLength: profile.periodSettings?['periodLength'] as int? ?? 5,
      initialIsRegular: profile.periodSettings?['isRegular'] as bool? ?? true,
    );
    if (result != null && result != PeriodSetupOutcome.back && mounted) {
      await _refresh();
    }
  }

  Future<void> _changePassword() async {
    final controller = TextEditingController();
    final confirmation = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change password'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: controller,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value?.length ?? 0) < 8
                      ? 'Use at least 8 characters.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: confirmation,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value != controller.text
                      ? 'Passwords do not match.'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(dialogContext, controller.text);
            },
            child: const Text('Update password'),
          ),
        ],
      ),
    );
    controller.dispose();
    confirmation.dispose();
    if (result == null || !mounted) return;
    await authManager.updatePassword(newPassword: result, context: context);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    GoRouter.of(context).prepareAuthEvent();
    await authManager.signOut();
    if (!mounted) return;
    GoRouter.of(context).clearRedirectLocation();
    context.goNamedAuth(LoginWidget.routeName, context.mounted);
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const DeleteAccountConfirmationDialog(),
    );
    if (confirmed != true || !mounted) return;

    try {
      await authManager.deleteUser(context);
      if (!mounted) return;
      context.goNamedAuth(LoginWidget.routeName, context.mounted);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account could not be deleted. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HealthProfileSnapshot>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const DawaPageScaffold(
            scrollable: false,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return DawaPageScaffold(
            child: DawaCard(
              child: Column(
                children: [
                  const DawaIconBadge(
                    icon: Icons.cloud_off_rounded,
                    size: 58,
                  ),
                  const SizedBox(height: 10),
                  Text('Profile could not be loaded',
                      style: context.dawaSectionTitle),
                  const SizedBox(height: 5),
                  Text(
                    'Check your connection and try again.',
                    style: context.dawaCaption,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        final profile = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: DawaPageScaffold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DawaAppHeader(
                  title: 'My profile',
                  notificationUnread: true,
                  onNotifications: () => context.push('/notifications'),
                ),
                const SizedBox(height: 8),
                DawaCard(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final image = SizedBox(
                        width: constraints.maxWidth < 480 ? 100 : 132,
                        height: 132,
                        child: Image.asset(
                          DawaArtwork.motherGreeting,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      );
                      final details = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name.isEmpty
                                ? 'Dawa Mom member'
                                : profile.name,
                            style: context.dawaTitle.copyWith(fontSize: 21),
                          ),
                          const SizedBox(height: 4),
                          if (profile.phone.isNotEmpty)
                            Text('☎  ${profile.phone}',
                                style: context.dawaCaption),
                          if (profile.email.isNotEmpty)
                            Text(profile.email, style: context.dawaCaption),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _editProfile,
                            icon: const Icon(Icons.edit_outlined, size: 17),
                            label: const Text('Edit profile'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(44, 42),
                            ),
                          ),
                        ],
                      );
                      return Row(
                        children: [
                          image,
                          const SizedBox(width: 14),
                          Expanded(child: details),
                          if (constraints.maxWidth >= 600)
                            SizedBox(
                              width: 120,
                              height: 130,
                              child: Image.asset(
                                DawaArtwork.motherBabyLine,
                                fit: BoxFit.contain,
                                excludeFromSemantics: true,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                const DawaSectionHeader(
                  title: 'Health summary',
                  actionLabel: 'View all',
                ),
                const SizedBox(height: 8),
                DawaCard(
                  child: DawaResponsiveGrid(
                    mobileColumns: 2,
                    tabletColumns: 4,
                    desktopColumns: 4,
                    children: [
                      _ProfileSummaryFact(
                        icon: Icons.pregnant_woman_rounded,
                        color: DawaColors.purple,
                        label: 'Pregnancy',
                        value: profile.pregnancyWeek == null
                            ? 'Not recorded'
                            : '${profile.pregnancyWeek} weeks',
                        helper: profile.trimester == null
                            ? 'Update profile'
                            : 'Trimester ${profile.trimester}',
                      ),
                      _ProfileSummaryFact(
                        icon: Icons.water_drop_rounded,
                        color: DawaColors.pink,
                        label: 'Cycle tracking',
                        value: profile.periodComplete ? 'Set up' : 'Not set up',
                        helper: profile.periodComplete
                            ? 'Tracking active'
                            : 'Add last period',
                      ),
                      _ProfileSummaryFact(
                        icon: Icons.fact_check_outlined,
                        color: DawaColors.green,
                        label: 'Profile',
                        value: '${profile.completedSections}/4 sections',
                        helper: profile.isComplete
                            ? 'Up to date'
                            : 'Needs attention',
                      ),
                      _ProfileSummaryFact(
                        icon: Icons.local_hospital_outlined,
                        color: DawaColors.primary,
                        label: 'Care link',
                        value: profile.isMappedToDawaClinician
                            ? 'Connected'
                            : 'Pending',
                        helper: profile.patientSyncNeedsAttention
                            ? 'Review required'
                            : 'Dawa care',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<DawaLearningState>(
                  future: _learningState,
                  builder: (context, learningSnapshot) {
                    final state =
                        learningSnapshot.data ?? const DawaLearningState();
                    return DawaCard(
                      onTap: learningSnapshot.connectionState ==
                              ConnectionState.done
                          ? () => _showRewards(state)
                          : null,
                      semanticLabel: 'Dawa rewards. ${state.coins} points.',
                      color: DawaColors.softBlue,
                      child: Row(
                        children: [
                          const DawaIconBadge(
                            icon: Icons.workspace_premium_rounded,
                            size: 52,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Dawa Rewards',
                                    style: context.dawaCaption),
                                Text('${state.coins} points',
                                    style: context.dawaTitle),
                                const SizedBox(height: 6),
                                DawaProgressBar(
                                  value: state.coins / 1000,
                                  semanticLabel: 'Free scan reward progress',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.redeem_rounded,
                              color: DawaColors.primary, size: 36),
                          const Icon(Icons.chevron_right_rounded,
                              color: DawaColors.primary),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                Text('Settings', style: context.dawaSectionTitle),
                const SizedBox(height: 8),
                FutureBuilder<DawaUserPreferences>(
                  future: _preferences,
                  builder: (context, preferenceSnapshot) {
                    final preferences =
                        preferenceSnapshot.data ?? const DawaUserPreferences();
                    return DawaCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Column(
                        children: [
                          _DawaSettingsRow(
                            icon: Icons.language_rounded,
                            title: 'Language',
                            trailing: preferences.language,
                            onTap: preferenceSnapshot.connectionState ==
                                    ConnectionState.done
                                ? () => _chooseLanguage(preferences)
                                : null,
                          ),
                          _DawaSettingsRow(
                            icon: Icons.notifications_none_rounded,
                            title: 'Notifications',
                            onTap: () => context.push('/notifications'),
                          ),
                          _DawaSettingsRow(
                            icon: Icons.health_and_safety_outlined,
                            title: 'Health profile',
                            onTap: _openCompletionHub,
                          ),
                          _DawaSettingsRow(
                            icon: Icons.water_drop_outlined,
                            title: 'Period Tracker setup',
                            trailing:
                                profile.periodComplete ? 'Set up' : 'Not set',
                            onTap: () => _setupPeriod(profile),
                          ),
                          _DawaSettingsRow(
                            icon: Icons.lock_outline_rounded,
                            title: 'Privacy',
                            onTap: _changePassword,
                          ),
                          _DawaSettingsRow(
                            icon: Icons.help_outline_rounded,
                            title: 'Help & support',
                            onTap: () => showDawaMomWalkthrough(context),
                            showDivider: false,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openCompletionHub,
                        icon: const Icon(Icons.person_outline_rounded),
                        label: const Text('Health profile'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.go('/encounters'),
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('View care records'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Account and profile', style: context.dawaSectionTitle),
                const SizedBox(height: 8),
                _HealthSettings(
                  profile: profile,
                  onOpenCompletion: _openCompletionHub,
                  onSetupPeriod: () => _setupPeriod(profile),
                ),
                const SizedBox(height: 12),
                _PrivacySettings(onChangePassword: _changePassword),
                const SizedBox(height: 12),
                _SupportSettings(
                  onReplayTour: () => showDawaMomWalkthrough(context),
                ),
                const SizedBox(height: 12),
                _AccountActions(
                  onLogout: _logout,
                  onDelete: _deleteAccount,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileSummaryFact extends StatelessWidget {
  const _ProfileSummaryFact({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.helper,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$label. $value. $helper.',
        child: Column(
          children: [
            DawaIconBadge(icon: icon, color: color),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center, style: context.dawaCaption),
            Text(value,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.dawaSectionTitle),
            Text(helper,
                textAlign: TextAlign.center, style: context.dawaCaption),
          ],
        ),
      );
}

class _DawaSettingsRow extends StatelessWidget {
  const _DawaSettingsRow({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ListTile(
            minTileHeight: 48,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: Icon(icon, color: DawaColors.primary, size: 21),
            title: Text(title, style: context.dawaBody),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailing != null)
                  Text(trailing!, style: context.dawaCaption),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: DawaColors.muted),
              ],
            ),
            onTap: onTap,
          ),
          if (showDivider) const Divider(height: 1),
        ],
      );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: theme.secondaryBackground,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.alternate),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.titleSmall.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _HealthSettings extends StatelessWidget {
  const _HealthSettings({
    required this.profile,
    required this.onOpenCompletion,
    required this.onSetupPeriod,
  });
  final HealthProfileSnapshot profile;
  final VoidCallback onOpenCompletion;
  final VoidCallback onSetupPeriod;

  @override
  Widget build(BuildContext context) => _SettingsCard(
        title: 'Health and tracking',
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Health profile'),
            subtitle: Text(profile.dashboardPrompt),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onOpenCompletion,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.water_drop_outlined),
            title: const Text('Period Tracker setup'),
            subtitle: Text(
              profile.periodComplete ? 'Set up' : 'Not set up',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onSetupPeriod,
          ),
        ],
      );
}

class _PrivacySettings extends StatelessWidget {
  const _PrivacySettings({required this.onChangePassword});
  final VoidCallback onChangePassword;

  @override
  Widget build(BuildContext context) => _SettingsCard(
        title: 'Privacy and security',
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_outline_rounded),
            title: const Text('Change password'),
            subtitle: const Text('Update your sign-in password'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onChangePassword,
          ),
        ],
      );
}

class _SupportSettings extends StatelessWidget {
  const _SupportSettings({required this.onReplayTour});
  final VoidCallback onReplayTour;

  @override
  Widget build(BuildContext context) => _SettingsCard(
        title: 'Help and About Dawa Mom',
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.tour_outlined),
            title: const Text('Replay app tour'),
            subtitle: const Text('Review the main Dawa Mom features'),
            trailing: const Icon(Icons.play_arrow_rounded),
            onTap: onReplayTour,
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline_rounded),
            title: Text('About Dawa Mom'),
            subtitle: Text(
              'Maternal health guidance, appointments and cycle tracking in one place.',
            ),
          ),
        ],
      );
}

class _AccountActions extends StatelessWidget {
  const _AccountActions({required this.onLogout, required this.onDelete});
  final VoidCallback onLogout;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return _SettingsCard(
      title: 'Account actions',
      children: [
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Logout'),
        ),
        const Divider(height: 28),
        Text(
          'Danger zone',
          style: theme.bodyMedium.copyWith(
            color: theme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Deleting your account is permanent.',
          style: theme.bodySmall.copyWith(color: theme.secondaryText),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          key: const ValueKey('delete-account'),
          onPressed: onDelete,
          icon: const Icon(Icons.delete_forever_outlined),
          label: const Text('Delete account'),
          style: TextButton.styleFrom(foregroundColor: theme.error),
        ),
      ],
    );
  }
}

class DeleteAccountConfirmationDialog extends StatefulWidget {
  const DeleteAccountConfirmationDialog({super.key});

  @override
  State<DeleteAccountConfirmationDialog> createState() =>
      _DeleteAccountConfirmationDialogState();
}

class _DeleteAccountConfirmationDialogState
    extends State<DeleteAccountConfirmationDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Permanently delete account?'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently deletes your Dawa Mom account, profile, appointments and tracker data. This action cannot be undone.',
              ),
              const SizedBox(height: 18),
              const Text('Type DELETE to confirm.'),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('delete-account-confirmation'),
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'DELETE',
                ),
                onChanged: (value) => setState(
                  () => _matches = value.trim() == 'DELETE',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep account'),
          ),
          FilledButton(
            key: const ValueKey('confirm-delete-account'),
            onPressed: _matches ? () => Navigator.pop(context, true) : null,
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete permanently'),
          ),
        ],
      );
}
