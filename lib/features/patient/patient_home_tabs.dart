part of 'patient_home.dart';

class _PatientTopBar extends StatelessWidget {
  const _PatientTopBar({required this.profile, required this.fallbackName});

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
          accentColors: const [AppPalette.patientPrimary, AppPalette.patientAccent],
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
                    fontWeight: FontWeight.w800,
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
                    fontWeight: FontWeight.w800,
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
                    label: Text(context.tr(ar: 'أضف دواء', en: 'Add medicine')),
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
                  fontWeight: FontWeight.w800,
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
        const _UpdatesHeroPanel(),
        const SizedBox(height: AppSpacing.md),
        _UpdateCard(
          icon: Icons.auto_awesome_rounded,
          accent: AppPalette.patientPrimary,
          title: context.tr(
            ar: 'مرحباً بك في DawaTime!',
            en: 'Welcome to DawaTime!',
          ),
          description: context.tr(
            ar: 'يساعدك التطبيق على تذكّر مواعيد أدويتك، متابعة التزامك، والوصول إلى إرشادات صحية واضحة.',
            en: 'The app helps you remember medication times, track adherence, and access clear health guidance.',
          ),
          buttonLabel: context.tr(ar: 'تعرّف على المزيد', en: 'Learn more'),
          onPressed: onLearnMore,
        ),
        const SizedBox(height: AppSpacing.md),
        _UpdateCard(
          icon: Icons.bar_chart_rounded,
          accent: const Color(0xFF2A8FE5),
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
        const SizedBox(height: AppSpacing.md),
        _UpdateCard(
          icon: Icons.notifications_active_rounded,
          accent: const Color(0xFF0F766E),
          title: context.tr(
            ar: 'إشعارات جرعات دقيقة',
            en: 'Precise dose notifications',
          ),
          description: context.tr(
            ar: 'تم ضبط تنبيهات الجرعات بقنوات مستقلة وأزرار تناول وتخطي وتأكيد محلي عند ضعف الاتصال.',
            en: 'Dose reminders use dedicated channels with taken, skip, and local confirmation support during weak connectivity.',
          ),
          buttonLabel: context.tr(ar: 'جاهزة', en: 'Ready'),
        ),
        const SizedBox(height: AppSpacing.md),
        _UpdateCard(
          icon: Icons.inventory_2_rounded,
          accent: const Color(0xFFE85D75),
          title: context.tr(
            ar: 'تنبيهات الكمية منفصلة',
            en: 'Separate stock alerts',
          ),
          description: context.tr(
            ar: 'تنبيهات نفاد الكمية تعمل بصوت وقناة مختلفة عن الجرعات حتى تعرف سبب التنبيه مباشرة.',
            en: 'Low-stock alerts now use a separate sound and channel from dose reminders, making the alert purpose clear.',
          ),
          buttonLabel: context.tr(ar: 'مفعّلة', en: 'Enabled'),
        ),
        const SizedBox(height: AppSpacing.md),
        _UpdateCard(
          icon: Icons.cloud_sync_rounded,
          accent: const Color(0xFF6D7DF2),
          title: context.tr(
            ar: 'مزامنة عند عودة الإنترنت',
            en: 'Sync when internet returns',
          ),
          description: context.tr(
            ar: 'عند الضغط على تناول أو تخطي من الإشعار يتم حفظ الإجراء محلياً ثم مزامنته تلقائياً عند توفر الاتصال.',
            en: 'Taken and skipped actions from notifications are saved locally and sync automatically when connectivity returns.',
          ),
          buttonLabel: context.tr(ar: 'تعمل تلقائياً', en: 'Automatic'),
        ),
      ],
    );
  }
}

class _UpdatesHeroPanel extends StatelessWidget {
  const _UpdatesHeroPanel();

