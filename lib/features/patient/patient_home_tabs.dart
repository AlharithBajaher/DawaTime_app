part of 'patient_home.dart';

class _PatientTopBar extends StatelessWidget {
  const _PatientTopBar({
    required this.profile,
    required this.fallbackName,
  });

  final AppUserModel? profile;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return HomeTopActionBar(
          profile: profile,
          fallbackName: fallbackName,
          roleLabel: context.tr(
            ar: 'مساحة المريض الذكية',
            en: 'Patient workspace',
          ),
          accentColors: const [Color(0xFF1E88E5), Color(0xFF54B8F7)],
          trailingIcon: Icons.notifications_active_rounded,
          onMenuPressed: () => Scaffold.of(context).openDrawer(),
        );
      },
    );
  }
}

class _ModernPatientHomeTab extends StatelessWidget {
  const _ModernPatientHomeTab({
    required this.selectedDate,
    required this.timeline,
    required this.onAddMedication,
    required this.onSelectOffset,
    required this.onShiftWeek,
    required this.onMedicationTap,
    required this.onDeleteMedication,
    required this.onTakeDose,
  });

  final DateTime selectedDate;
  final List<_DoseMoment> timeline;
  final VoidCallback onAddMedication;
  final ValueChanged<int> onSelectOffset;
  final ValueChanged<int> onShiftWeek;
  final ValueChanged<_DoseMoment> onMedicationTap;
  final ValueChanged<MedicationModel> onDeleteMedication;
  final ValueChanged<_DoseMoment> onTakeDose;

