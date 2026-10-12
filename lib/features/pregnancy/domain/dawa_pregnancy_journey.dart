import '/features/profile/data/health_profile_repository.dart';

/// Read-only pregnancy dates and presentation content derived from the
/// persisted Health Profile. This deliberately owns no persistence and is
/// shared by Home and Track so a due-date correction updates both surfaces.
class DawaPregnancyJourney {
  const DawaPregnancyJourney._({
    required this.actualWeek,
    required this.dayOfWeek,
    required this.trimester,
    required this.dueDate,
    required this.daysRemaining,
    required this.progress,
    required this.isPastDue,
  });

  final int actualWeek;
  final int dayOfWeek;
  final int trimester;
  final DateTime dueDate;
  final int daysRemaining;
  final double progress;
  final bool isPastDue;

  static DawaPregnancyJourney? fromProfile(
    HealthProfileSnapshot profile, {
    DateTime? now,
  }) {
    if (profile.pregnancyProfileStatus !=
        PregnancyProfileStatus.pregnantWithData) {
      return null;
    }
    final start = profile.calculatedPregnancyStart;
    final due = profile.calculatedDueDate;
    if (start == null || due == null) return null;

    final today = _dateOnly(now ?? DateTime.now());
    final startDay = _dateOnly(start);
    final dueDay = _dateOnly(due);
    final elapsedDays = today.difference(startDay).inDays;
    if (elapsedDays < 0) return null;

    // Keep the established LMP/EDD dating basis, but bound the visual model:
    // a post-due pregnancy remains a valid journey and never shows a negative
    // countdown or progress beyond its track.
    final week = (elapsedDays ~/ 7).clamp(0, 42);
    final trimester = week <= 13
        ? 1
        : week <= 27
            ? 2
            : 3;
    final remaining = dueDay.difference(today).inDays;
    return DawaPregnancyJourney._(
      actualWeek: week,
      // A gestational day is zero-indexed within the week: 39 elapsed days
      // reads as Week 5, Day 4. This also avoids presenting an inconsistent
      // day beside the date-only countdown.
      dayOfWeek: elapsedDays % 7,
      trimester: trimester,
      dueDate: dueDay,
      daysRemaining: remaining < 0 ? 0 : remaining,
      progress: (elapsedDays / 280).clamp(0, 1),
      isPastDue: remaining < 0,
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

/// One representative visual per supplied milestone. The files are bundled
/// artwork, not clinically validated anatomy or a precise measurement of an
/// individual baby. Weeks between milestones use their nearest prior stage.
class DawaPregnancyDevelopment {
  const DawaPregnancyDevelopment({
    required this.week,
    required this.title,
    required this.summary,
    required this.maternalNote,
    this.assetPath,
  });

  final int week;
  final String title;
  final String summary;
  final String maternalNote;
  final String? assetPath;

  static DawaPregnancyDevelopment forWeek(int value) {
    final week = value.clamp(0, 42);
    if (week <= 3) {
      return const DawaPregnancyDevelopment(
        week: 0,
        title: 'Early pregnancy timeline',
        summary:
            'The first weeks are part of pregnancy dating. Your stage is estimated from your recorded dates.',
        maternalNote:
            'Some mothers notice no changes yet. Contact a health worker if you have concerns.',
      );
    }
    return _milestones.lastWhere((item) => item.week <= week);
  }

  static const _root = 'assets/pregnancy_development_stages/';
  static const _milestones = <DawaPregnancyDevelopment>[
    DawaPregnancyDevelopment(
      week: 4,
      title: 'Early development',
      summary:
          'Early development is underway. This visual is an illustration of a typical stage.',
      maternalNote:
          'Tiredness or nausea can happen at this stage, but every pregnancy is different.',
      assetPath: '${_root}ChatGPT Image Oct 12, 2026, 10_02_52 AM-1.png',
    ),
    DawaPregnancyDevelopment(
      week: 6,
      title: 'Early embryo',
      summary:
          'Early structures are developing. This is a typical stage illustration, not a scan.',
      maternalNote:
          'Rest, fluids, and regular meals can support wellbeing when possible.',
      assetPath: '${_root}ChatGPT Image Oct 12, 2026, 10_02_54 AM-2.png',
    ),
    DawaPregnancyDevelopment(
      week: 8,
      title: 'Developing limbs',
      summary:
          'Early limbs and body structures continue to develop in a typical pregnancy.',
      maternalNote:
          'Some mothers notice changing energy or nausea. Speak to a health worker about worrying symptoms.',
      assetPath: '${_root}ChatGPT Image Oct 12, 2026, 10_02_55 AM-3.png',
    ),
    DawaPregnancyDevelopment(
      week: 12,
      title: 'Growing fetus',
      summary:
          'Your baby continues to grow and develop. This visual represents a typical stage.',
      maternalNote:
          'Antenatal care can help you plan the next steps for your pregnancy.',
      assetPath: '${_root}ChatGPT Image Oct 12, 2026, 10_02_57 AM-4.png',
    ),
    DawaPregnancyDevelopment(
      week: 16,
      title: 'Developing fetus',
      summary:
          'Growth continues through the second trimester. This is illustrative, not a measurement.',
      maternalNote:
          'Some mothers notice changes in energy, appetite, or sleep around this time.',
      assetPath: '${_root}ChatGPT Image Oct 12, 2026, 10_02_58 AM-5.png',
    ),
    DawaPregnancyDevelopment(
      week: 20,
      title: 'Mid-pregnancy growth',
      summary:
          'Your baby is continuing to grow and develop in a typical mid-pregnancy stage.',
      maternalNote:
          'Keep your antenatal visits and ask your health worker about changes that worry you.',
      assetPath: '${_root}ChatGPT Image Oct 12, 2026, 10_03_00 AM-6.png',
    ),
    DawaPregnancyDevelopment(
      week: 24,
      title: 'Growing and developing',
      summary:
          'Important systems continue to mature. This image is a representative stage visual.',
      maternalNote:
          'Some mothers notice changes in sleep or movement. Everyone’s experience can be different.',
      assetPath: '${_root}ChatGPT Image Oct 12, 2026, 10_03_02 AM-7.png',
    ),
    DawaPregnancyDevelopment(
      week: 28,
      title: 'Third trimester begins',
      summary: 'Your baby continues to gain and develop for the weeks ahead.',
      maternalNote:
          'Birth preparation and regular care can help you feel ready for the next stage.',
      assetPath: '${_root}ChatGPT Image Oct 12, 2026, 10_03_03 AM-8.png',
    ),
    DawaPregnancyDevelopment(
      week: 32,
      title: 'Later pregnancy growth',
      summary: 'Your baby is continuing typical later-pregnancy development.',
      maternalNote:
          'Rest when you can and speak to a health worker about new or concerning symptoms.',
      assetPath: '${_root}ChatGPT Image Oct 12, 2026, 10_03_04 AM-9.png',
    ),
    DawaPregnancyDevelopment(
      week: 40,
      title: 'Full-term development',
      summary:
          'Your estimated due date is a guide. Babies arrive on their own timelines.',
      maternalNote:
          'Stay in touch with your health worker about your care plan and any concerns.',
      assetPath: '${_root}ChatGPT Image Oct 12, 2026, 10_03_06 AM-10.png',
    ),
  ];
}
