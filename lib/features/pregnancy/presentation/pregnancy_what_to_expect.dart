import '/localization/dawa_localized_material.dart';

import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/features/profile/data/health_profile_repository.dart';
import '/features/profile/profile_completion_page.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class PregnancyWhatToExpectLoader extends StatefulWidget {
  const PregnancyWhatToExpectLoader({super.key, this.compact = false});

  final bool compact;

  @override
  State<PregnancyWhatToExpectLoader> createState() =>
      _PregnancyWhatToExpectLoaderState();
}

class _PregnancyWhatToExpectLoaderState
    extends State<PregnancyWhatToExpectLoader> {
  final _repository = HealthProfileRepository();
  late Future<HealthProfileSnapshot> _profile;

  @override
  void initState() {
    super.initState();
    HealthProfileRepository.changes.addListener(_reload);
    _profile = _repository.load();
  }

  @override
  void dispose() {
    HealthProfileRepository.changes.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (mounted) setState(() => _profile = _repository.load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HealthProfileSnapshot>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const DawaLoadingSkeleton(
            label: 'Loading pregnancy care',
            lines: 2,
          );
        }
        if (!snapshot.hasData) {
          return DawaCard(child: _PregnancyUnavailable(onRetry: _reload));
        }
        return DawaCard(
          color: DawaColors.warmSurface,
          child: PregnancyWhatToExpectCard(
            profile: snapshot.data!,
            compact: widget.compact,
            onOpenProfile: () =>
                context.pushNamed(ProfileCompletionPage.routeName),
          ),
        );
      },
    );
  }
}

class PregnancyWhatToExpectCard extends StatelessWidget {
  const PregnancyWhatToExpectCard({
    super.key,
    required this.profile,
    required this.onOpenProfile,
    this.compact = false,
  });

  final HealthProfileSnapshot profile;
  final VoidCallback onOpenProfile;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    switch (profile.pregnancyProfileStatus) {
      case PregnancyProfileStatus.pregnantWithData:
        return _PregnantWithData(
          profile: profile,
          compact: compact,
          onOpenProfile: onOpenProfile,
        );
      case PregnancyProfileStatus.pregnantMissingInformation:
        return _PregnancyStateMessage(
          icon: Icons.pregnant_woman_rounded,
          title: 'Pregnancy details need completion',
          description:
              'Your profile says you are pregnant. Add the first day of your last period or your due date to see the right tips.',
          actionLabel: 'Complete pregnancy details',
          onAction: onOpenProfile,
        );
      case PregnancyProfileStatus.notCurrentlyPregnant:
        return _PregnancyStateMessage(
          icon: Icons.health_and_safety_outlined,
          title: 'Pregnancy tips are off',
          description:
              'Your profile says you are not currently pregnant. Cycle tracking and appointment support remain available.',
          actionLabel: 'Review health profile',
          onAction: onOpenProfile,
        );
      case PregnancyProfileStatus.notProvided:
        final keptPrivate = profile.pregnancyStatus == 'prefer_not_to_say';
        return _PregnancyStateMessage(
          icon: keptPrivate
              ? Icons.lock_outline_rounded
              : Icons.assignment_ind_outlined,
          title: keptPrivate
              ? 'Pregnancy status kept private'
              : 'Pregnancy status not provided',
          description: keptPrivate
              ? 'This choice is respected. You can update it at any time in your health profile.'
              : 'Add or change your pregnancy choice to see the right tips.',
          actionLabel: 'Review health profile',
          onAction: onOpenProfile,
        );
    }
  }
}

class _PregnantWithData extends StatelessWidget {
  const _PregnantWithData({
    required this.profile,
    required this.compact,
    required this.onOpenProfile,
  });

  final HealthProfileSnapshot profile;
  final bool compact;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final week = profile.pregnancyWeek;
    final trimester = profile.trimester;
    final dueDate = profile.calculatedDueDate;
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = !compact && constraints.maxWidth >= 560;
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              week == null ? 'Pregnancy timeline' : 'Week $week',
              style: context.dawaTitle.copyWith(color: DawaColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              trimester == null
                  ? 'Dates available in your health profile'
                  : 'Trimester $trimester',
              style: context.dawaCaption,
            ),
          ],
        );
        final guidance = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dueDate == null
                  ? 'Your due date has not been added.'
                  : 'Estimated due date · ${DateFormat('d MMMM y').format(dueDate)}',
              style: context.dawaBody.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Pregnancy dates are estimates. Follow the advice from your health worker.',
              style: context.dawaCaption,
            ),
            const SizedBox(height: 8),
            DawaCompactButton(
              onPressed: onOpenProfile,
              icon: Icons.arrow_forward_rounded,
              label: 'View pregnancy details',
            ),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusHeader(
              icon: Icons.pregnant_woman_rounded,
              title: 'Pregnancy overview',
              subtitle: 'Based on your health profile',
            ),
            const SizedBox(height: 18),
            if (horizontal)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: details),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: guidance),
                ],
              )
            else ...[
              details,
              const SizedBox(height: 16),
              guidance,
            ],
          ],
        );
      },
    );
  }
}

class _PregnancyStateMessage extends StatelessWidget {
  const _PregnancyStateMessage({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusHeader(
          icon: icon,
          title: title,
          subtitle: description,
        ),
        const SizedBox(height: 12),
        DawaCompactButton(
          onPressed: onAction,
          icon: Icons.arrow_forward_rounded,
          label: actionLabel,
        ),
      ],
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DawaIconBadge(icon: icon, color: DawaColors.purple),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.dawaSectionTitle,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: context.dawaCaption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PregnancyUnavailable extends StatelessWidget {
  const _PregnancyUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      children: [
        Icon(Icons.cloud_off_outlined, color: theme.secondaryText),
        const SizedBox(height: 8),
        Text('Pregnancy information is temporarily unavailable',
            style: theme.bodyMedium),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }
}
