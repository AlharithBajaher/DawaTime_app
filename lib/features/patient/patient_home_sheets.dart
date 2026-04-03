part of 'patient_home.dart';

class _MedicationActionSheet extends StatelessWidget {
  const _MedicationActionSheet({
    required this.medication,
    required this.onTaken,
    required this.onSkipped,
    required this.onReschedule,
    required this.onEdit,
    required this.onDelete,
  });

  final MedicationModel medication;
  final VoidCallback onTaken;
  final VoidCallback onSkipped;
  final VoidCallback onReschedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: onDelete,
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
                  'مجدولة في الساعة ${medication.displayTime()} اليوم',
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
                        label: 'إعادة الجدولة',
                        color: const Color(0xFFE9EFFA),
                        onTap: onReschedule,
                      ),
                    ),
                    Expanded(
                      child: _ActionCircleButton(
                        icon: Icons.check_rounded,
                        label: 'تناول',
                        color: AppPalette.patientPrimary,
                        foreground: Colors.white,
                        onTap: onTaken,
                      ),
                    ),
                    Expanded(
                      child: _ActionCircleButton(
                        icon: Icons.close_rounded,
                        label: 'تخطي',
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icon, color: foreground, size: 30),
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
                  'تمت إضافة $name بنجاح!',
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
                  label: const Text('إضافة دواء آخر'),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('تم'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
                    const Padding(
                      padding: AppSpacing.pagePaddingWide,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Color(0xFFEAF4FF),
                            child: Icon(Icons.person_rounded, size: 42),
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            'ضيف',
                            style: TextStyle(
                              fontSize: AppFontSize.pageTitle,
                              fontWeight: FontWeight.w900,
                              color: AppPalette.text,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xxs),
                          Text(
                            'إنشاء الملف الشخصي',
                            style: TextStyle(
                              color: AppPalette.muted,
                              fontSize: AppFontSize.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    const _ProfileItem(
                      title: 'ملفات التعريف الشخصية',
                      icon: Icons.badge_outlined,
                    ),
                    const Divider(height: 1),
                    const _ProfileItem(
                      title: 'أضف شخص فعال',
                      icon: Icons.add_circle_outline_rounded,
                    ),
                    const Divider(height: 1),
                    const _ProfileItem(
                      title: 'أصدقاؤك في الطب فريند',
                      icon: Icons.group_outlined,
                    ),
                    const Divider(height: 1),
                    const _ProfileItem(
                      title: 'دعوة صديق طب فريند',
                      icon: Icons.person_add_alt_1_outlined,
                    ),
                    const Divider(height: 1),
                    const _ProfileItem(
                      title: 'رمز التحقق',
                      icon: Icons.qr_code_rounded,
                    ),
                    const Divider(height: 1),
                    _ProfileItem(
                      title: 'تسجيل الخروج',
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

class _ReminderTroubleshootPage extends StatelessWidget {
  const _ReminderTroubleshootPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('استكشاف وإصلاح أخطاء التذكير')),
      body: Container(
        color: const Color(0xFFF3F6FB),
        child: ListView(
          padding: AppSpacing.pagePadding,
          children: const [
            _TroubleshootCard(
              title: 'خطوة ١: استثني DawaTime من تنظيم البطارية',
              description:
                  'تحسين البطارية يقلل نشاطات التطبيقات عندما لا تكون فعالة، مما قد يؤثر على التذكيرات.',
            ),
            SizedBox(height: AppSpacing.md),
            _TroubleshootCard(
              title: 'خطوة ٢: قم بضبط إعدادات بطارية مطورة',
              description:
                  'تأكد من حصولك على إشعارات في الوقت الصحيح بواسطة ضبط إعدادات البطارية.',
            ),
            SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                'تحتاج لمزيد من\nاتصل بالدعم',
                textAlign: TextAlign.center,
                style: TextStyle(
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
                const SnackBar(
                  content: Text(
                    'تمت إضافة هذه الخطوة كإجراء إرشادي داخل التطبيق.',
                  ),
                ),
              );
            },
            child: const Text('خذ هذا التصرف'),
          ),
        ],
      ),
    );
  }
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
                    Icon(icon, size: 76, color: AppPalette.patientPrimary),
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
