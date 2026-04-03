part of 'patient_home.dart';

class _PatientTopBar extends StatelessWidget {
  const _PatientTopBar({
    required this.userName,
    required this.onProfilePressed,
  });

  final String userName;
  final VoidCallback onProfilePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      color: const Color(0xFF2287C8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              color: Colors.white.withValues(alpha: 0.14),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppFontSize.title,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: onProfilePressed,
            child: const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person_rounded, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientHomeTab extends StatelessWidget {
  const _PatientHomeTab({
    required this.selectedDate,
    required this.timeline,
    required this.onAddMedication,
    required this.onSelectOffset,
    required this.onShiftWeek,
    required this.onMedicationTap,
  });

  final DateTime selectedDate;
  final List<_DoseMoment> timeline;
  final VoidCallback onAddMedication;
  final ValueChanged<int> onSelectOffset;
  final ValueChanged<int> onShiftWeek;
  final ValueChanged<MedicationModel> onMedicationTap;

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
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity.abs() < 180) {
                return;
              }
              onShiftWeek(velocity < 0 ? 7 : -7);
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => onShiftWeek(-7),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Text(
                          _displayWeekRangeLabel(context, startOfWeek),
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
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Row(
                    children: weekDates
                        .map((date) {
                          final normalizedDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                          );
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: _DayTile(
                                date: date,
                                selected: normalizedDate == baseDate,
                                onTap: () => onSelectOffset(
                                  normalizedDate.difference(todayDate).inDays,
                                ),
                              ),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
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
                  const SizedBox(height: AppSpacing.sm),
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 96,
                    color: Color(0xFFD4DCE8),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'رتب جدول الأدوية الخاص بك',
                    style: TextStyle(
                      fontSize: AppFontSize.pageTitle,
                      fontWeight: FontWeight.w900,
                      color: AppPalette.text,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'اعرض جدولك اليومي وضع علامات على الأدوية حينما يتم أخذها.',
                    style: TextStyle(
                      color: AppPalette.muted,
                      height: 1.6,
                      fontSize: AppFontSize.body,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: onAddMedication,
                    child: const Text('أضف دواء'),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeline.first.label,
                  style: const TextStyle(
                    fontSize: AppFontSize.hero,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...timeline.map(
                  (dose) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      onTap: () => onMedicationTap(dose.medication),
                      child: DepthCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    dose.medication.name,
                                    style: const TextStyle(
                                      fontSize: AppFontSize.sectionTitle,
                                      fontWeight: FontWeight.w900,
                                      color: AppPalette.text,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    dose.medication.dose,
                                    style: const TextStyle(
                                      color: AppPalette.muted,
                                      fontSize: AppFontSize.body,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFDDE3EF),
                                  width: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ignore: unused_element
  String _fullDateLabel(BuildContext context, DateTime date) {
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
    return context.isArabic
        ? 'اليوم، ${date.day} ${months[date.month - 1]}'
        : 'Today, ${months[date.month - 1]} ${date.day}';
  }

  // ignore: unused_element
  String _weekRangeLabel(BuildContext context, DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    if (context.isArabic) {
      return '${startOfWeek.day} - ${endOfWeek.day} ${_monthLabel(context, endOfWeek.month)}';
    }
    return '${_monthLabel(context, startOfWeek.month)} ${startOfWeek.day} - ${endOfWeek.day}';
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

  String _selectedDateLabel(BuildContext context, DateTime date) {
    final monthLabel = _monthLabel(context, date.month);
    final weekdayLabel = _weekdayLabel(context, date);
    return context.isArabic
        ? '$weekdayLabel، ${date.day} $monthLabel'
        : '$weekdayLabel, $monthLabel ${date.day}';
  }

  String _displayWeekRangeLabel(BuildContext context, DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final startMonth = _monthLabel(context, startOfWeek.month);
    final endMonth = _monthLabel(context, endOfWeek.month);
    if (startOfWeek.month != endOfWeek.month) {
      return context.isArabic
          ? '${startOfWeek.day} $startMonth - ${endOfWeek.day} $endMonth'
          : '$startMonth ${startOfWeek.day} - $endMonth ${endOfWeek.day}';
    }
    if (context.isArabic) {
      return '${startOfWeek.day} - ${endOfWeek.day} $endMonth';
    }
    return '$startMonth ${startOfWeek.day} - ${endOfWeek.day}';
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

class _PatientMedicinesTab extends StatelessWidget {
  const _PatientMedicinesTab({
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
                size: 112,
                color: Color(0xFFD0D7E4),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'إدارة أدويتك',
                style: TextStyle(
                  fontSize: AppFontSize.pageTitle,
                  fontWeight: FontWeight.w900,
                  color: AppPalette.text,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'قم بإضافة أدويتك ليتم تذكيرك في الوقت المحدد وتتبع صحتك.',
                style: TextStyle(
                  color: AppPalette.muted,
                  height: 1.6,
                  fontSize: AppFontSize.body,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: onAddMedication,
                child: const Text('أضف دواء'),
              ),
            ],
          ),
        ),
        if (medications.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          ...medications.map(
            (medication) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: DepthCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      medication.name,
                      style: const TextStyle(
                        fontSize: AppFontSize.sectionTitle,
                        fontWeight: FontWeight.w900,
                        color: AppPalette.text,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${medication.dose} • ${medication.displayTime()}',
                      style: const TextStyle(
                        color: AppPalette.muted,
                        fontSize: AppFontSize.body,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PatientUpdatesTab extends StatelessWidget {
  const _PatientUpdatesTab({required this.onLearnMore});

  final VoidCallback onLearnMore;

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
          title: 'مرحباً بك في DawaTime!',
          description:
              'يساعدك التطبيق على تذكر موعد تناول أدويتك، وزيارة الطبيب، ومتابعة صحتك. هل تحتاج إلى مساعدة؟ ما عليك سوى سؤال فريق الدعم لدينا!',
          buttonLabel: 'تعرف على المزيد',
          onPressed: onLearnMore,
        ),
        const SizedBox(height: AppSpacing.md),
        const _UpdateCard(
          title: 'نصائح لتحسين الالتزام',
          description:
              'ثبّت أوقات الجرعات، راجع تنبيهاتك، واحتفظ بقائمة أدوية واضحة لتقليل نسيان الجرعات.',
          buttonLabel: 'عرض النصائح',
        ),
      ],
    );
  }
}

class _PatientMoreTab extends StatelessWidget {
  const _PatientMoreTab({required this.onOpenPage});

  final ValueChanged<Widget> onOpenPage;

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem(title: 'اشتراك DawaTime', icon: Icons.auto_awesome_rounded),
      _MenuItem(
        title: 'الأدوية',
        icon: Icons.medication_outlined,
        page: const _SimplePage(
          title: 'الأدوية',
          description: 'صفحة حقيقية مخصصة لإدارة قائمة الأدوية.',
          icon: Icons.medication_rounded,
        ),
      ),
      _MenuItem(
        title: 'أجهزة تتبع الصحة والقياسات',
        icon: Icons.monitor_heart_outlined,
        page: const _SimplePage(
          title: 'أجهزة تتبع الصحة',
          description:
              'يمكن توسيع هذه الصفحة مستقبلاً لربط الضغط والسكر والنبض وقراءات الصحة.',
          icon: Icons.monitor_heart_outlined,
        ),
      ),
      _MenuItem(
        title: 'المواعيد',
        icon: Icons.calendar_today_outlined,
        page: const _SimplePage(
          title: 'المواعيد',
          description: 'صفحة جاهزة لإدارة زيارات الأطباء والمواعيد الدورية.',
          icon: Icons.calendar_today_rounded,
        ),
      ),
      _MenuItem(
        title: 'ملاحظات اليوميات',
        icon: Icons.note_alt_outlined,
        page: const _SimplePage(
          title: 'ملاحظات اليوميات',
          description:
              'يمكن للمريض كتابة ملاحظاته اليومية المتعلقة بالعلاج أو الحالة.',
          icon: Icons.note_alt_rounded,
        ),
      ),
      _MenuItem(
        title: 'الأطباء',
        icon: Icons.badge_outlined,
        page: const _SimplePage(
          title: 'الأطباء',
          description: 'صفحة مخصصة لحفظ بيانات الأطباء والمتابعة معهم.',
          icon: Icons.badge_rounded,
        ),
      ),
      _MenuItem(
        title: context.t(AppText.settings),
        icon: Icons.settings_outlined,
        page: const SettingsPage(),
      ),
      _MenuItem(
        title: 'إنشاء حساب احتياطي',
        icon: Icons.security_outlined,
        page: const _SimplePage(
          title: 'إنشاء حساب احتياطي',
          description:
              'احتفظ بنسخة سحابية من بياناتك وتأكد من استرجاعها لاحقاً.',
          icon: Icons.security_rounded,
        ),
      ),
      _MenuItem(
        title: 'استكشاف أخطاء التذكيرات وإصلاحها',
        icon: Icons.notifications_active_outlined,
        page: const _ReminderTroubleshootPage(),
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final item = items[index];
        return DepthCard(
          onTap: item.page == null ? null : () => onOpenPage(item.page!),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.patientPrimary.withValues(alpha: 0.10),
                ),
                child: Icon(item.icon, color: AppPalette.patientPrimary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: AppFontSize.title,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.text,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppPalette.muted),
            ],
          ),
        );
      },
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
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1D6EAC), Color(0xFF4CA9E8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
            ),
            child: Stack(
              children: const [
                Positioned(
                  left: AppSpacing.xl,
                  top: 30,
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.health_and_safety_outlined,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
                Positioned(
                  right: AppSpacing.xl,
                  bottom: 30,
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.devices_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: AppSpacing.pagePaddingWide,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppFontSize.sectionTitle,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.text,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppPalette.text,
                    height: 1.6,
                    fontSize: AppFontSize.bodyLarge,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(onPressed: onPressed, child: Text(buttonLabel)),
              ],
            ),
          ),
        ],
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
    final dayNames = context.isArabic
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
        duration: const Duration(milliseconds: 180),
        height: 76,
        decoration: BoxDecoration(
          color: selected ? AppPalette.patientPrimary : const Color(0xFFF5F8FE),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected
                ? AppPalette.patientPrimary
                : const Color(0xFFDDE6F6),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayNames[date.weekday % 7],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : AppPalette.text,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '${date.day}',
              style: TextStyle(
                color: selected ? Colors.white : AppPalette.text,
                fontSize: AppFontSize.sectionTitle,
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
        if (expanded) ...[
          _FloatingActionItem(
            color: const Color(0xFFFF8C87),
            icon: Icons.medication_rounded,
            label: 'إضافة الدواء',
            onTap: onAddMedication,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FloatingActionItem(
            color: const Color(0xFF61B4FF),
            icon: Icons.monitor_heart_outlined,
            label: 'أضف متتبع الصحة',
            onTap: onAddHealthTrack,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FloatingActionItem(
            color: const Color(0xFF6E72FF),
            icon: Icons.add_chart_rounded,
            label: 'إضافة جرعة',
            onTap: onAddDose,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        GestureDetector(
          onTap: onMainTap,
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: expanded ? Colors.white : const Color(0xFFFF8C87),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              expanded ? Icons.close_rounded : Icons.add_rounded,
              size: 40,
              color: expanded ? AppPalette.muted : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatingActionItem extends StatelessWidget {
  const _FloatingActionItem({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: AppPalette.text,
                fontSize: AppFontSize.body,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  const _MenuItem({required this.title, required this.icon, this.page});

  final String title;
  final IconData icon;
  final Widget? page;
}
