part of 'pharmacist_home.dart';

class _PharmacistOverviewTab extends StatelessWidget {
  const _PharmacistOverviewTab({
    required this.active,
    required this.urgent,
    required this.completed,
    required this.tasks,
    required this.ratings,
    required this.ratingSummary,
    required this.onCreateTask,
  });

  final int active;
  final int urgent;
  final int completed;
  final List<PharmacyTaskModel> tasks;
  final List<PharmacyRatingModel> ratings;
  final PharmacyRatingSummary ratingSummary;
  final VoidCallback onCreateTask;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _pharmacistPagePadding,
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
              Text(
                context.tr(ar: 'لوحة الصيدلي', en: 'Pharmacist dashboard'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.pageTitle,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.tr(
                  ar: 'واجهة تشغيلية احترافية للصيدلية، مصممة لإدارة المخزون والأولويات وسير العمل اليومي.',
                  en: 'A professional workspace for inventory control, priorities, and daily pharmacy operations.',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.body,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _PharmacyStat(
                      label: context.tr(ar: 'نشطة', en: 'Active'),
                      value: '$active',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PharmacyStat(
                      label: context.tr(ar: 'عاجلة', en: 'Urgent'),
                      value: '$urgent',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PharmacyStat(
                      label: context.tr(ar: 'مكتملة', en: 'Completed'),
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
              Text(
                context.tr(
                  ar: 'تركيز المخزون اليوم',
                  en: 'Today inventory focus',
                ),
                style: const TextStyle(
                  fontSize: AppFontSize.title,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (tasks.isEmpty)
                Column(
                  children: [
                    Text(
                      context.tr(
                        ar: 'لا توجد عناصر مخزون بعد. أضف أول عنصر للبدء.',
                        en: 'No inventory items yet. Add your first item to start.',
                      ),
                      style: const TextStyle(fontSize: AppFontSize.body),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: onCreateTask,
                      child: Text(
                        context.tr(
                          ar: 'إضافة عنصر مخزون',
                          en: 'Add inventory item',
                        ),
                      ),
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
        const SizedBox(height: AppSpacing.md),
        _PharmacyRatingOverviewCard(ratings: ratings, summary: ratingSummary),
      ],
    );
  }
}

class _PharmacyRatingOverviewCard extends StatelessWidget {
  const _PharmacyRatingOverviewCard({
    required this.ratings,
    required this.summary,
  });

  final List<PharmacyRatingModel> ratings;
  final PharmacyRatingSummary summary;

  @override
  Widget build(BuildContext context) {
    final latestRatings = ratings.take(3).toList(growable: false);
    return DepthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFFB100)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  context.tr(ar: 'تقييمات الصيدلية', en: 'Pharmacy ratings'),
                  style: const TextStyle(
                    fontSize: AppFontSize.title,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.text,
                  ),
                ),
              ),
              Text(
                summary.hasRatings ? summary.average.toStringAsFixed(1) : '--',
                style: const TextStyle(
                  fontSize: AppFontSize.sectionTitle,
                  fontWeight: FontWeight.w900,
                  color: AppPalette.pharmacistPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            summary.hasRatings
                ? context.tr(
                    ar: '${summary.count} تقييم من المرضى',
                    en: '${summary.count} patient reviews',
                  )
                : context.tr(
                    ar: 'لم تصل تقييمات بعد. ستظهر هنا تلقائياً عند تقييم المرضى للصيدلية.',
                    en: 'No reviews yet. Patient ratings will appear here automatically.',
                  ),
            style: const TextStyle(
              color: AppPalette.muted,
              fontSize: AppFontSize.body,
              height: 1.4,
            ),
          ),
          if (latestRatings.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...latestRatings.map(
              (rating) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PharmacistReviewTile(rating: rating),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PharmacistReviewTile extends StatelessWidget {
  const _PharmacistReviewTile({required this.rating});

  final PharmacyRatingModel rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBFA),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFD8EEE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rating.patientName.isEmpty
                      ? context.tr(ar: 'مريض', en: 'Patient')
                      : rating.patientName,
                  style: const TextStyle(
                    color: AppPalette.text,
                    fontSize: AppFontSize.body,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ...List.generate(
                5,
                (index) => Icon(
                  index < rating.rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: const Color(0xFFFFB100),
                  size: 18,
                ),
              ),
            ],
          ),
          if (rating.comment.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              rating.comment,
              style: const TextStyle(
                color: AppPalette.muted,
                fontSize: AppFontSize.body,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
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
      padding: _pharmacistPagePadding,
      children: [
        Text(
          context.tr(ar: 'تحليلات المخزون', en: 'Inventory insights'),
          style: const TextStyle(
            fontSize: AppFontSize.pageTitle,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: DepthCard(
                child: _MetricBlock(
                  label: context.tr(ar: 'صرف', en: 'Dispense'),
                  value: '$dispense',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DepthCard(
                child: _MetricBlock(
                  label: context.tr(ar: 'مخزون', en: 'Inventory'),
                  value: '$inventory',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DepthCard(
                child: _MetricBlock(
                  label: context.tr(ar: 'استشارة', en: 'Consultation'),
                  value: '$consult',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        DepthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(ar: 'نظرة تشغيلية', en: 'Operations snapshot'),
                style: const TextStyle(
                  fontSize: AppFontSize.title,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.tr(
                  ar: 'هذه المنطقة جاهزة لتوسعات لاحقة مثل الربط مع المرضى أو تقارير المخزون.',
                  en: 'This area is prepared for future expansions such as patient links or inventory reports.',
                ),
                style: const TextStyle(fontSize: AppFontSize.body),
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
                            task.isOutOfStock
                                ? Icons.cancel_rounded
                                : task.isLowStock
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_rounded,
                            color: task.isOutOfStock
                                ? AppPalette.coral
                                : task.isLowStock
                                ? AppPalette.amber
                                : AppPalette.success,
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
                            task.isOutOfStock
                                ? context.tr(ar: 'نفد', en: 'Out')
                                : '${task.quantity} ${_unitLabel(context, task.unit)}',
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

  String _unitLabel(BuildContext context, String unit) {
    switch (unit) {
      case 'strip':
        return context.tr(ar: 'شريط', en: 'strip');
      case 'pack':
        return context.tr(ar: 'عبوة', en: 'pack');
      default:
        return context.tr(ar: 'علبة', en: 'box');
    }
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
    final accent = task.isOutOfStock
        ? AppPalette.coral
        : task.isLowStock
        ? AppPalette.amber
        : AppPalette.success;

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
                const SizedBox(height: AppSpacing.xs),
                Text(
                  task.isOutOfStock
                      ? context.tr(ar: 'نفد المخزون', en: 'Out of stock')
                      : context.tr(
                          ar: 'الكمية: ${task.quantity} | حد التنبيه: ${task.minQuantity}',
                          en: 'Qty: ${task.quantity} | Min: ${task.minQuantity}',
                        ),
                  style: TextStyle(
                    color: task.isOutOfStock
                        ? AppPalette.coral
                        : task.isLowStock
                        ? AppPalette.amber
                        : AppPalette.success,
                    fontSize: AppFontSize.caption,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            children: [
              _WorkflowTag(label: _categoryLabel(context, task.category)),
              const SizedBox(height: AppSpacing.xs),
              _WorkflowTag(
                label: _priorityLabel(context, task.priority),
                tinted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _categoryLabel(BuildContext context, String category) {
    switch (category) {
      case 'inventory':
        return context.tr(ar: 'مخزون', en: 'Inventory');
      case 'consultation':
        return context.tr(ar: 'استشارة', en: 'Consultation');
      default:
        return context.tr(ar: 'صرف', en: 'Dispense');
    }
  }

  String _priorityLabel(BuildContext context, String priority) {
    switch (priority) {
      case 'high':
        return context.tr(ar: 'عالية', en: 'High');
      case 'low':
        return context.tr(ar: 'منخفضة', en: 'Low');
      default:
        return context.tr(ar: 'متوسطة', en: 'Medium');
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

class _ModernPharmacistAccountTab extends StatelessWidget {
  const _ModernPharmacistAccountTab({
    required this.email,
    required this.displayName,
    required this.ratingSummary,
    required this.onEditProfile,
    required this.onSignOut,
  });

  final String email;
  final String displayName;
  final PharmacyRatingSummary ratingSummary;
  final VoidCallback onEditProfile;
  final Future<void> Function() onSignOut;

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
                radius: 28,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.local_pharmacy_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                displayName,
                style: const TextStyle(
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
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFFFF4D8),
                child: Icon(Icons.star_rounded, color: Color(0xFFFFB100)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(ar: 'تقييم الصيدلية', en: 'Pharmacy rating'),
                      style: const TextStyle(
                        color: AppPalette.text,
                        fontSize: AppFontSize.body,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      ratingSummary.hasRatings
                          ? context.tr(
                              ar: '${ratingSummary.average.toStringAsFixed(1)} من 5 بناءً على ${ratingSummary.count} تقييم',
                              en: '${ratingSummary.average.toStringAsFixed(1)} out of 5 from ${ratingSummary.count} reviews',
                            )
                          : context.tr(
                              ar: 'لا توجد تقييمات بعد.',
                              en: 'No ratings yet.',
                            ),
                      style: const TextStyle(
                        color: AppPalette.muted,
                        fontSize: AppFontSize.body,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DepthCard(
          child: Column(
            children: [
              _ActionRow(
                icon: Icons.edit_outlined,
                title: context.tr(ar: 'تعديل الملف الشخصي', en: 'Edit profile'),
                onTap: onEditProfile,
              ),
              const Divider(),
              _ActionRow(
                icon: Icons.cloud_done_outlined,
                title: context.tr(
                  ar: 'بيانات الصيدلية داخل صفحة تعديل الملف',
                  en: 'Pharmacy details are managed inside the profile editor',
                ),
              ),
              const Divider(),
              _ActionRow(
                icon: Icons.logout_rounded,
                title: context.tr(ar: 'تسجيل الخروج', en: 'Sign out'),
                onTap: () async {
                  await onSignOut();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
