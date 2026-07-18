import 'package:flutter/material.dart';
import '/components/period_setup/period_setup_flow.dart';
import '/components/responsive/responsive_layout.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/navbar/edit_profile/edit_profile_widget.dart';
import 'data/health_profile_repository.dart';

class ProfileCompletionPage extends StatefulWidget {
  const ProfileCompletionPage({super.key});

  static const routeName = 'ProfileCompletion';
  static const routePath = '/profileCompletion';

  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  final _repository = HealthProfileRepository();
  late Future<HealthProfileSnapshot> _profile;
  bool _retryingPatientSync = false;

  @override
  void initState() {
    super.initState();
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
            'Your profile sync has been queued and will retry safely.',
          ),
        ),
      );
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete your personal details, then try the clinic connection again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _retryingPatientSync = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.primaryBackground,
        foregroundColor: theme.primaryText,
        title: const Text('Complete health profile'),
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
              title: 'Profile could not be loaded',
              description: 'Check your connection and try again.',
              actionLabel: 'Retry',
              onAction: _refresh,
            );
          }
          final data = snapshot.data!;
          return SingleChildScrollView(
            child: ResponsivePageContainer(
              maxWidth: 920,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      border: Border.all(color: theme.alternate),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.isComplete
                              ? 'Your health profile is ready'
                              : 'A few details will improve your experience',
                          style: theme.headlineSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data.dashboardPrompt,
                          style: theme.bodyMedium.copyWith(
                            color: theme.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: data.completedSections / 4,
                            minHeight: 8,
                            backgroundColor:
                                theme.primary.withValues(alpha: 0.1),
                            color:
                                data.isComplete ? theme.success : theme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${data.completedSections} of 4 sections complete',
                          style: theme.bodySmall.copyWith(
                            color: theme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (data.patientSyncNeedsAttention) ...[
                    const SizedBox(height: 14),
                    DawaMomCard(
                      child: Row(
                        children: [
                          Icon(Icons.sync_problem_rounded, color: theme.warning),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your health profile is saved. The clinic connection needs another attempt.',
                              style: theme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: _retryingPatientSync
                                ? null
                                : _retryPatientSync,
                            child: Text(
                              _retryingPatientSync ? 'Queuing...' : 'Retry',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cards = [
                        _CompletionCard(
                          icon: Icons.badge_outlined,
                          title: 'Personal details',
                          description: data.personalComplete
                              ? 'Name and date of birth added'
                              : 'Add your name and date of birth',
                          status: data.personalComplete
                              ? _CompletionStatus.complete
                              : _CompletionStatus.incomplete,
                          actionLabel:
                              data.personalComplete ? 'Review' : 'Add details',
                          onTap: _editPersonal,
                        ),
                        _CompletionCard(
                          icon: Icons.contact_phone_outlined,
                          title: 'Contact details',
                          description: data.contactComplete
                              ? 'Email, phone number and address added'
                              : 'Add a phone number and address',
                          status: data.contactComplete
                              ? _CompletionStatus.complete
                              : _CompletionStatus.incomplete,
                          actionLabel:
                              data.contactComplete ? 'Review' : 'Add details',
                          onTap: _editPersonal,
                        ),
                        _CompletionCard(
                          icon: Icons.pregnant_woman_rounded,
                          title: 'Pregnancy information',
                          description: _pregnancyDescription(data),
                          status: data.pregnancyComplete
                              ? _CompletionStatus.complete
                              : _CompletionStatus.incomplete,
                          actionLabel: data.pregnancyComplete
                              ? 'Review'
                              : 'Add information',
                          onTap: () => _editPregnancy(data),
                        ),
                        _CompletionCard(
                          icon: Icons.water_drop_outlined,
                          title: 'Period Tracker',
                          description: data.periodComplete
                              ? 'Latest period: ${DateFormat('d MMM y').format(data.lastPeriodStart!)}'
                              : 'Set up tracking to receive cycle estimates',
                          status: data.periodComplete
                              ? _CompletionStatus.complete
                              : data.periodWasSkipped
                                  ? _CompletionStatus.skipped
                                  : _CompletionStatus.incomplete,
                          actionLabel:
                              data.periodComplete ? 'Update' : 'Set up tracker',
                          onTap: () => _setupPeriod(data),
                        ),
                      ];
                      if (constraints.maxWidth >= 700) {
                        return GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.8,
                          children: cards,
                        );
                      }
                      return Column(
                        children: cards
                            .map(
                              (card) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: card,
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: () => Navigator.maybePop(context),
                    icon: Icon(
                      data.isComplete
                          ? Icons.check_circle_outline_rounded
                          : Icons.save_outlined,
                    ),
                    label: Text(
                      data.isComplete
                          ? 'Return to dashboard'
                          : 'Save and close',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.primary,
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _pregnancyDescription(HealthProfileSnapshot data) {
    switch (data.pregnancyStatus) {
      case 'pregnant':
        return data.estimatedDueDate == null
            ? 'Currently pregnant'
            : 'Estimated due date: ${DateFormat('d MMM y').format(data.estimatedDueDate!)}';
      case 'not_pregnant':
        return 'Not currently pregnant';
      case 'prefer_not_to_say':
        return 'You chose not to provide this';
      default:
        return 'Not provided';
    }
  }
}

enum _CompletionStatus { complete, incomplete, skipped }

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final _CompletionStatus status;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final statusColor = switch (status) {
      _CompletionStatus.complete => theme.success,
      _CompletionStatus.skipped => theme.warning,
      _CompletionStatus.incomplete => theme.secondaryText,
    };
    final statusLabel = switch (status) {
      _CompletionStatus.complete => 'Complete',
      _CompletionStatus.skipped => 'Skipped',
      _CompletionStatus.incomplete => 'Incomplete',
    };
    return DawaMomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.primary),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  statusLabel,
                  style: theme.bodySmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.titleSmall.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.bodySmall.copyWith(color: theme.secondaryText),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onTap,
            child: Text(actionLabel),
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
                  decoration: const InputDecoration(
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
                    title: const Text('Last menstrual period'),
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
                    title: const Text('Estimated due date'),
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
