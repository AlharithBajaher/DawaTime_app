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
                      icon: const Icon(Icons.edit_rounded),
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
                  backgroundColor: AppPalette.surfaceAlt,
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
                        color: AppPalette.actionButtonBg,
                        onTap: onReschedule,
                      ),
                    ),
                    Expanded(
                      child: _ActionCircleButton(
                        icon: Icons.snooze_rounded,
                        label: context.tr(ar: 'تأجيل 30د', en: 'Snooze 30m'),
                        color: AppPalette.actionButtonBg,
                        onTap: onSnooze30,
                      ),
                    ),
                    Expanded(
                      child: _ActionCircleButton(
                        icon: Icons.snooze_rounded,
                        label: context.tr(ar: 'تأجيل 60د', en: 'Snooze 60m'),
                        color: AppPalette.actionButtonBg,
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
                        color: AppPalette.actionButtonBg,
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
                    fontWeight: FontWeight.w800,
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


