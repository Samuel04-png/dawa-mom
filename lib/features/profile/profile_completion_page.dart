import 'dart:async';

import '/localization/dawa_localized_material.dart';
import '/components/period_setup/period_setup_flow.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_interactions.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/features/feedback/dawa_feedback_effects.dart';
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
  bool _savingPregnancy = false;
  _ProfileFeedback? _feedback;
  final _feedbackKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? HealthProfileRepository();
    _profile = _repository.load();
  }

  Future<HealthProfileSnapshot> _refresh() async {
    final future = _repository.load();
    setState(() {
      _profile = future;
    });
    return future;
  }

  Future<void> _editPersonal(HealthProfileSnapshot before) async {
    final result = await context.pushNamed(EditProfileWidget.routeName);
    if (!mounted || result is! HealthProfilePersonalSave) return;
    final savedSnapshot = before.copyWith(
      profile: {...before.profile, ...result.profile},
      mother: {...before.mother, ...result.mother},
    );
    setState(() {
      _profile = Future.value(savedSnapshot);
    });
    HealthProfileSnapshot after = savedSnapshot;
    var refreshUnavailable = false;
    try {
      after = await _repository.load();
      if (mounted) {
        setState(() {
          _profile = Future.value(after);
        });
      }
    } catch (_) {
      refreshUnavailable = true;
    }
    if (!mounted) return;
    _showFeedback(
      before: before,
      after: after,
      title: after.isComplete && !before.isComplete
          ? 'Your profile is ready'
          : 'Your details are saved',
      message: after.isComplete && !before.isComplete
          ? 'Your health profile is ready. DawaMom can now show care and tips that fit you.'
          : refreshUnavailable
              ? 'Your details are saved. We will refresh the rest of your profile when you are connected.'
              : 'Your personal details have been added to your health profile.',
    );
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
      final after = await _refresh();
      if (!mounted || after.periodComplete == data.periodComplete) return;
      _showFeedback(
        before: data,
        after: after,
        title: after.isComplete && !data.isComplete
            ? 'Profile complete'
            : 'Period dates added',
        message: after.isComplete && !data.isComplete
            ? 'Your health profile is ready. You can change any answer when you need to.'
            : 'Your cycle estimates can now use the period date you saved.',
      );
    }
  }

  Future<void> _editPregnancy(HealthProfileSnapshot data) async {
    // The pregnancy RPC correctly rejects users who do not yet have a mother
    // record. Personal details creates that record, so make the prerequisite
    // clear before opening a form that cannot be saved.
    if (!data.hasMaternalProfile) {
      _showPrerequisiteFeedback();
      return;
    }
    final result = await showDialog<_PregnancyResult>(
      context: context,
      builder: (context) => _PregnancyDialog(data: data),
    );
    if (result == null || !mounted) return;
    setState(() => _savingPregnancy = true);
    try {
      await _repository.savePregnancyInformation(
        status: result.status,
        lastMenstrualPeriod: result.lastMenstrualPeriod,
        estimatedDueDate: result.estimatedDueDate,
      );
      if (!mounted) return;
      final savedSnapshot = data.copyWith(
        mother: {...data.mother, 'pregnancy_status': result.status},
        pregnancy: result.status == 'pregnant'
            ? {
                'lnmp': result.lastMenstrualPeriod?.toIso8601String(),
                'estimated_due_date':
                    result.estimatedDueDate?.toIso8601String(),
              }
            : null,
        clearPregnancy: result.status != 'pregnant',
      );
      setState(() {
        _profile = Future.value(savedSnapshot);
      });
      HealthProfileSnapshot after = savedSnapshot;
      var refreshUnavailable = false;
      try {
        after = await _repository.load();
        if (mounted) {
          setState(() {
            _profile = Future.value(after);
          });
        }
      } catch (_) {
        refreshUnavailable = true;
      }
      if (!mounted) return;
      final detailsReady = after.pregnancyWeek != null ||
          after.estimatedDueDate != null ||
          after.lastMenstrualPeriod != null;
      _showFeedback(
        before: data,
        after: after,
        title: after.isComplete && !data.isComplete
            ? 'Profile complete'
            : result.status == 'pregnant'
                ? 'Pregnancy details added'
                : 'Pregnancy choice saved',
        message: after.isComplete && !data.isComplete
            ? 'Your health profile is ready. DawaMom can now show care and tips that fit you.'
            : detailsReady
                ? 'Your current week, trimester, and due-date details are now ready.'
                : refreshUnavailable
                    ? 'Your pregnancy choice is saved. We will refresh the rest of your profile when you are connected.'
                    : 'Your pregnancy choice has been saved. Add dates later if you want week and due-date details.',
      );
    } on HealthProfileException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[HealthProfile] operation=save_pregnancy stage=profile_ui '
        'error_type=${error.runtimeType}',
      );
      debugPrintStack(
        label: '[HealthProfile] save_pregnancy/profile_ui',
        stackTrace: stackTrace,
        maxFrames: 5,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Pregnancy information could not be saved. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingPregnancy = false);
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

  void _showFeedback({
    required HealthProfileSnapshot before,
    required HealthProfileSnapshot after,
    required String title,
    required String message,
  }) {
    if (!mounted) return;
    unawaited(DawaFeedbackEffects.profileStepSaved());
    setState(
      () => _feedback = _ProfileFeedback(
        title: title,
        message: message,
        milestone: after.isComplete && !before.isComplete,
      ),
    );
    // The acknowledgement is part of the page rather than a transient toast,
    // so screen readers can announce it and the user can read it again. Bring
    // it into view when a lower step initiated the save.
    _revealFeedback();
  }

  void _showPrerequisiteFeedback() {
    if (!mounted) return;
    setState(
      () => _feedback = const _ProfileFeedback(
        title: 'Add your details first',
        message:
            'Add your name, date of birth, phone number, and address. Then you can save pregnancy information.',
        milestone: false,
        tone: DawaFeedbackTone.information,
      ),
    );
    _revealFeedback();
  }

  void _revealFeedback() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedbackContext = _feedbackKey.currentContext;
      if (mounted && feedbackContext != null) {
        Scrollable.ensureVisible(
          feedbackContext,
          duration: DawaMotion.resolve(context, DawaMotion.standard),
          curve: Curves.easeOutCubic,
          alignment: .08,
        );
      }
    });
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
              actionLabel: data.personalComplete ? 'Edit' : 'Add',
              onTap: () => _editPersonal(data),
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
              actionLabel: data.contactComplete ? 'Edit' : 'Add',
              onTap: () => _editPersonal(data),
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
              actionLabel: data.pregnancyComplete ? 'Edit' : 'Choose',
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
              actionLabel: data.periodComplete ? 'Edit' : 'Add period',
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
                if (_feedback != null) ...[
                  const SizedBox(height: DawaSpacing.sm),
                  DawaActionFeedback(
                    key: _feedbackKey,
                    title: _feedback!.title,
                    message: _feedback!.message,
                    tone: _feedback!.tone,
                    dismissLabel: 'Close',
                    onDismiss: () => setState(() => _feedback = null),
                  ),
                ],
                if (_savingPregnancy) ...[
                  const SizedBox(height: DawaSpacing.sm),
                  const DawaActionFeedback(
                    title: 'Saving your details',
                    message:
                        'Please wait while we save your pregnancy information.',
                    tone: DawaFeedbackTone.information,
                  ),
                ],
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

class _ProfileFeedback {
  const _ProfileFeedback({
    required this.title,
    required this.message,
    required this.milestone,
    this.tone = DawaFeedbackTone.success,
  });

  final String title;
  final String message;
  final bool milestone;
  final DawaFeedbackTone tone;
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
          DawaTextButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          DawaPrimaryButton(
            label: 'Save',
            icon: Icons.check_rounded,
            fullWidth: false,
            onPressed: () => Navigator.pop(
              context,
              _PregnancyResult(
                status: _status,
                lastMenstrualPeriod: _status == 'pregnant' ? _lnmp : null,
                estimatedDueDate: _status == 'pregnant' ? _dueDate : null,
              ),
            ),
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
