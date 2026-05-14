part of 'patient_home.dart';

class _PatientMarketplaceTab extends StatelessWidget {
  const _PatientMarketplaceTab({
    required this.medicines,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onOpenMedicine,
  });

  final List<SharedMedicineModel> medicines;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<SharedMedicineModel> onOpenMedicine;

  @override
  Widget build(BuildContext context) {
    final filteredMedicines = medicines
        .where((medicine) => medicine.matchesQuery(searchQuery))
        .toList(growable: false);
    final availableCount = filteredMedicines
        .where((medicine) => medicine.isAvailable)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        DepthCard(
          gradient: const LinearGradient(
            colors: [Color(0xFF1D6EAC), Color(0xFF4CA9E8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: Colors.white.withValues(alpha: 0.16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                  ar: 'تصفح أدوية الصيدليات',
                  en: 'Browse pharmacy medicines',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.pageTitle,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.tr(
                  ar: 'ابحث عن الأدوية المنشورة من الصيادلة، وراجع السعر والجرعة وحالة التوفر وتقييم الصيدلية.',
                  en: 'Search pharmacist-published medicines, then review price, dosage, availability, and pharmacy trust ratings.',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.body,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: context.tr(
                    ar: 'ابحث باسم الدواء أو الصيدلية أو الجرعة أو الموقع',
                    en: 'Search by medicine, pharmacy, dosage, or location',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _MarketplaceMetric(
                      value: '${filteredMedicines.length}',
                      label: context.tr(ar: 'مطابقة', en: 'Matched'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MarketplaceMetric(
                      value: '$availableCount',
                      label: context.tr(ar: 'متوفرة', en: 'Available'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (filteredMedicines.isEmpty)
          DepthCard(
            child: Column(
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: 72,
                  color: AppPalette.patientPrimary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.tr(
                    ar: 'لا توجد أدوية مطابقة',
                    en: 'No matching medicines found',
                  ),
                  style: const TextStyle(
                    fontSize: AppFontSize.sectionTitle,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.tr(
                    ar: 'جرّب اسماً آخر للدواء أو جرعة مختلفة أو موقع صيدلية آخر.',
                    en: 'Try another medicine name, dosage, or pharmacy location.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: AppFontSize.body,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          )
        else
          ...filteredMedicines.map(
            (medicine) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _MarketplaceMedicineCard(
                medicine: medicine,
                onTap: () => onOpenMedicine(medicine),
              ),
            ),
          ),
      ],
    );
  }
}

class _MarketplaceMedicineCard extends StatelessWidget {
  const _MarketplaceMedicineCard({required this.medicine, required this.onTap});

  final SharedMedicineModel medicine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DepthCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(AppRadius.xl),
            ),
            child: SizedBox(
              width: 116,
              height: 156,
              child: medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty
                  ? Image.network(
                      medicine.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackImage(),
                    )
                  : _fallbackImage(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppFontSize.sectionTitle,
                      fontWeight: FontWeight.w900,
                      color: AppPalette.text,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    medicine.pharmacyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.patientPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    medicine.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppFontSize.caption,
                      color: AppPalette.muted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    medicine.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppFontSize.body,
                      color: AppPalette.muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _MedicineBadge(
                        icon: Icons.payments_rounded,
                        label: medicine.formattedPrice(
                          isArabic: context.isArabic,
                        ),
                        color: AppPalette.patientPrimary,
                      ),
                      _MedicineBadge(
                        icon: Icons.science_rounded,
                        label: medicine.dosage,
                        color: AppPalette.adminPrimary,
                      ),
                      _MedicineBadge(
                        icon: medicine.isAvailable
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        label: medicine.isAvailable
                            ? context.tr(ar: 'متوفر', en: 'Available')
                            : context.tr(ar: 'غير متوفر', en: 'Out of stock'),
                        color: medicine.isAvailable
                            ? AppPalette.success
                            : AppPalette.coral,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: const Color(0xFFE9F5FF),
      child: const Icon(
        Icons.medication_liquid_rounded,
        color: AppPalette.patientPrimary,
        size: 34,
      ),
    );
  }
}

class _PatientMedicineDetailsSheet extends StatelessWidget {
  const _PatientMedicineDetailsSheet({required this.medicine});

  final SharedMedicineModel medicine;

  Future<void> _openRatingComposer(BuildContext context) async {
    final service = PharmacyRatingService();
    final commentController = TextEditingController();
    var selectedRating = 5;
    var isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF4F7FB),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4DCE8),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      context.tr(
                        ar: 'تقييم الصيدلية',
                        en: 'Rate this pharmacy',
                      ),
                      style: const TextStyle(
                        fontSize: AppFontSize.sectionTitle,
                        fontWeight: FontWeight.w900,
                        color: AppPalette.text,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      context.tr(
                        ar: 'يساعد تقييمك المرضى الآخرين في معرفة مستوى الثقة والمصداقية.',
                        en: 'Your feedback helps other patients judge trust and reliability.',
                      ),
                      style: const TextStyle(
                        color: AppPalette.muted,
                        fontSize: AppFontSize.body,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        return IconButton(
                          onPressed: () {
                            setModalState(() => selectedRating = star);
                          },
                          icon: Icon(
                            star <= selectedRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xFFFFB100),
                            size: 34,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: context.tr(
                          ar: 'ملاحظتك (اختياري)',
                          en: 'Your comment (optional)',
                        ),
                        prefixIcon: const Icon(Icons.rate_review_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                                setModalState(() => isSaving = true);
                                ScaffoldMessenger.of(context)
                                  ..clearSnackBars()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.tr(
                                          ar: 'جارٍ حفظ التقييم...',
                                          en: 'Saving your rating...',
                                        ),
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                          try {
                            await service.submitRating(
                              pharmacistId: medicine.pharmacistId,
                              pharmacyName: medicine.pharmacyName,
                              rating: selectedRating,
                              comment: commentController.text,
                            );
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.tr(
                                    ar: 'تم حفظ تقييمك بنجاح.',
                                    en: 'Your rating was saved successfully.',
                                  ),
                                ),
                              ),
                            );
                          } catch (error) {
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.tr(
                                    ar: 'تعذر حفظ التقييم: $error',
                                    en: 'Unable to save rating: $error',
                                  ),
                                ),
                              ),
                            );
                          } finally {
                            if (context.mounted) {
                              setModalState(() => isSaving = false);
                            }
                          }
                        },
                        icon: const Icon(Icons.star_rate_rounded),
                        label: Text(
                          isSaving
                              ? context.tr(ar: 'جارٍ الحفظ', en: 'Saving')
                              : context.tr(
                                  ar: 'حفظ التقييم',
                                  en: 'Save rating',
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ratingService = PharmacyRatingService();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF4F7FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
        ),
        child: StreamBuilder<List<PharmacyRatingModel>>(
          stream: ratingService.watchRatingsForPharmacist(medicine.pharmacistId),
          builder: (context, snapshot) {
            final ratings = snapshot.data ?? const <PharmacyRatingModel>[];
            final reviewCount = ratings.length;
            final average = reviewCount == 0
                ? 0.0
                : ratings.fold<int>(0, (sum, item) => sum + item.rating) /
                    reviewCount;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4DCE8),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: SizedBox(
                    width: double.infinity,
                    height: 220,
                    child:
                        medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty
                        ? Image.network(
                            medicine.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _detailsFallbackImage(),
                          )
                        : _detailsFallbackImage(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicine.name,
                            style: const TextStyle(
                              fontSize: AppFontSize.hero,
                              fontWeight: FontWeight.w900,
                              color: AppPalette.text,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            medicine.pharmacyName,
                            style: const TextStyle(
                              fontSize: AppFontSize.title,
                              fontWeight: FontWeight.w800,
                              color: AppPalette.patientPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            medicine.pharmacistName.isEmpty
                                ? medicine.pharmacistEmail
                                : medicine.pharmacistName,
                            style: const TextStyle(
                              fontSize: AppFontSize.body,
                              color: AppPalette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (medicine.isAvailable
                                    ? AppPalette.success
                                    : AppPalette.coral)
                                .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        medicine.isAvailable
                            ? context.tr(
                                ar: 'متوفر الآن',
                                en: 'Available now',
                              )
                            : context.tr(
                                ar: 'غير متوفر',
                                en: 'Out of stock',
                              ),
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          fontWeight: FontWeight.w800,
                          color: medicine.isAvailable
                              ? AppPalette.success
                              : AppPalette.coral,
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
                      _MarketplaceDetailRow(
                        icon: Icons.payments_rounded,
                        title: context.tr(ar: 'السعر', en: 'Price'),
                        value: medicine.formattedPrice(
                          isArabic: context.isArabic,
                        ),
                      ),
                      const Divider(),
                      _MarketplaceDetailRow(
                        icon: Icons.science_rounded,
                        title: context.tr(ar: 'الجرعة', en: 'Dosage'),
                        value: medicine.dosage,
                      ),
                      const Divider(),
                      _MarketplaceDetailRow(
                        icon: Icons.inventory_2_rounded,
                        title: context.tr(ar: 'حجم العبوة', en: 'Pack size'),
                        value: medicine.packageSize,
                      ),
                      const Divider(),
                      _MarketplaceDetailRow(
                        icon: Icons.category_rounded,
                        title: context.tr(ar: 'الفئة', en: 'Category'),
                        value: medicine.category,
                      ),
                      const Divider(),
                      _MarketplaceDetailRow(
                        icon: Icons.verified_user_rounded,
                        title: context.tr(ar: 'الوصفة', en: 'Prescription'),
                        value: medicine.requiresPrescription
                            ? context.tr(
                                ar: 'يتطلب وصفة طبية',
                                en: 'Prescription required',
                              )
                            : context.tr(
                                ar: 'بدون وصفة',
                                en: 'OTC / no prescription',
                              ),
                      ),
                      const Divider(),
                      _MarketplaceDetailRow(
                        icon: Icons.location_on_rounded,
                        title: context.tr(ar: 'الموقع', en: 'Location'),
                        value: medicine.location,
                      ),
                      if (medicine.pharmacyPhone.trim().isNotEmpty) ...[
                        const Divider(),
                        _MarketplaceDetailRow(
                          icon: Icons.phone_rounded,
                          title: context.tr(ar: 'الهاتف', en: 'Phone'),
                          value: medicine.pharmacyPhone,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DepthCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB100),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            reviewCount == 0
                                ? context.tr(
                                    ar: 'لا توجد تقييمات بعد',
                                    en: 'No ratings yet',
                                  )
                                : context.tr(
                                    ar: '${average.toStringAsFixed(1)} من 5',
                                    en: '${average.toStringAsFixed(1)} out of 5',
                                  ),
                            style: const TextStyle(
                              fontSize: AppFontSize.title,
                              fontWeight: FontWeight.w900,
                              color: AppPalette.text,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            context.tr(
                              ar: '$reviewCount تقييم',
                              en: '$reviewCount reviews',
                            ),
                            style: const TextStyle(
                              color: AppPalette.muted,
                              fontSize: AppFontSize.caption,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openRatingComposer(context),
                          icon: const Icon(Icons.star_rate_rounded),
                          label: Text(
                            context.tr(
                              ar: 'قيّم هذه الصيدلية',
                              en: 'Rate this pharmacy',
                            ),
                          ),
                        ),
                      ),
                      if (ratings.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        ...ratings.take(4).map(
                          (rating) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _ReviewTile(rating: rating),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DepthCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(ar: 'الوصف', en: 'Description'),
                        style: const TextStyle(
                          fontSize: AppFontSize.title,
                          fontWeight: FontWeight.w900,
                          color: AppPalette.text,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        medicine.description,
                        style: const TextStyle(
                          fontSize: AppFontSize.body,
                          color: AppPalette.text,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        context.tr(
                          ar: 'تعليمات الاستخدام',
                          en: 'Usage instructions',
                        ),
                        style: const TextStyle(
                          fontSize: AppFontSize.title,
                          fontWeight: FontWeight.w900,
                          color: AppPalette.text,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        medicine.usageInstructions,
                        style: const TextStyle(
                          fontSize: AppFontSize.body,
                          color: AppPalette.text,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check_rounded),
                      label: Text(
                        context.tr(
                          ar: 'إغلاق التفاصيل',
                          en: 'Close details',
                        ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _detailsFallbackImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D6EAC), Color(0xFF4CA9E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.medication_liquid_rounded,
          color: Colors.white,
          size: 72,
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.rating});

  final PharmacyRatingModel rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rating.patientName.isEmpty
                      ? context.tr(ar: 'مستخدم', en: 'User')
                      : rating.patientName,
                  style: const TextStyle(
                    fontSize: AppFontSize.body,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.text,
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

class _MarketplaceMetric extends StatelessWidget {
  const _MarketplaceMetric({required this.value, required this.label});

  final String value;
  final String label;

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
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineBadge extends StatelessWidget {
  const _MedicineBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: AppFontSize.caption,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceDetailRow extends StatelessWidget {
  const _MarketplaceDetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppPalette.patientPrimary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(icon, color: AppPalette.patientPrimary, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppPalette.muted,
                  fontSize: AppFontSize.caption,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppPalette.text,
                  fontSize: AppFontSize.body,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

