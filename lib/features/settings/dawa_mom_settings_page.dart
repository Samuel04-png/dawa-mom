import 'package:flutter/material.dart';

import '/auth/login/login_widget.dart';
import '/auth/supabase_auth/auth_util.dart';
import '/components/period_setup/period_setup_flow.dart';
import '/components/responsive/responsive_layout.dart';
import '/features/onboarding/dawa_mom_walkthrough.dart';
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

  @override
  void initState() {
    super.initState();
    _profiles = widget._profileRepository ?? HealthProfileRepository();
    _profile = _profiles.load();
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
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: theme.primaryBackground,
        foregroundColor: theme.primaryText,
        title: Text(
          'Settings',
          style: theme.headlineSmall.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: FutureBuilder<HealthProfileSnapshot>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return DawaMomEmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Settings could not be loaded',
              description: 'Check your connection and try again.',
              actionLabel: 'Retry',
              onAction: _refresh,
            );
          }
          final profile = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ResponsivePageContainer(
                maxWidth: 1040,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final account = _AccountCard(
                      profile: profile,
                      onEdit: _editProfile,
                    );
                    final healthSettings = _HealthSettings(
                      profile: profile,
                      onOpenCompletion: _openCompletionHub,
                      onSetupPeriod: () => _setupPeriod(profile),
                    );
                    final privacySettings = _PrivacySettings(
                      onChangePassword: _changePassword,
                    );
                    final supportSettings = _SupportSettings(
                      onReplayTour: () => showDawaMomWalkthrough(context),
                    );
                    final accountActions = _AccountActions(
                      onLogout: _logout,
                      onDelete: _deleteAccount,
                    );
                    if (constraints.maxWidth >= 860) {
                      return Column(
                        children: [
                          account,
                          const SizedBox(height: 18),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    healthSettings,
                                    const SizedBox(height: 16),
                                    supportSettings,
                                  ],
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  children: [
                                    privacySettings,
                                    const SizedBox(height: 16),
                                    accountActions,
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        account,
                        ...[
                          healthSettings,
                          privacySettings,
                          supportSettings,
                          accountActions,
                        ].expand(
                          (section) => [
                            const SizedBox(height: 14),
                            section,
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
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

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.profile, required this.onEdit});

  final HealthProfileSnapshot profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return _SettingsCard(
      title: 'Account and profile',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final avatar = CircleAvatar(
              radius: 34,
              backgroundColor: theme.primary.withValues(alpha: 0.1),
              backgroundImage: const AssetImage(
                'assets/images/transparent assets/Frame_41.png',
              ),
            );
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name.isEmpty ? 'Dawa Mom member' : profile.name,
                  style: theme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  profile.email,
                  style: theme.bodySmall.copyWith(color: theme.secondaryText),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 5,
                  children: [
                    _ProfileFact(
                      icon: Icons.phone_outlined,
                      text: profile.phone,
                    ),
                    _ProfileFact(
                      icon: Icons.work_outline_rounded,
                      text: profile.occupation,
                    ),
                    _ProfileFact(
                      icon: Icons.location_on_outlined,
                      text: profile.address,
                    ),
                  ],
                ),
              ],
            );
            final editButton = FilledButton.tonalIcon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit profile'),
            );

            if (constraints.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      avatar,
                      const SizedBox(width: 16),
                      Expanded(child: details),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: editButton,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatar,
                const SizedBox(width: 16),
                Expanded(child: details),
                const SizedBox(width: 12),
                editButton,
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProfileFact extends StatelessWidget {
  const _ProfileFact({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 5),
        Flexible(child: Text(text)),
      ],
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
