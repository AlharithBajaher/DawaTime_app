part of 'pharmacist_home.dart';

class _PharmacistMedicineTab extends StatelessWidget {
  const _PharmacistMedicineTab({
    required this.medicines,
    required this.ratingSummary,
    required this.onCreateMedicine,
    required this.onEditMedicine,
    required this.onToggleAvailability,
    required this.onDeleteMedicine,
  });

  final List<SharedMedicineModel> medicines;
  final PharmacyRatingSummary ratingSummary;
  final VoidCallback onCreateMedicine;
  final ValueChanged<SharedMedicineModel> onEditMedicine;
  final void Function(SharedMedicineModel medicine, bool isAvailable)
  onToggleAvailability;
  final ValueChanged<SharedMedicineModel> onDeleteMedicine;

  @override
  Widget build(BuildContext context) {
    final availableCount = medicines
        .where((medicine) => medicine.isAvailable)
        .length;
    final listedCount = medicines.length;
    final needsRxCount = medicines
        .where((medicine) => medicine.requiresPrescription)
        .length;
    final ratingValue = ratingSummary.hasRatings
        ? ratingSummary.average.toStringAsFixed(1)
        : context.tr(ar: 'جديد', en: 'New');

    return ListView(
      padding: _pharmacistPagePadding,
      children: [
        DepthCard(
          gradient: const LinearGradient(
            colors: [AppPalette.pharmacistPrimary, AppPalette.pharmacistAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: Colors.white.withValues(alpha: 0.14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                  ar: 'كتالوج الأدوية المنشورة',
                  en: 'Shared medicine catalog',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.pageTitle,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.tr(
                  ar: 'انشر الأدوية مع الصور والسعر والجرعة وموقع الصيدلية وحالة التوفر المباشرة للمرضى.',
                  en: 'Publish medicine listings with photos, pricing, dosage, pharmacy location, and live stock status for patients.',
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
                      label: context.tr(ar: 'منشورة', en: 'Published'),
                      value: '$listedCount',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PharmacyStat(
                      label: context.tr(ar: 'متوفرة', en: 'Available'),
                      value: '$availableCount',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PharmacyStat(
                      label: context.tr(ar: 'بوصفة', en: 'Rx only'),
                      value: '$needsRxCount',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PharmacyStat(
                      label: context.tr(ar: 'التقييم', en: 'Rating'),
                      value: ratingValue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                ratingSummary.hasRatings
                    ? context.tr(
                        ar: '${ratingSummary.count} تقييم من المرضى لصيدليتك',
                        en: '${ratingSummary.count} patient reviews for your pharmacy',
                      )
                    : context.tr(
                        ar: 'ستظهر تقييمات المرضى هنا بعد أول مراجعة.',
                        en: 'Patient ratings will appear here after the first review.',
                      ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.caption,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (medicines.isEmpty)
          DepthCard(
            child: Column(
              children: [
                const Icon(
                  Icons.local_pharmacy_rounded,
                  size: 72,
                  color: AppPalette.pharmacistPrimary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.tr(
                    ar: 'لا توجد أدوية منشورة بعد',
                    en: 'No medicines published yet',
                  ),
                  style: const TextStyle(
                    fontSize: AppFontSize.sectionTitle,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.tr(
                    ar: 'أضف أول دواء حتى يستطيع المرضى اكتشاف مخزون صيدليتك.',
                    en: 'Add your first product listing so patients can discover your pharmacy inventory.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: AppFontSize.body,
                    color: AppPalette.muted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: onCreateMedicine,
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                  label: Text(
                    context.tr(ar: 'نشر دواء', en: 'Publish medicine'),
                  ),
                ),
              ],
            ),
          )
        else
          ...medicines.map(
            (medicine) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _ModernPublishedMedicineCard(
                medicine: medicine,
                onEdit: () => onEditMedicine(medicine),
                onToggleAvailability: (value) =>
                    onToggleAvailability(medicine, value),
                onDelete: () => onDeleteMedicine(medicine),
              ),
            ),
          ),
      ],
    );
  }
}

class _MedicineInfoChip extends StatelessWidget {
  const _MedicineInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppPalette.pharmacistPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppPalette.pharmacistPrimary),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: FontWeight.w700,
              color: AppPalette.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernPublishedMedicineCard extends StatelessWidget {
  const _ModernPublishedMedicineCard({
    required this.medicine,
    required this.onEdit,
    required this.onToggleAvailability,
    required this.onDelete,
  });

  final SharedMedicineModel medicine;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleAvailability;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = medicine.isAvailable
        ? AppPalette.success
        : AppPalette.coral;

    return DepthCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: SizedBox(
                  width: 78,
                  height: 78,
                  child:
                      medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty
                      ? Image.network(
                          medicine.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildMedicineFallback(),
                        )
                      : _buildMedicineFallback(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            medicine.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: AppFontSize.sectionTitle,
                              fontWeight: FontWeight.w800,
                              color: AppPalette.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            medicine.isAvailable
                                ? context.tr(ar: 'متوفر', en: 'Available')
                                : context.tr(ar: 'نفد', en: 'Out'),
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      medicine.pharmacyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppFontSize.body,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.pharmacistPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _MedicineInfoChip(
                          icon: Icons.schedule_rounded,
                          label: medicine.displayTimelineLabel(),
                        ),
                        _MedicineInfoChip(
                          icon: Icons.payments_rounded,
                          label: medicine.formattedPrice(
                            isArabic: context.isArabic,
                          ),
                        ),
                        _MedicineInfoChip(
                          icon: Icons.science_rounded,
                          label: medicine.dosage,
                        ),
                        _MedicineInfoChip(
                          icon: Icons.inventory_2_rounded,
                          label: medicine.packageSize,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            medicine.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: AppFontSize.body,
              color: AppPalette.text,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _MedicineInfoChip(
                icon: Icons.category_rounded,
                label: medicine.category,
              ),
              _MedicineInfoChip(
                icon: Icons.location_on_rounded,
                label: medicine.location,
              ),
              _MedicineInfoChip(
                icon: Icons.verified_user_rounded,
                label: medicine.requiresPrescription
                    ? context.tr(ar: 'يتطلب وصفة', en: 'Rx required')
                    : context.tr(ar: 'بدون وصفة', en: 'OTC'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  value: medicine.isAvailable,
                  onChanged: onToggleAvailability,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeThumbColor: AppPalette.pharmacistPrimary,
                  title: Text(
                    context.tr(ar: 'إتاحة للمرضى', en: 'Visible to patients'),
                    style: const TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_rounded,
                  color: AppPalette.pharmacistPrimary,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_rounded,
                  color: AppPalette.coral,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppPalette.pharmacistImageStart, AppPalette.pharmacistImageEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.medication_liquid_rounded,
          size: 38,
          color: AppPalette.pharmacistPrimary,
        ),
      ),
    );
  }
}
