part of 'pharmacist_home.dart';

class _PharmacistOverviewTab extends StatelessWidget {
  const _PharmacistOverviewTab({
    required this.active,
    required this.urgent,
    required this.completed,
    required this.tasks,
    required this.onCreateTask,
  });

  final int active;
  final int urgent;
  final int completed;
  final List<PharmacyTaskModel> tasks;
  final VoidCallback onCreateTask;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        120,
      ),
      children: [
        DepthCard(
          gradient: const LinearGradient(
            colors: [AppPalette.pharmacistPrimary, AppPalette.pharmacistAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: Colors.white.withValues(alpha: 0.16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'لوحة الصيدلي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.pageTitle,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'واجهة تشغيلية مختلفة عن واجهة المريض، مصممة للتركيز على المهام والأولويات وسير العمل.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.body,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _PharmacyStat(label: 'نشطة', value: '$active'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PharmacyStat(label: 'عاجلة', value: '$urgent'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PharmacyStat(
                      label: 'مكتملة',
                      value: '$completed',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DepthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تركيز اليوم',
                style: TextStyle(
                  fontSize: AppFontSize.title,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (tasks.isEmpty)
                Column(
                  children: [
                    const Text(
                      'لا توجد مهام بعد. أضف أول مهمة لتبدأ لوحة العمل.',
                      style: TextStyle(fontSize: AppFontSize.body),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: onCreateTask,
                      child: const Text('إضافة مهمة'),
                    ),
                  ],
                )
              else
                ...tasks
                    .take(4)
                    .map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _WorkflowTile(task: task),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkflowTab extends StatelessWidget {
  const _WorkflowTab({
    required this.tasks,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final List<PharmacyTaskModel> tasks;
  final Future<void> Function(PharmacyTaskModel) onToggle;
  final ValueChanged<PharmacyTaskModel> onEdit;
  final ValueChanged<PharmacyTaskModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        120,
      ),
      children: [
        const Text(
          'سير العمل',
          style: TextStyle(
            fontSize: AppFontSize.pageTitle,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'المهام محفوظة في مجموعة صيدلية مستقلة داخل Firestore ومصممة لواجهة الصيدلي فقط.',
          style: TextStyle(fontSize: AppFontSize.body),
        ),
        const SizedBox(height: AppSpacing.md),
        if (tasks.isEmpty)
          const DepthCard(
            child: Text(
              'لا توجد مهام حالياً. أضف مهمة جديدة من الزر العائم.',
              style: TextStyle(fontSize: AppFontSize.body),
            ),
          )
        else
          ...tasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: DepthCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: task.isCompleted,
                      activeColor: AppPalette.pharmacistPrimary,
                      visualDensity: VisualDensity.compact,
                      onChanged: (_) => onToggle(task),
                    ),
                    Expanded(child: _WorkflowTile(task: task)),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit(task);
                        } else {
                          onDelete(task);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('تعديل')),
                        PopupMenuItem(value: 'delete', child: Text('حذف')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InsightsTab extends StatelessWidget {
  const _InsightsTab({required this.tasks});

  final List<PharmacyTaskModel> tasks;

  @override
  Widget build(BuildContext context) {
    final dispense = tasks.where((task) => task.category == 'dispense').length;
    final inventory = tasks
        .where((task) => task.category == 'inventory')
        .length;
    final consult = tasks
        .where((task) => task.category == 'consultation')
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        120,
      ),
      children: [
        const Text(
          'تحليلات التشغيل',
          style: TextStyle(
            fontSize: AppFontSize.pageTitle,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: DepthCard(
                child: _MetricBlock(label: 'صرف', value: '$dispense'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DepthCard(
                child: _MetricBlock(label: 'مخزون', value: '$inventory'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DepthCard(
                child: _MetricBlock(label: 'استشارة', value: '$consult'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        DepthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'نظرة تشغيلية',
                style: TextStyle(
                  fontSize: AppFontSize.title,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'تم تصميم هذه المنطقة لتكون مهيأة لتوسعات لاحقة مثل الربط مع المرضى أو تقارير المخزون.',
                style: TextStyle(fontSize: AppFontSize.body),
              ),
              const SizedBox(height: AppSpacing.md),
              ...tasks
                  .take(5)
                  .map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          Icon(
                            task.isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.pending_actions_rounded,
                            color: task.isCompleted
                                ? AppPalette.success
                                : AppPalette.pharmacistPrimary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              task.title,
                              style: const TextStyle(
                                fontSize: AppFontSize.body,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            _priorityLabel(task.priority),
                            style: const TextStyle(
                              color: AppPalette.muted,
                              fontSize: AppFontSize.caption,
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
    );
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return 'عالية';
      case 'low':
        return 'منخفضة';
      default:
        return 'متوسطة';
    }
  }
}

class _PharmacistAccountTab extends StatelessWidget {
  const _PharmacistAccountTab({required this.email, required this.onSignOut});

  final String email;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        120,
      ),
      children: [
        DepthCard(
          gradient: const LinearGradient(
            colors: [Color(0xFF143937), Color(0xFF246962)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: Colors.white.withValues(alpha: 0.12),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.local_pharmacy_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'حساب الصيدلي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.sectionTitle,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                email,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: AppFontSize.body,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DepthCard(
          child: Column(
            children: [
              const _ActionRow(
                icon: Icons.layers_outlined,
                title: 'مهام منفصلة عن واجهة المريض',
              ),
              const Divider(),
              const _ActionRow(
                icon: Icons.cloud_done_outlined,
                title: 'حفظ مباشر داخل Firestore',
              ),
              const Divider(),
              _ActionRow(
                icon: Icons.logout_rounded,
                title: 'تسجيل الخروج',
                onTap: onSignOut,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PharmacyStat extends StatelessWidget {
  const _PharmacyStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowTile extends StatelessWidget {
  const _WorkflowTile({required this.task});

  final PharmacyTaskModel task;

  @override
  Widget build(BuildContext context) {
    final accent = task.priority == 'high'
        ? AppPalette.coral
        : task.priority == 'low'
        ? AppPalette.success
        : AppPalette.amber;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FBF9),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 50,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: AppFontSize.bodyLarge,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  task.details,
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: AppFontSize.body,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            children: [
              _WorkflowTag(label: _categoryLabel(task.category)),
              const SizedBox(height: AppSpacing.xs),
              _WorkflowTag(label: _priorityLabel(task.priority), tinted: true),
            ],
          ),
        ],
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'inventory':
        return 'مخزون';
      case 'consultation':
        return 'استشارة';
      default:
        return 'صرف';
    }
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return 'عالية';
      case 'low':
        return 'منخفضة';
      default:
        return 'متوسطة';
    }
  }
}

class _WorkflowTag extends StatelessWidget {
  const _WorkflowTag({required this.label, this.tinted = false});

  final String label;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: tinted
            ? AppPalette.pharmacistPrimary.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tinted ? AppPalette.pharmacistPrimary : AppPalette.text,
          fontSize: AppFontSize.caption,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: AppFontSize.pageTitle,
            fontWeight: FontWeight.w900,
            color: AppPalette.text,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: const TextStyle(
            color: AppPalette.muted,
            fontSize: AppFontSize.caption,
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.icon, required this.title, this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: AppPalette.pharmacistPrimary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: AppFontSize.body,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppPalette.muted),
        ],
      ),
    );

    if (onTap == null) {
      return child;
    }

    return InkWell(onTap: onTap, child: child);
  }
}
