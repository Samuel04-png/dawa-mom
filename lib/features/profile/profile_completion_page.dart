import '/localization/dawa_localized_material.dart';
import '/components/period_setup/period_setup_flow.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/navbar/edit_profile/edit_profile_widget.dart';
import 'data/health_profile_repository.dart';

class ProfileCompletionPage extends StatefulWidget {
  const ProfileCompletionPage({super.key, this.repository});

  static const routeName = 'ProfileCompletion';
  static const routePath = '/profileCompletion';
  final HealthProfileRepository? repository;

  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  late final HealthProfileRepository _repository;
  late Future<HealthProfileSnapshot> _profile;
  bool _retryingPatientSync = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? HealthProfileRepository();
    _profile = _repository.load();
  }

  Future<void> _refresh() async {
    final future = _repository.load();
    setState(() => _profile = future);
    await future;
  }

  Future<void> _editPersonal() async {
    await context.pushNamed(EditProfileWidget.routeName);
    if (mounted) await _refresh();
  }

  Future<void> _setupPeriod(HealthProfileSnapshot data) async {
    final outcome = await showPeriodSetupFlow(
      context,
      allowSkip: true,
      initialStartDate: data.lastPeriodStart,
      initialCycleLength:
          data.periodSettings?['averageCycleLength'] as int? ?? 28,
      initialPeriodLength: data.periodSettings?['periodLength'] as int? ?? 5,
      initialIsRegular: data.periodSettings?['isRegular'] as bool? ?? true,
    );
    if (outcome != null && outcome != PeriodSetupOutcome.back && mounted) {
      await _refresh();
    }
  }

  Future<void> _editPregnancy(HealthProfileSnapshot data) async {
    final result = await showDialog<_PregnancyResult>(
      context: context,
      builder: (context) => _PregnancyDialog(data: data),
    );
    if (result == null || !mounted) return;
    try {
      await _repository.savePregnancyInformation(
        status: result.status,
        lastMenstrualPeriod: result.lastMenstrualPeriod,
        estimatedDueDate: result.estimatedDueDate,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pregnancy information saved.')),
      );
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pregnancy information could not be saved. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _retryPatientSync() async {
    if (_retryingPatientSync) return;
    setState(() => _retryingPatientSync = true);
    try {
      await _repository.retryPatientSync();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'We are trying the clinic connection again.',
          ),
        ),
      );
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add your personal details, then try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _retryingPatientSync = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<HealthProfileSnapshot>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const DawaPageScaffold(
              maxWidth: 920,
              reserveMobileNavigationSpace: false,
              child: DawaPageSkeleton(
                label: 'Loading your health profile',
                showHero: true,
                cardCount: 3,
              ),
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return DawaPageScaffold(
              maxWidth: 920,
              reserveMobileNavigationSpace: false,
              child: Column(
                children: [
                  DawaAppHeader(
                    title: 'Your health profile',
                    onBack: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(height: DawaSpacing.md),
                  DawaErrorState(
                    title: 'Your profile did not load',
                    message: 'Check your internet, then try again.',
                    onRetry: _refresh,
                  ),
                ],
              ),
            );
          }
          final data = snapshot.data!;
          final cards = [
            _CompletionCard(
              step: 1,
              color: DawaColors.primary,
              icon: Icons.badge_outlined,
              title: 'About you',
              description: data.personalComplete
                  ? 'Your name and date of birth are added.'
                  : 'Add your name and date of birth.',
              status: data.personalComplete
                  ? _CompletionStatus.complete
                  : _CompletionStatus.incomplete,
              actionLabel: data.personalComplete ? 'Check' : 'Add now',
              onTap: _editPersonal,
            ),
            _CompletionCard(
              step: 2,
              color: DawaColors.teal,
              icon: Icons.contact_phone_outlined,
              title: 'How to reach you',
              description: data.contactComplete
                  ? 'Your phone number and address are added.'
                  : 'Add a phone number and address.',
              status: data.contactComplete
                  ? _CompletionStatus.complete
                  : _CompletionStatus.incomplete,
              actionLabel: data.contactComplete ? 'Check' : 'Add now',
              onTap: _editPersonal,
            ),
            _CompletionCard(
              step: 3,
              color: DawaColors.purple,
              icon: Icons.pregnant_woman_rounded,
              title: 'Pregnancy choice',
              description: _pregnancyDescription(data),
              status: data.pregnancyComplete
                  ? _CompletionStatus.complete
                  : _CompletionStatus.incomplete,
              actionLabel: data.pregnancyComplete ? 'Check' : 'Choose now',
              onTap: () => _editPregnancy(data),
            ),
            _CompletionCard(
              step: 4,
              color: DawaColors.pink,
              icon: Icons.water_drop_outlined,
              title: 'Your period dates',
              description: data.periodComplete
                  ? 'Last period: ${DateFormat('d MMM y').format(data.lastPeriodStart!)}'
                  : 'Add your last period to see cycle dates.',
              status: data.periodComplete
                  ? _CompletionStatus.complete
                  : data.periodWasSkipped
                      ? _CompletionStatus.skipped
                      : _CompletionStatus.incomplete,
              actionLabel: data.periodComplete ? 'Update' : 'Add period',
              onTap: () => _setupPeriod(data),
            ),
          ];
          return DawaPageScaffold(
            maxWidth: 920,
            reserveMobileNavigationSpace: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DawaAppHeader(
                  title: 'Your health profile',
                  onBack: () => Navigator.maybePop(context),
                ),
                const SizedBox(height: DawaSpacing.xs),
                DawaIllustratedHeroCard(
                  category: data.isComplete ? 'ALL DONE' : 'MADE FOR YOU',
                  title: data.isComplete
                      ? 'Your profile is ready'
                      : 'Tell us a little about you',
                  subtitle: data.isComplete
                      ? 'DawaMom can now show care and tips that fit you.'
                      : 'This helps DawaMom show the right care and tips.',
                  illustrationPath: data.isComplete
                      ? DawaArtwork.motherGreeting
                      : DawaArtwork.motherLearning,
                  progress: data.completedSections / 4,
                  progressLabel: '${data.completedSections} of 4 steps done',
                  backgroundColor: DawaColors.softBlue,
                  semanticLabel:
                      '${data.completedSections} of 4 profile steps done.',
                ),
                const SizedBox(height: DawaSpacing.md),
                DawaCard(
                  child: Row(
                    children: [
                      const DawaIconBadge(
                        icon: Icons.auto_awesome_rounded,
                        color: DawaColors.greenDark,
                      ),
                      const SizedBox(width: DawaSpacing.sm),
                      Expanded(
                        child: Text(
                          data.isComplete
                              ? 'You can change any answer when you need to.'
                              : 'Finish all four steps for better tips and faster booking.',
                          style: context.dawaBody,
                        ),
                      ),
                    ],
                  ),
                ),
                if (data.patientSyncNeedsAttention) ...[
                  const SizedBox(height: DawaSpacing.sm),
                  DawaCard(
                    child: Row(
                      children: [
                        const DawaIconBadge(
                          icon: Icons.sync_problem_rounded,
                          color: DawaColors.warning,
                        ),
                        const SizedBox(width: DawaSpacing.sm),
                        Expanded(
                          child: Text(
                            'Your answers are saved. We still need to connect them to the clinic.',
                            style: context.dawaBody,
                          ),
                        ),
                        TextButton(
                          onPressed:
                              _retryingPatientSync ? null : _retryPatientSync,
                          child: Text(
                            _retryingPatientSync ? 'Trying...' : 'Try again',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: DawaSpacing.lg),
                const DawaSectionHeader(
                  title: 'Your four steps',
                  subtitle: 'Tap any step to add or change an answer.',
                ),
                const SizedBox(height: DawaSpacing.sm),
                DawaResponsiveGrid(
                  mobileColumns: 1,
                  tabletColumns: 2,
                  desktopColumns: 2,
                  spacing: DawaSpacing.md,
                  runSpacing: DawaSpacing.md,
                  children: cards,
                ),
                const SizedBox(height: DawaSpacing.xl),
                DawaPrimaryButton(
                  label: data.isComplete ? 'Back to home' : 'Close for now',
                  icon: data.isComplete
                      ? Icons.home_rounded
                      : Icons.close_rounded,
                  onPressed: () => Navigator.maybePop(context),
                ),
              ],
            ),
          );
        },
      );

  static String _pregnancyDescription(HealthProfileSnapshot data) {
    switch (data.pregnancyStatus) {
      case 'pregnant':
        return data.estimatedDueDate == null
            ? 'Currently pregnant'
            : 'Baby due around ${DateFormat('d MMM y').format(data.estimatedDueDate!)}.';
      case 'not_pregnant':
        return 'Not currently pregnant';
      case 'prefer_not_to_say':
        return 'You chose not to answer.';
      default:
        return 'Choose the answer that fits you.';
    }
  }
}

enum _CompletionStatus { complete, incomplete, skipped }

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({
    required this.step,
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.actionLabel,
    required this.onTap,
  });

  final int step;
  final Color color;
  final IconData icon;
  final String title;
  final String description;
  final _CompletionStatus status;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (status) {
      _CompletionStatus.complete => DawaColors.greenDark,
      _CompletionStatus.skipped => DawaColors.warning,
      _CompletionStatus.incomplete => DawaColors.muted,
    };
    final statusLabel = switch (status) {
      _CompletionStatus.complete => 'Done',
      _CompletionStatus.skipped => 'Skipped',
      _CompletionStatus.incomplete => 'To do',
    };
    final statusIcon = switch (status) {
      _CompletionStatus.complete => Icons.check_rounded,
      _CompletionStatus.skipped => Icons.fast_forward_rounded,
      _CompletionStatus.incomplete => Icons.circle_outlined,
    };
    return DawaCard(
      onTap: onTap,
      semanticLabel: 'Step $step. $title. $statusLabel. $description',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  DawaIconBadge(icon: icon, color: color, size: 48),
                  Positioned(
                    left: -5,
                    top: -6,
                    child: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        '$step',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: DawaSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: context.dawaSectionTitle.copyWith(fontSize: 16),
                ),
              ),
              DawaStatusPill(
                label: statusLabel,
                icon: statusIcon,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: DawaSpacing.sm),
          Text(
            description,
            style: context.dawaBody.copyWith(color: DawaColors.textSecondary),
          ),
          const SizedBox(height: DawaSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                actionLabel,
                style: context.dawaCaption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.arrow_forward_rounded, color: color, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _PregnancyDialog extends StatefulWidget {
  const _PregnancyDialog({required this.data});

  final HealthProfileSnapshot data;

  @override
  State<_PregnancyDialog> createState() => _PregnancyDialogState();
}

class _PregnancyDialogState extends State<_PregnancyDialog> {
  late String _status;
  DateTime? _lnmp;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _status = widget.data.pregnancyStatus;
    _lnmp = widget.data.lastMenstrualPeriod;
    _dueDate = widget.data.estimatedDueDate;
  }

  Future<void> _pick({required bool dueDate}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate
          ? (_dueDate ?? now.add(const Duration(days: 140)))
          : (_lnmp ?? now),
      firstDate: dueDate ? now : DateTime(now.year - 1),
      lastDate: dueDate ? DateTime(now.year + 2) : now,
      helpText: context.tr(
        dueDate ? 'Choose due date' : 'Choose first day of last period',
      ),
      cancelText: context.tr('Cancel'),
      confirmText: context.tr('Save'),
    );
    if (picked == null) return;
    setState(() {
      dueDate ? _dueDate = picked : _lnmp = picked;
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Pregnancy information'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: InputDecoration(
                    labelText: 'Pregnancy status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'not_provided',
                      child: Text('Not provided'),
                    ),
                    DropdownMenuItem(
                      value: 'pregnant',
                      child: Text('Currently pregnant'),
                    ),
                    DropdownMenuItem(
                      value: 'not_pregnant',
                      child: Text('Not currently pregnant'),
                    ),
                    DropdownMenuItem(
                      value: 'prefer_not_to_say',
                      child: Text('Prefer not to say'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _status = value!),
                ),
                if (_status == 'pregnant') ...[
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('First day of your last period'),
                    subtitle: Text(
                      _lnmp == null
                          ? 'Optional'
                          : DateFormat('d MMMM y').format(_lnmp!),
                    ),
                    onTap: () => _pick(dueDate: false),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_available_outlined),
                    title: const Text('Due date'),
                    subtitle: Text(
                      _dueDate == null
                          ? 'Optional'
                          : DateFormat('d MMMM y').format(_dueDate!),
                    ),
                    onTap: () => _pick(dueDate: true),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              _PregnancyResult(
                status: _status,
                lastMenstrualPeriod: _status == 'pregnant' ? _lnmp : null,
                estimatedDueDate: _status == 'pregnant' ? _dueDate : null,
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      );
}

class _PregnancyResult {
  const _PregnancyResult({
    required this.status,
    required this.lastMenstrualPeriod,
    required this.estimatedDueDate,
  });

  final String status;
  final DateTime? lastMenstrualPeriod;
  final DateTime? estimatedDueDate;
}