  @override
  Widget build(BuildContext context) {
    final baseDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final startOfWeek = baseDate.subtract(Duration(days: baseDate.weekday % 7));
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final weekDates = List<DateTime>.generate(
      7,
      (index) => startOfWeek.add(Duration(days: index)),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: DepthCard(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => onShiftWeek(-7),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        _compactWeekLabel(context, startOfWeek),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: AppFontSize.body,
                          fontWeight: FontWeight.w800,
                          color: AppPalette.text,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onShiftWeek(7),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                Row(
                  children: weekDates
                      .map((date) {
                        final normalized = DateTime(
                          date.year,
                          date.month,
                          date.day,
                        );
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _DayTile(
                              date: date,
                              selected: normalized == baseDate,
                              onTap: () => onSelectOffset(
                                normalized.difference(todayDate).inDays,
                              ),
                            ),
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _selectedDateLabel(context, selectedDate),
                  style: const TextStyle(
                    color: AppPalette.patientPrimary,
                    fontSize: AppFontSize.title,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (timeline.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: DepthCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 84,
                    color: Color(0xFFD4DCE8),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.tr(
                      ar: 'رتّب جدول أدويتك الخاص',
                      en: 'Organize your medication schedule',
                    ),
                    style: const TextStyle(
                      fontSize: AppFontSize.sectionTitle,
                      fontWeight: FontWeight.w900,
                      color: AppPalette.text,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.tr(
                      ar: 'اعرض جدول اليوم وأوقات الجرعات بشكل واضح ومضغوط حتى تبقى المتابعة أسهل.',
                      en: 'View today\'s doses in a clear and compact layout so daily follow-up stays easy.',
                    ),
                    style: const TextStyle(
                      color: AppPalette.muted,
                      height: 1.6,
                      fontSize: AppFontSize.body,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: onAddMedication,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      context.tr(ar: 'أضف دواء', en: 'Add medicine'),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: timeline
                  .map(
                    (dose) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _DoseMomentCard(
                        dose: dose,
                        onTap: () => onMedicationTap(dose),
                        onDelete: () => onDeleteMedication(dose.medication),
                        onTake: () => onTakeDose(dose),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
      ],
    );
  }

  String _selectedDateLabel(BuildContext context, DateTime date) {
    final monthLabel = _monthLabel(context, date.month);
    final weekdayLabel = _weekdayLabel(context, date);
    return context.isArabic
        ? '$weekdayLabel، ${date.day} $monthLabel'
        : '$weekdayLabel, $monthLabel ${date.day}';
  }

  String _compactWeekLabel(BuildContext context, DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final monthLabel = _monthLabel(context, endOfWeek.month);
    return context.isArabic
        ? '${startOfWeek.day} - ${endOfWeek.day} $monthLabel'
        : '$monthLabel ${startOfWeek.day} - ${endOfWeek.day}';
  }

  String _monthLabel(BuildContext context, int month) {
    final months = context.isArabic
        ? const [
            'يناير',
            'فبراير',
            'مارس',
            'أبريل',
            'مايو',
            'يونيو',
            'يوليو',
            'أغسطس',
            'سبتمبر',
            'أكتوبر',
            'نوفمبر',
            'ديسمبر',
          ]
        : const [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
          ];
    return months[month - 1];
  }

  String _weekdayLabel(BuildContext context, DateTime date) {
    final labels = context.isArabic
        ? const [
            'الأحد',
            'الاثنين',
            'الثلاثاء',
            'الأربعاء',
            'الخميس',
            'الجمعة',
            'السبت',
          ]
        : const [
            'Sunday',
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
          ];
    return labels[date.weekday % 7];
  }
}

class _ModernPatientMedicinesTab extends StatelessWidget {
  const _ModernPatientMedicinesTab({
    required this.medications,
    required this.onAddMedication,
  });

  final List<MedicationModel> medications;
  final VoidCallback onAddMedication;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        DepthCard(
          child: Column(
            children: [
              const Icon(
                Icons.medication_liquid_rounded,
                size: 88,
                color: Color(0xFFD0D7E4),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.tr(ar: 'إدارة أدويتك', en: 'Manage your medicines'),
                style: const TextStyle(
                  fontSize: AppFontSize.pageTitle,
                  fontWeight: FontWeight.w900,
                  color: AppPalette.text,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.tr(
                  ar: 'كل دواء يظهر في بطاقة مستقلة مع الوقت والجرعة والكمية المتبقية لتصبح المتابعة أسرع.',
                  en: 'Each medicine appears in its own card with time, dosage, and remaining stock for faster follow-up.',
                ),
                style: const TextStyle(
                  color: AppPalette.muted,
                  height: 1.6,
                  fontSize: AppFontSize.body,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: onAddMedication,
                child: Text(context.tr(ar: 'أضف دواء', en: 'Add medicine')),
              ),
            ],
          ),
        ),
        if (medications.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          ...medications.map(
            (medication) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _MedicineInventoryCard(medication: medication),
            ),
          ),
        ],
      ],
    );
  }
}

class _PatientUpdatesTab extends StatelessWidget {
  const _PatientUpdatesTab({
    required this.onLearnMore,
    required this.onOpenReports,
  });

  final VoidCallback onLearnMore;
  final VoidCallback onOpenReports;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        _UpdateCard(
          title: context.tr(ar: 'مرحباً بك في DawaTime!', en: 'Welcome to DawaTime!'),
          description: context.tr(
            ar: 'يساعدك التطبيق على تذكّر مواعيد أدويتك، متابعة التزامك، والوصول إلى إرشادات صحية واضحة.',
            en: 'The app helps you remember medication times, track adherence, and access clear health guidance.',
          ),
          buttonLabel: context.tr(ar: 'تعرّف على المزيد', en: 'Learn more'),
          onPressed: onLearnMore,
        ),
        const SizedBox(height: AppSpacing.md),
        _UpdateCard(
          title: context.tr(
            ar: 'تقارير تناول الأدوية',
            en: 'Medication adherence reports',
          ),
          description: context.tr(
            ar: 'راجع تقريرك اليومي والأسبوعي والشهري بدقة من يوم إضافة الدواء وحتى بعد انتهاء كميته.',
            en: 'Review precise daily, weekly, and monthly reports starting from the day the medicine was added, even after it finishes.',
          ),
          buttonLabel: context.tr(ar: 'فتح التقارير', en: 'Open reports'),
          onPressed: onOpenReports,
        ),
      ],
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({
    required this.title,
    required this.description,
    required this.buttonLabel,
    this.onPressed,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DepthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: AppFontSize.sectionTitle,
              fontWeight: FontWeight.w900,
              color: AppPalette.text,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: const TextStyle(
              color: AppPalette.muted,
              fontSize: AppFontSize.body,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: onPressed,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _PatientMoreTab extends StatelessWidget {
  const _PatientMoreTab({
    required this.onOpenPage,
    required this.medications,
    required this.onEditProfile,
  });

  final Future<void> Function(Widget page) onOpenPage;
  final List<MedicationModel> medications;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final items = <_MoreDestination>[
      _MoreDestination(
        title: context.tr(ar: 'تعديل الملف الشخصي', en: 'Edit profile'),
        description: context.tr(
          ar: 'حدّث بيانات حسابك من صفحة الملف الشخصي.',
          en: 'Update your account details from the profile editor.',
        ),
        icon: Icons.edit_note_rounded,
        onTap: onEditProfile,
      ),
      _MoreDestination(
        title: context.tr(ar: 'التقارير', en: 'Reports'),
        description: context.tr(
          ar: 'عرض دقيق لنسب الالتزام والجرعات المأخوذة والفائتة.',
          en: 'Precise adherence insights for taken, skipped, and missed doses.',
        ),
        icon: Icons.bar_chart_rounded,
        page: _MedicationReportsPage(medications: medications),
      ),
      _MoreDestination(
        title: context.tr(ar: 'دليل التطبيق', en: 'App guide'),
        description: context.tr(
          ar: 'شرح سريع لكيفية استخدام المنصة والتنقل بين أقسامها.',
          en: 'A quick guide to using the platform and navigating its sections.',
        ),
        icon: Icons.menu_book_rounded,
        page: _SimplePage(
          title: context.tr(ar: 'دليل التطبيق', en: 'App guide'),
          description: context.tr(
            ar: 'يمكنك من هنا متابعة الأدوية، قراءة التقارير، وتصفح الأدوية المنشورة من الصيدليات بسهولة.',
            en: 'From here you can follow medicines, open reports, and browse medicines published by pharmacies with ease.',
          ),
          icon: Icons.menu_book_rounded,
        ),
      ),
      _MoreDestination(
        title: context.tr(ar: 'أجهزة تتبع الصحة', en: 'Health trackers'),
        description: context.tr(
          ar: 'مساحة جاهزة لاحقاً لربط الضغط والسكر والنبض.',
          en: 'Prepared for future blood pressure, glucose, and pulse tracking.',
        ),
        icon: Icons.monitor_heart_outlined,
        page: _SimplePage(
          title: context.tr(ar: 'أجهزة تتبع الصحة', en: 'Health trackers'),
          description: context.tr(
            ar: 'صفحة مخصصة لاحقاً لربط قياساتك الصحية بشكل أسهل.',
            en: 'A future page dedicated to linking health measurements more easily.',
          ),
          icon: Icons.monitor_heart_outlined,
        ),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                onTap: () async {
                  if (item.onTap != null) {
                    item.onTap!();
                    return;
                  }
                  final page = item.page;
                  if (page != null) {
                    await onOpenPage(page);
                  }
                },
                child: DepthCard(
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppPalette.patientPrimary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Icon(item.icon, color: AppPalette.patientPrimary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: AppFontSize.bodyLarge,
                                fontWeight: FontWeight.w900,
                                color: AppPalette.text,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              item.description,
                              style: const TextStyle(
                                color: AppPalette.muted,
                                fontSize: AppFontSize.body,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppPalette.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _MoreDestination {
  const _MoreDestination({
    required this.title,
    required this.description,
    required this.icon,
    this.page,
    this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Widget? page;
  final VoidCallback? onTap;
}

class _SimplePage extends StatelessWidget {
  const _SimplePage({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxSheetWidth),
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: DepthCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 72, color: AppPalette.patientPrimary),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: AppFontSize.pageTitle,
                      fontWeight: FontWeight.w900,
                      color: AppPalette.text,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppPalette.muted,
                      fontSize: AppFontSize.body,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MedicationReportsPage extends StatelessWidget {
  const _MedicationReportsPage({required this.medications});

  final List<MedicationModel> medications;

  _AdherenceReport _buildAdherenceReport({required int days}) {
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final windowStartDate = today.subtract(Duration(days: days - 1));

    var scheduled = 0;
    var taken = 0;
    var skipped = 0;
    var missed = 0;
    var pending = 0;

    for (final medication in medications) {
      final doseTimes = medication.sortedDoseTimes;
      if (doseTimes.isEmpty) {
        continue;
      }

      final medicationStartDate = _effectiveMedicationStart(
        windowStartDate,
        medication,
      );
      if (medicationStartDate.isAfter(today)) {
        continue;
      }

      for (
        var day = medicationStartDate;
        !day.isAfter(today);
        day = day.add(const Duration(days: 1))
      ) {
        if (!medication.isScheduledOnDate(day)) {
          continue;
        }

        for (final doseTime in doseTimes) {
          final scheduledAt = DateTime(
            day.year,
            day.month,
            day.day,
            doseTime.hour,
            doseTime.minute,
          );
          if (scheduledAt.isAfter(now)) {
            continue;
          }

          scheduled += 1;
          if (medication.isDoseTaken(scheduledAt)) {
            taken += 1;
          } else if (medication.isDoseSkipped(scheduledAt)) {
            skipped += 1;
          } else if (medication.isDoseMissed(scheduledAt, now: now)) {
            missed += 1;
          } else {
            pending += 1;
          }
        }
      }
    }

    final adherenceBase = taken + skipped + missed;
    final adherenceRate = adherenceBase == 0 ? 0.0 : taken / adherenceBase;

    return _AdherenceReport(
      scheduled: scheduled,
      taken: taken,
      skipped: skipped,
      missed: missed,
      pending: pending,
      adherenceRate: adherenceRate,
    );
  }

  List<_MedicineReportRowData> _buildMedicineRows({required int days}) {
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final windowStartDate = today.subtract(Duration(days: days - 1));
    final rows = <_MedicineReportRowData>[];

    for (final medication in medications) {
      var scheduled = 0;
      var taken = 0;

      final medicationStartDate = _effectiveMedicationStart(
        windowStartDate,
        medication,
      );
      if (medicationStartDate.isAfter(today)) {
        continue;
      }

      for (
        var day = medicationStartDate;
        !day.isAfter(today);
        day = day.add(const Duration(days: 1))
      ) {
        if (!medication.isScheduledOnDate(day)) {
          continue;
        }

        for (final doseTime in medication.sortedDoseTimes) {
          final scheduledAt = DateTime(
            day.year,
            day.month,
            day.day,
            doseTime.hour,
            doseTime.minute,
          );
          if (scheduledAt.isAfter(now)) {
            continue;
          }

          scheduled += 1;
          if (medication.isDoseTaken(scheduledAt)) {
            taken += 1;
          }
        }
      }

      if (scheduled == 0) {
        continue;
      }

      rows.add(
        _MedicineReportRowData(
          name: medication.name,
          taken: taken,
          scheduled: scheduled,
        ),
      );
    }

    rows.sort((a, b) {
      final rateComparison = b.adherenceRate.compareTo(a.adherenceRate);
      if (rateComparison != 0) {
        return rateComparison;
      }
      return b.scheduled.compareTo(a.scheduled);
    });

    return rows;
  }

  DateTime _effectiveMedicationStart(
    DateTime windowStartDate,
    MedicationModel medication,
  ) {
    final createdAt = medication.createdAt?.toDate();
    if (createdAt == null) {
      return windowStartDate;
    }

    final createdDate = DateTime(
      createdAt.year,
      createdAt.month,
      createdAt.day,
    );
    return createdDate.isAfter(windowStartDate)
        ? createdDate
        : windowStartDate;
  }

  @override
  Widget build(BuildContext context) {
    final weekly = _buildAdherenceReport(days: 7);
    final monthly = _buildAdherenceReport(days: 30);
    final quarterly = _buildAdherenceReport(days: 90);
    final medicineRows = _buildMedicineRows(days: 30);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr(ar: 'التقارير', en: 'Reports'))),
      body: Container(
        color: const Color(0xFFF3F6FB),
        child: ListView(
          padding: AppSpacing.pagePadding,
          children: [
            DepthCard(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A8FE5), Color(0xFF62C3FB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderColor: Colors.white.withValues(alpha: 0.20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(
                      ar: 'ملخص الالتزام العلاجي',
                      en: 'Adherence summary',
                    ),
                    style: const TextStyle(
                      fontSize: AppFontSize.pageTitle,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.tr(
                      ar: 'قراءة سريعة لمستوى تناول الجرعات من يوم إضافة الدواء وحتى اليوم.',
                      en: 'A quick view of dose adherence from the day each medicine was added until today.',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppFontSize.body,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _ReportMetric(
                        label: context.tr(ar: 'آخر 7 أيام', en: 'Last 7 days'),
                        value: '${(weekly.adherenceRate * 100).round()}%',
                      ),
                      _ReportMetric(
                        label: context.tr(ar: 'آخر 30 يوماً', en: 'Last 30 days'),
                        value: '${(monthly.adherenceRate * 100).round()}%',
                      ),
                      _ReportMetric(
                        label: context.tr(ar: 'آخر 90 يوماً', en: 'Last 90 days'),
                        value: '${(quarterly.adherenceRate * 100).round()}%',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _AdherenceReportCard(
              title: context.tr(ar: 'تقرير 7 أيام', en: '7-day report'),
              report: weekly,
            ),
            const SizedBox(height: AppSpacing.md),
            _AdherenceReportCard(
              title: context.tr(ar: 'تقرير 30 يوماً', en: '30-day report'),
              report: monthly,
            ),
            const SizedBox(height: AppSpacing.md),
            _AdherenceReportCard(
              title: context.tr(ar: 'تقرير 90 يوماً', en: '90-day report'),
              report: quarterly,
            ),
            const SizedBox(height: AppSpacing.md),
            DepthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(
                      ar: 'أفضل الأدوية التزاماً (آخر 30 يوماً)',
                      en: 'Best adherence by medicine (last 30 days)',
                    ),
                    style: const TextStyle(
                      fontSize: AppFontSize.sectionTitle,
                      fontWeight: FontWeight.w900,
                      color: AppPalette.text,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (medicineRows.isEmpty)
                    Text(
                      context.tr(
                        ar: 'لا توجد بيانات كافية لعرض ترتيب الأدوية بعد.',
                        en: 'There is not enough data yet to rank medicines.',
                      ),
                      style: const TextStyle(
                        color: AppPalette.muted,
                        fontSize: AppFontSize.body,
                      ),
                    )
                  else
                    ...medicineRows.take(6).map(
                      (row) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                row.name,
                                style: const TextStyle(
                                  color: AppPalette.text,
                                  fontSize: AppFontSize.bodyLarge,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              '${(row.adherenceRate * 100).round()}%',
                              style: const TextStyle(
                                color: AppPalette.patientPrimary,
                                fontSize: AppFontSize.body,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
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
}

class _AdherenceReport {
  const _AdherenceReport({
    required this.scheduled,
    required this.taken,
    required this.skipped,
    required this.missed,
    required this.pending,
    required this.adherenceRate,
  });

  final int scheduled;
  final int taken;
  final int skipped;
  final int missed;
  final int pending;
  final double adherenceRate;
}

class _AdherenceReportCard extends StatelessWidget {
  const _AdherenceReportCard({required this.title, required this.report});

  final String title;
  final _AdherenceReport report;

  @override
  Widget build(BuildContext context) {
    final adherencePercent = (report.adherenceRate * 100).round();

    return DepthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: AppFontSize.sectionTitle,
              fontWeight: FontWeight.w900,
              color: AppPalette.text,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr(
              ar: 'نسبة الالتزام: $adherencePercent%',
              en: 'Adherence rate: $adherencePercent%',
            ),
            style: const TextStyle(
              color: AppPalette.patientPrimary,
              fontSize: AppFontSize.bodyLarge,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ReportMiniMetric(
                label: context.tr(ar: 'مجدولة', en: 'Scheduled'),
                value: '${report.scheduled}',
              ),
              _ReportMiniMetric(
                label: context.tr(ar: 'مأخوذة', en: 'Taken'),
                value: '${report.taken}',
              ),
              _ReportMiniMetric(
                label: context.tr(ar: 'متخطاة', en: 'Skipped'),
                value: '${report.skipped}',
              ),
              _ReportMiniMetric(
                label: context.tr(ar: 'فائتة', en: 'Missed'),
                value: '${report.missed}',
              ),
              _ReportMiniMetric(
                label: context.tr(ar: 'بانتظارها', en: 'Pending'),
                value: '${report.pending}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MedicineReportRowData {
  const _MedicineReportRowData({
    required this.name,
    required this.taken,
    required this.scheduled,
  });

  final String name;
  final int taken;
  final int scheduled;

  double get adherenceRate => scheduled == 0 ? 0 : taken / scheduled;
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppFontSize.metric,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: AppFontSize.caption,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportMiniMetric extends StatelessWidget {
  const _ReportMiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppPalette.text,
              fontSize: AppFontSize.title,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: const TextStyle(
              color: AppPalette.muted,
              fontSize: AppFontSize.caption,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineInventoryCard extends StatelessWidget {
  const _MedicineInventoryCard({required this.medication});

  final MedicationModel medication;

  @override
  Widget build(BuildContext context) {
    final stockColor = medication.remainingQuantity <= 2
        ? const Color(0xFFE85D75)
        : AppPalette.patientPrimary;

    return DepthCard(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppPalette.patientPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(
              _patientMedicineIconForForm(medication.form),
              color: AppPalette.patientPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.name,
                  style: const TextStyle(
                    fontSize: AppFontSize.bodyLarge,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${medication.dose} - ${medication.repeatSummary(isArabic: context.isArabic)}',
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: AppFontSize.body,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  medication.displayTime(),
                  style: const TextStyle(
                    color: AppPalette.patientPrimary,
                    fontSize: AppFontSize.caption,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: stockColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              context.tr(
                ar: 'المتبقي: ${medication.remainingQuantity}/${medication.quantity}',
                en: 'Remaining: ${medication.remainingQuantity}/${medication.quantity}',
              ),
              style: TextStyle(
                color: stockColor,
                fontSize: AppFontSize.caption,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoseMomentCard extends StatelessWidget {
  const _DoseMomentCard({
    required this.dose,
    required this.onTap,
    required this.onDelete,
    required this.onTake,
  });

  final _DoseMoment dose;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) {
    final isTaken = dose.medication.isDoseTaken(dose.time);
    final isSkipped = dose.medication.isDoseSkipped(dose.time);
    final isMissed = dose.medication.isDoseMissed(dose.time);
    final takenAt = dose.medication.takenDoseTime(dose.time);
    final skippedAt = dose.medication.skippedDoseTime(dose.time);

    final status = switch ((isTaken, isSkipped, isMissed)) {
      (true, _, _) => _DoseStatusUi(
        color: AppPalette.success,
        icon: Icons.check_circle_rounded,
        background: const Color(0xFFE7FBF1),
        label: context.tr(
          ar: 'تم تناول الدواء عند ${_formatDoseClock(takenAt ?? dose.time)}',
          en: 'Taken at ${_formatDoseClock(takenAt ?? dose.time)}',
        ),
      ),
      (false, true, _) => _DoseStatusUi(
        color: const Color(0xFFF59E0B),
        icon: Icons.skip_next_rounded,
        background: const Color(0xFFFFF4D9),
        label: context.tr(
          ar: 'تم التخطي عند ${_formatDoseClock(skippedAt ?? dose.time)}',
          en: 'Skipped at ${_formatDoseClock(skippedAt ?? dose.time)}',
        ),
      ),
      (false, false, true) => _DoseStatusUi(
        color: const Color(0xFFEF4444),
        icon: Icons.cancel_rounded,
        background: const Color(0xFFFFECEC),
        label: context.tr(
          ar: 'فات وقت الجرعة وتم اعتمادها كفائتة.',
          en: 'Dose time expired and it is now marked as missed.',
        ),
      ),
      _ => _DoseStatusUi(
        color: const Color(0xFF94A3B8),
        icon: Icons.hourglass_bottom_rounded,
        background: const Color(0xFFF1F5F9),
        label: context.tr(
          ar: 'بانتظار الجرعة المجدولة',
          en: 'Waiting for the scheduled dose',
        ),
      ),
    };

    final stockColor = dose.medication.remainingQuantity <= 2
        ? const Color(0xFFE85D75)
        : AppPalette.patientPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppPalette.patientPrimary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: AppPalette.patientPrimary,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                dose.label,
                style: const TextStyle(
                  color: AppPalette.patientPrimary,
                  fontSize: AppFontSize.caption,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DepthCard(
          onTap: onTap,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  color: AppPalette.patientPrimary.withValues(alpha: 0.08),
                ),
                child: Icon(
                  _patientMedicineIconForForm(dose.medication.form),
                  color: AppPalette.patientPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dose.medication.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppFontSize.sectionTitle,
                        fontWeight: FontWeight.w900,
                        color: AppPalette.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dose.medication.dose} - ${dose.medication.repeatSummary(isArabic: context.isArabic)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppPalette.muted,
                        fontSize: AppFontSize.body,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      status.label,
                      style: TextStyle(
                        color: status.color,
                        fontSize: AppFontSize.caption,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: stockColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        context.tr(
                          ar: 'المتبقي: ${dose.medication.remainingQuantity}/${dose.medication.quantity}',
                          en: 'Remaining: ${dose.medication.remainingQuantity}/${dose.medication.quantity}',
                        ),
                        style: TextStyle(
                          color: stockColor,
                          fontSize: AppFontSize.caption,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Column(
                children: [
                  _DoseActionIcon(
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFE85D75),
                    backgroundColor: const Color(0xFFFFEEF2),
                    onTap: onDelete,
                  ),
                  const SizedBox(height: 8),
                  _DoseActionIcon(
                    icon: status.icon,
                    color: status.color,
                    backgroundColor: status.background,
                    onTap: (isTaken || isSkipped) ? null : onTake,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDoseClock(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _DoseStatusUi {
  const _DoseStatusUi({
    required this.color,
    required this.icon,
    required this.background,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final Color background;
  final String label;
}

class _DoseActionIcon extends StatelessWidget {
  const _DoseActionIcon({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weekday = context.isArabic
        ? const ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت']
        : const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppPalette.patientPrimary : const Color(0xFFF6F8FC),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected
                ? AppPalette.patientPrimary
                : const Color(0xFFDCE3EE),
          ),
        ),
        child: Column(
          children: [
            Text(
              weekday[date.weekday % 7],
              style: TextStyle(
                color: selected ? Colors.white70 : AppPalette.muted,
                fontSize: AppFontSize.caption,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: TextStyle(
                color: selected ? Colors.white : AppPalette.text,
                fontSize: AppFontSize.title,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionMenu extends StatelessWidget {
  const _QuickActionMenu({
    required this.expanded,
    required this.onMainTap,
    required this.onAddMedication,
    required this.onAddHealthTrack,
    required this.onAddDose,
  });

  final bool expanded;
  final VoidCallback onMainTap;
  final VoidCallback onAddMedication;
  final VoidCallback onAddHealthTrack;
  final VoidCallback onAddDose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: expanded
              ? Column(
                  key: const ValueKey('expanded-actions'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuickActionButton(
                      icon: Icons.medication_rounded,
                      label: context.tr(
                        ar: 'إضافة دواء',
                        en: 'Add medicine',
                      ),
                      onTap: onAddMedication,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _QuickActionButton(
                      icon: Icons.schedule_rounded,
                      label: context.tr(
                        ar: 'إضافة جرعة',
                        en: 'Add dose',
                      ),
                      onTap: onAddDose,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _QuickActionButton(
                      icon: Icons.monitor_heart_outlined,
                      label: context.tr(
                        ar: 'إضافة متتبع صحة',
                        en: 'Add health tracker',
                      ),
                      onTap: onAddHealthTrack,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                )
              : const SizedBox.shrink(key: ValueKey('collapsed-actions')),
        ),
        FloatingActionButton(
          onPressed: onMainTap,
          backgroundColor: const Color(0xFFFF7D8F),
          child: AnimatedRotation(
            turns: expanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 220),
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      elevation: 10,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppPalette.patientPrimary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: const TextStyle(
                  color: AppPalette.text,
                  fontSize: AppFontSize.body,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _patientMedicineIconForForm(String form) {
  switch (form.toLowerCase()) {
    case 'tablet':
    case 'capsule':
      return Icons.medication_rounded;
    case 'injection':
      return Icons.vaccines_rounded;
    case 'drops':
      return Icons.opacity_rounded;
    case 'cream':
      return Icons.sanitizer_rounded;
    case 'syrup':
    case 'liquid':
      return Icons.local_drink_rounded;
    default:
      return Icons.medication_liquid_rounded;
  }
}