  @override
  Widget build(BuildContext context) {
    return DepthCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF153E75), Color(0xFF2A8FE5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: Colors.white.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.health_and_safety_rounded,
            color: Colors.white,
            size: 38,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr(ar: 'مركز تحديثات المريض', en: 'Patient update center'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppFontSize.pageTitle,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr(
              ar: 'كل ما يخص الجرعات والتنبيهات والتقارير وحماية البيانات في مساحة واحدة واضحة.',
              en: 'Dose actions, notifications, reports, and data protection are gathered in one clear workspace.',
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppFontSize.body,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.description,
    required this.buttonLabel,
    this.onPressed,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DepthCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppFontSize.sectionTitle,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: AppFontSize.body,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FilledButton.tonal(
                    onPressed: onPressed,
                    child: Text(buttonLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientMoreTab extends StatelessWidget {
  const _PatientMoreTab({
    required this.onOpenPage,
    required this.medicationHistory,
    required this.onEditProfile,
  });

  final Future<void> Function(Widget page) onOpenPage;
  final List<MedicationModel> medicationHistory;
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
        page: _MedicationReportsLivePage(
          fallbackMedications: medicationHistory,
        ),
      ),
      _MoreDestination(
        title: context.tr(ar: 'النسخ الاحتياطي', en: 'Backup & restore'),
        description: context.tr(
          ar: 'احفظ بياناتك في السحابة أو على جهازك واستعدها عند الحاجة.',
          en: 'Backup your data to the cloud or locally and restore anytime.',
        ),
        icon: Icons.backup_rounded,
        page: const BackupScreen(),
      ),
      _MoreDestination(
        title: context.tr(ar: 'دليل التطبيق', en: 'App guide'),
        description: context.tr(
          ar: 'خطوات واضحة لإدارة الأدوية، قراءة التقارير، والاستفادة من السوق الدوائي.',
          en: 'Clear steps for managing medicines, reading reports, and using the medicine marketplace.',
        ),
        icon: Icons.menu_book_rounded,
        page: _PatientKnowledgePage.appGuide(context),
      ),
      _MoreDestination(
        title: context.tr(ar: 'مركز الإشعارات', en: 'Notification center'),
        description: context.tr(
          ar: 'شرح عملي لطريقة عمل إشعارات الجرعات والكمية والمزامنة عند عودة الاتصال.',
          en: 'A practical guide to dose alerts, stock alerts, and sync after reconnecting.',
        ),
        icon: Icons.notifications_active_rounded,
        page: _PatientKnowledgePage.notifications(context),
      ),
      _MoreDestination(
        title: context.tr(ar: 'المؤشرات الصحية', en: 'Health insights'),
        description: context.tr(
          ar: 'لوحة إرشادية خفيفة تربط الالتزام بالجرعات مع عادات يومية مفيدة.',
          en: 'A lightweight guidance board connecting dose adherence with helpful daily habits.',
        ),
        icon: Icons.monitor_heart_rounded,
        page: _PatientKnowledgePage.healthInsights(context),
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
                          color: AppPalette.patientPrimary.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Icon(
                          item.icon,
                          color: AppPalette.patientPrimary,
                        ),
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
                                fontWeight: FontWeight.w800,
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

class _PatientKnowledgePage extends StatelessWidget {
  const _PatientKnowledgePage({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.sections,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final List<_KnowledgeSection> sections;

  static _PatientKnowledgePage appGuide(BuildContext context) {
    return _PatientKnowledgePage(
      title: context.tr(ar: 'دليل التطبيق', en: 'App guide'),
      description: context.tr(
        ar: 'مسار سريع يوضح كيف تستخدم DawaTime بثقة من إضافة الدواء حتى قراءة التقرير.',
        en: 'A quick path for using DawaTime confidently from adding medicine to reading reports.',
      ),
      icon: Icons.menu_book_rounded,
      accent: AppPalette.patientPrimary,
      sections: [
        _KnowledgeSection(
          icon: Icons.add_circle_outline_rounded,
          title: context.tr(ar: 'إضافة الدواء', en: 'Add medicine'),
          body: context.tr(
            ar: 'أدخل اسم الدواء، شكله، الكمية، وعدد الجرعات. بعد الحفظ يتم تجهيز جدول الجرعات تلقائياً.',
            en: 'Enter medicine name, form, quantity, and dose count. After saving, the dose schedule is prepared automatically.',
          ),
        ),
        _KnowledgeSection(
          icon: Icons.touch_app_rounded,
          title: context.tr(ar: 'تنفيذ الجرعة', en: 'Handle a dose'),
          body: context.tr(
            ar: 'من بطاقة الجرعة يمكنك تسجيل التناول أو التخطي أو التأجيل، وتنعكس النتيجة مباشرة في التقارير.',
            en: 'From the dose card, mark taken, skipped, or snoozed, and the result appears directly in reports.',
          ),
        ),
        _KnowledgeSection(
          icon: Icons.storefront_rounded,
          title: context.tr(ar: 'السوق الدوائي', en: 'Medicine marketplace'),
          body: context.tr(
            ar: 'تصفح أدوية الصيدليات، راجع السعر والتوفر والتقييمات، ثم قيّم الصيدلية بعد تجربتك.',
            en: 'Browse pharmacy medicines, review price, availability, and ratings, then rate the pharmacy after your experience.',
          ),
        ),
      ],
    );
  }

  static _PatientKnowledgePage notifications(BuildContext context) {
    return _PatientKnowledgePage(
      title: context.tr(ar: 'مركز الإشعارات', en: 'Notification center'),
      description: context.tr(
        ar: 'تفاصيل واضحة لما يحدث خلف تنبيهات الجرعات وتنبيهات الكمية.',
        en: 'A clear explanation of what happens behind dose and stock alerts.',
      ),
      icon: Icons.notifications_active_rounded,
      accent: const Color(0xFF0F766E),
      sections: [
        _KnowledgeSection(
          icon: Icons.alarm_rounded,
          title: context.tr(ar: 'إشعار الجرعة', en: 'Dose reminder'),
          body: context.tr(
            ar: 'يظهر في وقت الجرعة مع أزرار تناول وتخطي وتأجيل، ويستخدم قناة مخصصة للجرعات فقط.',
            en: 'Appears at dose time with taken, skip, and snooze actions, using a dose-only channel.',
          ),
        ),
        _KnowledgeSection(
          icon: Icons.inventory_2_rounded,
          title: context.tr(ar: 'إشعار الكمية', en: 'Stock alert'),
          body: context.tr(
            ar: 'يتم حسابه من الكمية المتبقية وجدول الجرعات، ويظهر قبل النفاد بقناة وصوت منفصلين.',
            en: 'Calculated from remaining stock and schedule, appearing before depletion through a separate channel and sound.',
          ),
        ),
        _KnowledgeSection(
          icon: Icons.cloud_done_rounded,
          title: context.tr(ar: 'المزامنة', en: 'Sync'),
          body: context.tr(
            ar: 'إذا ضعف الاتصال، يتم حفظ إجراء الجرعة محلياً ثم مزامنته تلقائياً عند عودة الإنترنت.',
            en: 'If connectivity is weak, dose actions are saved locally and synced automatically when internet returns.',
          ),
        ),
      ],
    );
  }

  static _PatientKnowledgePage healthInsights(BuildContext context) {
    return _PatientKnowledgePage(
      title: context.tr(ar: 'المؤشرات الصحية', en: 'Health insights'),
      description: context.tr(
        ar: 'إرشادات يومية مختصرة تساعدك على ربط الالتزام بالجرعات بروتين صحي أسهل.',
        en: 'Short daily guidance that connects dose adherence with a healthier routine.',
      ),
      icon: Icons.monitor_heart_outlined,
      accent: const Color(0xFFE85D75),
      sections: [
        _KnowledgeSection(
          icon: Icons.water_drop_outlined,
          title: context.tr(ar: 'الترطيب', en: 'Hydration'),
          body: context.tr(
            ar: 'اجعل شرب الماء عادة ملازمة لبعض الجرعات عندما يسمح الطبيب بذلك.',
            en: 'Pair water intake with some doses when your clinician says it is appropriate.',
          ),
        ),
        _KnowledgeSection(
          icon: Icons.restaurant_menu_rounded,
          title: context.tr(ar: 'الغذاء والدواء', en: 'Food and medicine'),
          body: context.tr(
            ar: 'استخدم ملاحظات الجرعة لتتذكر إن كان الدواء يؤخذ قبل الطعام أو بعده.',
            en: 'Use dose notes to remember whether medicine should be taken before or after meals.',
          ),
        ),
        _KnowledgeSection(
          icon: Icons.bedtime_rounded,
          title: context.tr(ar: 'روتين ثابت', en: 'Stable routine'),
          body: context.tr(
            ar: 'ثبات وقت النوم والاستيقاظ يجعل تنبيهات الجرعات أكثر قابلية للالتزام.',
            en: 'Stable sleep and wake times make dose reminders easier to follow.',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Container(
        color: AppPalette.canvas,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.maxContentWidth,
            ),
            child: ListView(
              padding: AppSpacing.pagePadding,
              children: [
                DepthCard(
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.68)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderColor: Colors.white.withValues(alpha: 0.18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 46, color: Colors.white),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: AppFontSize.pageTitle,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppFontSize.body,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _KnowledgeSectionTile(
                      section: section,
                      accent: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KnowledgeSection {
  const _KnowledgeSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _KnowledgeSectionTile extends StatelessWidget {
  const _KnowledgeSectionTile({required this.section, required this.accent});

  final _KnowledgeSection section;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DepthCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(section.icon, color: accent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: const TextStyle(
                    color: AppPalette.text,
                    fontSize: AppFontSize.bodyLarge,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  section.body,
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: AppFontSize.body,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationReportsLivePage extends StatelessWidget {
  const _MedicationReportsLivePage({required this.fallbackMedications});

  final List<MedicationModel> fallbackMedications;
  static final MedicationService _medicationService = MedicationService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MedicationModel>>(
      stream: _medicationService.getUserMedicationReports(),
      builder: (context, snapshot) {
        final reportMedications = snapshot.data ?? const <MedicationModel>[];
        return _MedicationReportsPage(
          medications: reportMedications.isNotEmpty
              ? reportMedications
              : fallbackMedications,
        );
      },
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

      final medEndDate = _effectiveMedicationEnd(medication);
      final lastDate = medEndDate != null && medEndDate.isBefore(today)
          ? medEndDate
          : today;
      if (medicationStartDate.isAfter(lastDate)) {
        continue;
      }

      for (
        var day = medicationStartDate;
        !day.isAfter(lastDate);
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
      var skipped = 0;
      var missed = 0;

      final medicationStartDate = _effectiveMedicationStart(
        windowStartDate,
        medication,
      );
      if (medicationStartDate.isAfter(today)) {
        continue;
      }

      final medEndDate = _effectiveMedicationEnd(medication);
      final lastDate = medEndDate != null && medEndDate.isBefore(today)
          ? medEndDate
          : today;
      if (medicationStartDate.isAfter(lastDate)) {
        continue;
      }

      for (
        var day = medicationStartDate;
        !day.isAfter(lastDate);
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
          } else if (medication.isDoseSkipped(scheduledAt)) {
            skipped += 1;
          } else if (medication.isDoseMissed(scheduledAt, now: now)) {
            missed += 1;
          }
        }
      }

      if (scheduled == 0) {
        continue;
      }

      rows.add(
        _MedicineReportRowData(
          medication: medication,
          name: medication.name,
          taken: taken,
          skipped: skipped,
          missed: missed,
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
    return createdDate.isAfter(windowStartDate) ? createdDate : windowStartDate;
  }

  DateTime? _effectiveMedicationEnd(MedicationModel medication) {
    if (!medication.isArchived) {
      return null;
    }
    final archived = medication.archivedAt?.toDate();
    if (archived == null) {
      return null;
    }
    return DateTime(archived.year, archived.month, archived.day);
  }

  Future<void> _openMonthCalendar(
    BuildContext context,
    MedicationModel medication,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MedicationMonthCalendarSheet(medication: medication),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekly = _buildAdherenceReport(days: 7);
    final monthly = _buildAdherenceReport(days: 30);
    final quarterly = _buildAdherenceReport(days: 90);
    final medicineRows = _buildMedicineRows(days: 30);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(ar: 'التقارير', en: 'Reports')),
      ),
      body: Container(
        color: AppPalette.canvas,
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
                      fontWeight: FontWeight.w800,
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
                        label: context.tr(
                          ar: 'آخر 30 يوماً',
                          en: 'Last 30 days',
                        ),
                        value: '${(monthly.adherenceRate * 100).round()}%',
                      ),
                      _ReportMetric(
                        label: context.tr(
                          ar: 'آخر 90 يوماً',
                          en: 'Last 90 days',
                        ),
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
                      fontWeight: FontWeight.w800,
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
                    ...medicineRows
                        .take(6)
                        .map(
                          (row) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6FAFF),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                                border: Border.all(
                                  color: const Color(0xFFDCE7F8),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
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
                                  const SizedBox(height: AppSpacing.xs),
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _openMonthCalendar(
                                        context,
                                        row.medication,
                                      ),
                                      icon: const Icon(
                                        Icons.calendar_month_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        context.tr(
                                          ar: 'تقويم الشهر',
                                          en: 'Month calendar',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                    fontWeight: FontWeight.w800,
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
          const SizedBox(height: AppSpacing.sm),
          _AdherenceBar(
            taken: report.taken,
            skipped: report.skipped,
            missed: report.missed,
          ),
          const SizedBox(height: AppSpacing.xs),
          _AdherenceLegend(),
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
          const SizedBox(height: AppSpacing.md),
          _AdherenceInterpretation(
            rate: report.adherenceRate,
            missed: report.missed,
            totalScheduled: report.scheduled,
          ),
        ],
      ),
    );
  }
}

class _MedicineReportRowData {
  const _MedicineReportRowData({
    required this.medication,
    required this.name,
    required this.taken,
    required this.scheduled,
    this.skipped = 0,
    this.missed = 0,
  });

  final MedicationModel medication;
  final String name;
  final int taken;
  final int scheduled;
  final int skipped;
  final int missed;

  double get adherenceRate => scheduled == 0 ? 0 : taken / scheduled;
}

class _AdherenceBar extends StatelessWidget {
  const _AdherenceBar({required this.taken, required this.skipped, required this.missed});

  final int taken;
  final int skipped;
  final int missed;

  @override
  Widget build(BuildContext context) {
    final total = taken + skipped + missed;
    if (total == 0) {
      return Container(
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFFE8ECF2),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        alignment: Alignment.center,
        child: Text(
          context.tr(ar: 'لا توجد بيانات', en: 'No data'),
          style: const TextStyle(
            color: Color(0xFF9AA6B8),
            fontSize: AppFontSize.caption,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final takenFraction = taken / total;
    final skippedFraction = skipped / total;
    final missedFraction = missed / total;

    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF2),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          if (taken > 0)
            Expanded(
              flex: (takenFraction * 100).round().clamp(1, 100),
              child: Container(
                color: AppPalette.taken,
                alignment: Alignment.center,
                child: takenFraction > 0.12
                    ? Text(
                        '${(takenFraction * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppFontSize.caption,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
            ),
          if (skipped > 0)
            Expanded(
              flex: (skippedFraction * 100).round().clamp(1, 100),
              child: Container(
                color: AppPalette.skipped,
                alignment: Alignment.center,
                child: skippedFraction > 0.12
                    ? Text(
                        '${(skippedFraction * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppFontSize.caption,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
            ),
          if (missed > 0)
            Expanded(
              flex: (missedFraction * 100).round().clamp(1, 100),
              child: Container(
                color: AppPalette.missed,
                alignment: Alignment.center,
                child: missedFraction > 0.12
                    ? Text(
                        '${(missedFraction * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppFontSize.caption,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _AdherenceLegend extends StatelessWidget {
  const _AdherenceLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(AppPalette.taken, context.tr(ar: 'مأخوذة', en: 'Taken')),
        const SizedBox(width: AppSpacing.sm),
        _legendDot(AppPalette.skipped, context.tr(ar: 'متخطاة', en: 'Skipped')),
        const SizedBox(width: AppSpacing.sm),
        _legendDot(AppPalette.missed, context.tr(ar: 'فائتة', en: 'Missed')),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppPalette.muted,
            fontSize: AppFontSize.caption,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AdherenceInterpretation extends StatelessWidget {
  const _AdherenceInterpretation({required this.rate, required this.missed, required this.totalScheduled});

  final double rate;
  final int missed;
  final int totalScheduled;

  @override
  Widget build(BuildContext context) {
    final percent = (rate * 100).round();
    String message;
    IconData icon;

    if (totalScheduled == 0) {
      message = context.tr(
        ar: 'لم تبدأ بعد في تناول الجرعات المقررة. ابدأ بمتابعة جدول أدويتك.',
        en: 'You have not started taking any scheduled doses yet. Start tracking your medication schedule.',
      );
      icon = Icons.info_outline_rounded;
    } else if (percent >= 90) {
      message = context.tr(
        ar: 'التزام ممتاز! حافظ على هذا المستوى للحصول على أفضل نتائج علاجية.',
        en: 'Excellent adherence! Keep up this level for the best treatment outcomes.',
      );
      icon = Icons.emoji_events_rounded;
    } else if (percent >= 75) {
      message = context.tr(
        ar: 'التزام جيد. حاول تحسين الالتزام بتناول الجرعات في مواعيدها.',
        en: 'Good adherence. Try to improve by taking doses on time.',
      );
      icon = Icons.thumb_up_rounded;
    } else if (percent >= 50) {
      message = context.tr(
        ar: 'التزام متوسط. فاتتك $missed جرعة. حاول ضبط منبهات الأدوية.',
        en: 'Moderate adherence. You missed $missed doses. Try setting medication alarms.',
      );
      icon = Icons.trending_up_rounded;
    } else {
      message = context.tr(
        ar: 'التزام منخفض. فاتتك $missed جرعة. استشر طبيبك لضبط الجدول العلاجي.',
        en: 'Low adherence. You missed $missed doses. Consult your doctor to adjust the treatment plan.',
      );
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: percent >= 75
            ? const Color(0xFFE8F8F0)
            : percent >= 50
                ? const Color(0xFFFFF7E8)
                : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppPalette.text),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppPalette.text,
                fontSize: AppFontSize.caption,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _MedicationDayState { none, upcoming, taken, notTaken }

class _MedicationMonthCalendarSheet extends StatefulWidget {
  const _MedicationMonthCalendarSheet({required this.medication});

  final MedicationModel medication;

  @override
  State<_MedicationMonthCalendarSheet> createState() =>
      _MedicationMonthCalendarSheetState();
}

class _MedicationMonthCalendarSheetState
    extends State<_MedicationMonthCalendarSheet> {
  int _monthOffset = 0;

  DateTime get _displayMonth {
    final now = DateTime.now().toLocal();
    return DateTime(now.year, now.month + _monthOffset, 1);
  }

  String _monthLabel(BuildContext context, DateTime month) {
    const arMonths = [
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
    ];
    const enMonths = [
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
    final monthName = context.isArabic
        ? arMonths[month.month - 1]
        : enMonths[month.month - 1];
    return '$monthName ${month.year}';
  }

  _MedicationDayState _dayState(DateTime day) {
    if (!widget.medication.isScheduledOnDate(day)) {
      return _MedicationDayState.none;
    }

    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    if (day.isAfter(today)) {
      return _MedicationDayState.upcoming;
    }

    var dueCount = 0;
    var takenCount = 0;
    final doseTimes = widget.medication.sortedDoseTimes;
    for (final dose in doseTimes) {
      final scheduledAt = DateTime(
        day.year,
        day.month,
        day.day,
        dose.hour,
        dose.minute,
      );
      if (day == today && scheduledAt.isAfter(now)) {
        continue;
      }
      dueCount += 1;
      if (widget.medication.isDoseTaken(scheduledAt)) {
        takenCount += 1;
      }
    }

    if (dueCount == 0) {
      return _MedicationDayState.upcoming;
    }
    return takenCount >= dueCount
        ? _MedicationDayState.taken
        : _MedicationDayState.notTaken;
  }

  Widget _statusIconForState(_MedicationDayState state) {
    switch (state) {
      case _MedicationDayState.taken:
        return const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF1FA65A),
          size: 14,
        );
      case _MedicationDayState.notTaken:
        return const Icon(
          Icons.cancel_rounded,
          color: Color(0xFFE24C4B),
          size: 14,
        );
      case _MedicationDayState.upcoming:
        return const Icon(
          Icons.remove_circle_outline_rounded,
          color: Color(0xFFB0B9C6),
          size: 14,
        );
      case _MedicationDayState.none:
        return const SizedBox.shrink();
    }
  }

  Color _backgroundForState(_MedicationDayState state) {
    switch (state) {
      case _MedicationDayState.taken:
        return const Color(0xFFE9F9EF);
      case _MedicationDayState.notTaken:
        return const Color(0xFFFFF0F0);
      case _MedicationDayState.upcoming:
        return const Color(0xFFF7F9FC);
      case _MedicationDayState.none:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final month = _displayMonth;
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday % 7;
    final totalCells = leadingBlanks + daysInMonth;
    final trailingBlanks = (7 - (totalCells % 7)) % 7;
    final totalGrid = totalCells + trailingBlanks;

    final weekLabels = context.isArabic
        ? const ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س']
        : const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxSheetWidth),
          child: DepthCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _monthOffset -= 1),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        _monthLabel(context, month),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: AppFontSize.sectionTitle,
                          fontWeight: FontWeight.w800,
                          color: AppPalette.text,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _monthOffset += 1),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.medication.name,
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: AppFontSize.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: weekLabels
                      .map(
                        (label) => Expanded(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppPalette.patientPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: AppFontSize.caption,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: AppSpacing.xs),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalGrid,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, index) {
                    if (index < leadingBlanks || index >= totalCells) {
                      return const SizedBox.shrink();
                    }
                    final dayNumber = index - leadingBlanks + 1;
                    final dayDate = DateTime(
                      month.year,
                      month.month,
                      dayNumber,
                    );
                    final state = _dayState(dayDate);
                    final statusIcon = _statusIconForState(state);
                    final bgColor = _backgroundForState(state);

                    return Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: const Color(0xFFE2EAF6)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNumber',
                            style: const TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: FontWeight.w800,
                              color: AppPalette.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          statusIcon,
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF1FA65A),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.tr(ar: 'تم التناول', en: 'Taken'),
                      style: const TextStyle(
                        color: AppPalette.muted,
                        fontSize: AppFontSize.caption,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.cancel_rounded,
                      color: Color(0xFFE24C4B),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.tr(ar: 'لم يتم التناول', en: 'Not taken'),
                      style: const TextStyle(
                        color: AppPalette.muted,
                        fontSize: AppFontSize.caption,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
                    fontWeight: FontWeight.w800,
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
                        fontWeight: FontWeight.w800,
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
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
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
        ? const [
            'الأحد',
            'الاثنين',
            'الثلاثاء',
            'الأربعاء',
            'الخميس',
            'الجمعة',
            'السبت',
          ]
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
                      label: context.tr(ar: 'إضافة دواء', en: 'Add medicine'),
                      onTap: onAddMedication,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _QuickActionButton(
                      icon: Icons.schedule_rounded,
                      label: context.tr(ar: 'إضافة جرعة', en: 'Add dose'),
                      onTap: onAddDose,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _QuickActionButton(
                      icon: Icons.monitor_heart_rounded,
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
          backgroundColor: AppPalette.patientFab,
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
