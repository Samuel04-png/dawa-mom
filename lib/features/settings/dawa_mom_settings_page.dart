import '/localization/dawa_localized_material.dart';

import '/auth/login/login_widget.dart';
import '/auth/supabase_auth/auth_util.dart';
import '/components/period_setup/period_setup_flow.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/components/responsive/dawa_mom_responsive_shell.dart';
import '/features/learning/data/dawa_learning_repository.dart';
import '/features/onboarding/dawa_main_app_tour.dart';
import '/features/preferences/dawa_language_sheet.dart';
import '/features/preferences/dawa_user_preferences_repository.dart';
import '/features/profile/data/health_profile_repository.dart';
import '/features/profile/profile_completion_page.dart';
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
    await context.push('/learn/rewards');
    if (mounted) setState(() => _learningState = _learningRepository.load());
  }

  void _showSupport() {
    final pageContext = context;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DawaBottomSheetFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const DawaIconBadge(
                  icon: Icons.support_agent_rounded,
                  color: DawaColors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('How can we help?', style: pageContext.dawaTitle),
                ),
                IconButton(
                  tooltip: 'Close support',
                  onPressed: () => Navigator.pop(sheetContext),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DawaCard(
              onTap: () {
                Navigator.pop(sheetContext);
                DawaMomResponsiveShell.openRudo(pageContext);
              },
              semanticLabel: 'Ask Rudo for general health guidance',
              color: DawaColors.softBlue,
              child: Row(
                children: [
                  const DawaIconBadge(
                    icon: Icons.chat_bubble_outline_rounded,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ask Rudo', style: pageContext.dawaSectionTitle),
                        Text(
                          'Basic health help and help finding the right page.',
                          style: pageContext.dawaCaption,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: DawaColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 10),
            DawaCard(
              onTap: () {
                Navigator.pop(sheetContext);
                pageContext.go('/encounters');
              },
              semanticLabel: 'Open care and appointments',
              child: Row(
                children: [
                  const DawaIconBadge(
                    icon: Icons.medical_services_outlined,
                    color: DawaColors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Care and appointments',
                            style: pageContext.dawaSectionTitle),
                        Text(
                          'Book a visit or review an upcoming appointment.',
                          style: pageContext.dawaCaption,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: DawaColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 12),
            DawaCard(
              color: DawaColors.softPink,
              borderColor: DawaColors.pink.withValues(alpha: .3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.emergency_rounded, color: DawaColors.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'For severe pain, heavy bleeding, trouble breathing, fainting, or pregnancy danger signs, seek urgent local medical care now.',
                      style: pageContext.dawaCaption.copyWith(
                        color: DawaColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
                  decoration: InputDecoration(
                    labelText: 'New password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value?.length ?? 0) < 8
                      ? context.tr('Use at least 8 characters.')
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: confirmation,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm new password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value != controller.text
                      ? context.tr('Passwords do not match.')
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HealthProfileSnapshot>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const DawaPageScaffold(
            child: DawaPageSkeleton(
              label: 'Loading your profile',
              cardCount: 3,
            ),
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
                        width: constraints.maxWidth < 480 ? 116 : 142,
                        height: constraints.maxWidth < 480 ? 124 : 142,
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
                                ? 'DawaMom member'
                                : profile.name,
                            style: context.dawaTitle.copyWith(fontSize: 21),
                          ),
                          const SizedBox(height: 4),
                          if (profile.phone.isNotEmpty)
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone_outlined,
                                  size: 13,
                                  color: DawaColors.muted,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    profile.phone,
                                    style: context.dawaCaption,
                                  ),
                                ),
                              ],
                            ),
                          if (profile.email.isNotEmpty)
                            Text(profile.email, style: context.dawaCaption),
                          const SizedBox(height: 9),
                          Text(
                            profile.isComplete
                                ? 'Profile complete'
                                : 'Profile ${((profile.completedSections / 4) * 100).round()}% complete',
                            style: context.dawaCaption.copyWith(
                              color: profile.isComplete
                                  ? DawaColors.green
                                  : DawaColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          DawaProgressBar(
                            value: profile.completedSections / 4,
                            semanticLabel: 'Profile completion progress',
                            color: profile.isComplete
                                ? DawaColors.green
                                : DawaColors.primary,
                          ),
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
                        onTap: _openCompletionHub,
                      ),
                      _ProfileSummaryFact(
                        icon: Icons.water_drop_rounded,
                        color: DawaColors.pink,
                        label: 'Cycle tracking',
                        value: profile.periodComplete ? 'Active' : 'Not set up',
                        helper: profile.periodComplete
                            ? 'Cycle details saved'
                            : 'Add last period',
                        onTap: () => _setupPeriod(profile),
                      ),
                      _ProfileSummaryFact(
                        icon: Icons.fact_check_outlined,
                        color: DawaColors.green,
                        label: 'Profile',
                        value: '${profile.completedSections}/4 sections',
                        helper: profile.isComplete
                            ? 'Up to date'
                            : 'Needs attention',
                        onTap: _openCompletionHub,
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
                        onTap: _openCompletionHub,
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
                            trailing: 'Preferences',
                            onTap: () =>
                                context.push('/notification-preferences'),
                          ),
                          _DawaSettingsRow(
                            icon: Icons.lock_outline_rounded,
                            title: 'Privacy',
                            onTap: _changePassword,
                          ),
                          _DawaSettingsRow(
                            icon: Icons.tour_outlined,
                            title: 'Take the app tour again',
                            onTap: () => DawaMainAppTourScope.replay(context),
                          ),
                          _DawaSettingsRow(
                            icon: Icons.help_outline_rounded,
                            title: 'Help & support',
                            onTap: _showSupport,
                          ),
                          _DawaSettingsRow(
                            icon: Icons.info_outline_rounded,
                            title: 'About DawaMom',
                            onTap: _showSupport,
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
                Text('Account', style: context.dawaSectionTitle),
                const SizedBox(height: 8),
                _AccountActions(
                  onLogout: _logout,
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
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String helper;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$label. $value. $helper.',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DawaRadii.small),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
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
          ),
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
            minTileHeight: 58,
            minLeadingWidth: 38,
            horizontalTitleGap: 12,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: DawaIconBadge(
              icon: icon,
              color: DawaColors.primary,
              size: 38,
            ),
            title: Text(title, style: context.dawaBody),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailing != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 112),
                    child: Text(
                      trailing!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.dawaCaption,
                    ),
                  ),
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

class _AccountActions extends StatelessWidget {
  const _AccountActions({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          key: const ValueKey('profile-logout'),
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Logout'),
        ),
      );
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
                'This permanently deletes your DawaMom account, profile, appointments and tracker data. This action cannot be undone.',
              ),
              const SizedBox(height: 18),
              const Text('Type DELETE to confirm.'),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('delete-account-confirmation'),
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
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
