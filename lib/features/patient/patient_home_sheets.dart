part of 'patient_home.dart';

class _MedicationActionSheet extends StatelessWidget {
  const _MedicationActionSheet({
    required this.medication,
    required this.onTaken,
    required this.onSkipped,
    required this.onSnooze30,
    required this.onSnooze60,
    required this.onReschedule,
    required this.onEdit,
    required this.onDelete,
  });

  final MedicationModel medication;
  final Future<void> Function() onTaken;
  final Future<void> Function() onSkipped;
  final Future<void> Function() onSnooze30;
  final Future<void> Function() onSnooze60;
  final Future<void> Function() onReschedule;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: DepthCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () async => onEdit(),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: () async => onDelete(),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                    const Spacer(),
                    const Icon(Icons.info_outline_rounded),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(0xFFF0F4FA),
                  child: Icon(
                    Icons.medication_outlined,
                    color: AppPalette.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  medication.name,
                  style: const TextStyle(
                    fontSize: AppFontSize.hero,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.tr(
                    ar: 'مجدولة اليوم في ${medication.displayTime()}',
                    en: 'Scheduled today at ${medication.displayTime()}',
                  ),
                  style: const TextStyle(
                    color: AppPalette.text,
                    fontSize: AppFontSize.bodyLarge,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  medication.dose,
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: AppFontSize.body,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCircleButton(
                        icon: Icons.access_time_rounded,
                        label: context.tr(
                          ar: 'إعادة الجدولة',
                          en: 'Reschedule',
                        ),
                        color: const Color(0xFFE9EFFA),
                        onTap: onReschedule,
                      ),
                    ),
                    Expanded(
                      child: _ActionCircleButton(
                        icon: Icons.snooze_rounded,
                        label: context.tr(ar: 'تأجيل 30د', en: 'Snooze 30m'),
                        color: const Color(0xFFE9EFFA),
                        onTap: onSnooze30,
                      ),
                    ),
                    Expanded(
                      child: _ActionCircleButton(
                        icon: Icons.snooze_outlined,
                        label: context.tr(ar: 'تأجيل 60د', en: 'Snooze 60m'),
                        color: const Color(0xFFE9EFFA),
                        onTap: onSnooze60,
                      ),
                    ),
                    Expanded(
                      child: _ActionCircleButton(
                        icon: Icons.check_rounded,
                        label: context.tr(ar: 'تناول', en: 'Taken'),
                        color: AppPalette.patientPrimary,
                        foreground: Colors.white,
                        onTap: onTaken,
                      ),
                    ),
                    Expanded(
                      child: _ActionCircleButton(
                        icon: Icons.close_rounded,
                        label: context.tr(ar: 'تخطي', en: 'Skip'),
                        color: const Color(0xFFE9EFFA),
                        onTap: onSkipped,
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

class _ActionCircleButton extends StatelessWidget {
  const _ActionCircleButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.foreground = AppPalette.patientPrimary,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color foreground;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () async => onTap(),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icon, color: foreground, size: 24),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: const TextStyle(
            color: AppPalette.patientPrimary,
            fontSize: AppFontSize.caption,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _MedicationSuccessSheet extends StatelessWidget {
  const _MedicationSuccessSheet({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: DepthCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFE5FFF3),
                  child: Icon(
                    Icons.event_available_rounded,
                    color: AppPalette.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.tr(
                    ar: 'تمت إضافة $name بنجاح!',
                    en: '$name was added successfully!',
                  ),
                  style: const TextStyle(
                    fontSize: AppFontSize.sectionTitle,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.text,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    context.tr(
                      ar: 'إضافة دواء آخر',
                      en: 'Add another medicine',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(context.tr(ar: 'تم', en: 'Done')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet({required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.82,
            ),
            child: DepthCard(
              padding: EdgeInsets.zero,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: AppSpacing.pagePaddingWide,
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 40,
                            backgroundColor: Color(0xFFEAF4FF),
                            child: Icon(Icons.person_rounded, size: 32),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            context.tr(ar: 'ضيف', en: 'Guest'),
                            style: const TextStyle(
                              fontSize: AppFontSize.pageTitle,
                              fontWeight: FontWeight.w900,
                              color: AppPalette.text,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            context.tr(
                              ar: 'إنشاء الملف الشخصي',
                              en: 'Create profile',
                            ),
                            style: const TextStyle(
                              color: AppPalette.muted,
                              fontSize: AppFontSize.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    _ProfileItem(
                      title: context.tr(
                        ar: 'ملفات التعريف الشخصية',
                        en: 'Personal profiles',
                      ),
                      icon: Icons.badge_outlined,
                    ),
                    const Divider(height: 1),
                    _ProfileItem(
                      title: context.tr(
                        ar: 'أضف شخصاً فعالاً',
                        en: 'Add active person',
                      ),
                      icon: Icons.add_circle_outline_rounded,
                    ),
                    const Divider(height: 1),
                    _ProfileItem(
                      title: context.tr(
                        ar: 'أصدقاؤك في DawaTime',
                        en: 'Your DawaTime friends',
                      ),
                      icon: Icons.group_outlined,
                    ),
                    const Divider(height: 1),
                    _ProfileItem(
                      title: context.tr(ar: 'دعوة صديق', en: 'Invite a friend'),
                      icon: Icons.person_add_alt_1_outlined,
                    ),
                    const Divider(height: 1),
                    _ProfileItem(
                      title: context.tr(
                        ar: 'رمز التحقق',
                        en: 'Verification code',
                      ),
                      icon: Icons.qr_code_rounded,
                    ),
                    const Divider(height: 1),
                    _ProfileItem(
                      title: context.tr(ar: 'تسجيل الخروج', en: 'Sign out'),
                      icon: Icons.logout_rounded,
                      onTap: () {
                        onSignOut();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({required this.title, required this.icon, this.onTap});

  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.patientPrimary.withValues(alpha: 0.10),
              ),
              child: Icon(icon, color: AppPalette.patientPrimary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: AppFontSize.title,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ReminderTroubleshootPage extends StatelessWidget {
  const _ReminderTroubleshootPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr(
            ar: 'استكشاف وإصلاح أخطاء التذكير',
            en: 'Troubleshoot reminders',
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFFF3F6FB),
        child: ListView(
          padding: AppSpacing.pagePadding,
          children: [
            _TroubleshootCard(
              title: context.tr(
                ar: 'خطوة 1: استثنِ DawaTime من تحسين البطارية',
                en: 'Step 1: Exclude DawaTime from battery optimization',
              ),
              description: context.tr(
                ar: 'تحسين البطارية قد يقلل نشاط التطبيق في الخلفية، مما قد يؤثر على وصول التذكيرات.',
                en: 'Battery optimization can reduce background activity and delay reminders.',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _TroubleshootCard(
              title: context.tr(
                ar: 'خطوة 2: راجع إعدادات إشعارات الجهاز',
                en: 'Step 2: Review device notification settings',
              ),
              description: context.tr(
                ar: 'تأكد أن الإشعارات مسموحة للتطبيق وأن وضع عدم الإزعاج لا يمنع ظهور التنبيهات.',
                en: 'Make sure notifications are allowed for the app and Do Not Disturb is not blocking alerts.',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                context.tr(
                  ar: 'تحتاج لمزيد من المساعدة؟\nتواصل مع الدعم',
                  en: 'Need more help?\nContact support',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppPalette.patientPrimary,
                  fontSize: AppFontSize.sectionTitle,
                  fontWeight: FontWeight.w800,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TroubleshootCard extends StatelessWidget {
  const _TroubleshootCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return DepthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.battery_alert_outlined,
                color: AppPalette.patientPrimary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppFontSize.title,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: const TextStyle(
              color: AppPalette.muted,
              fontSize: AppFontSize.body,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.tr(
                      ar: 'تمت إضافة هذه الخطوة كإجراء إرشادي داخل التطبيق.',
                      en: 'This step was added as an in-app guidance action.',
                    ),
                  ),
                ),
              );
            },
            child: Text(
              context.tr(ar: 'خذ هذا التصرف', en: 'Take this action'),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _InfoSimplePage extends StatelessWidget {
  const _InfoSimplePage({
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
      body: Container(
        color: const Color(0xFFF3F6FB),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.maxSheetWidth,
            ),
            child: Padding(
              padding: AppSpacing.pagePaddingWide,
              child: DepthCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 56, color: AppPalette.patientPrimary),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppFontSize.pageTitle,
                        fontWeight: FontWeight.w900,
                        color: AppPalette.text,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppPalette.muted,
                        height: 1.6,
                        fontSize: AppFontSize.body,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
