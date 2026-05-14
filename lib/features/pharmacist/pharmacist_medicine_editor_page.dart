import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/localization/app_localization.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/depth_card.dart';
import '../../data/models/app_user_model.dart';
import '../../data/models/shared_medicine_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/shared_medicine_service.dart';

class PharmacistMedicineEditorPage extends StatefulWidget {
  const PharmacistMedicineEditorPage({super.key, this.existing});

  final SharedMedicineModel? existing;

  @override
  State<PharmacistMedicineEditorPage> createState() =>
      _PharmacistMedicineEditorPageState();
}

class _PharmacistMedicineEditorPageState
    extends State<PharmacistMedicineEditorPage> {
  final SharedMedicineService _sharedMedicineService = SharedMedicineService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _usageController;
  late final TextEditingController _dosageController;
  late final TextEditingController _packageSizeController;
  late final TextEditingController _priceController;
  late final Future<AppUserModel?> _profileFuture;

  String _category = 'Analgesics';
  bool _isAvailable = true;
  bool _requiresPrescription = false;
  bool _isSaving = false;
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;

  SharedMedicineModel? get _existing => widget.existing;

  @override
  void initState() {
    super.initState();
    final existing = _existing;
    _profileFuture = _authService.getCurrentUserProfile();
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _usageController = TextEditingController(
      text: existing?.usageInstructions ?? '',
    );
    _dosageController = TextEditingController(text: existing?.dosage ?? '');
    _packageSizeController = TextEditingController(
      text: existing?.packageSize ?? '',
    );
    _priceController = TextEditingController(
      text: existing == null ? '' : existing.price.toStringAsFixed(0),
    );
    _category = existing?.category ?? 'Analgesics';
    _isAvailable = existing?.isAvailable ?? true;
    _requiresPrescription = existing?.requiresPrescription ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _usageController.dispose();
    _dosageController.dispose();
    _packageSizeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickGalleryImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (pickedFile == null) {
      return;
    }

    final bytes = await pickedFile.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _pickedImageBytes = bytes;
      _pickedImageName = pickedFile.name;
    });
  }

  Future<void> _saveMedicine() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final profile = await _profileFuture;
    if (profile == null || !profile.hasPharmacyProfile) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              ar: 'أكمل اسم الصيدلية وموقعها في الملف الشخصي أولاً قبل نشر الدواء.',
              en: 'Complete your pharmacy name and location in the profile first.',
            ),
          ),
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    final parsedPrice = double.tryParse(_priceController.text.trim());
    if (parsedPrice == null || parsedPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              ar: 'أدخل سعراً صحيحاً بالريال اليمني.',
              en: 'Please enter a valid Yemeni Riyal price.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final existing = _existing;
      late final SharedMedicineSaveResult saveResult;
      if (existing == null) {
        saveResult = await _sharedMedicineService.addSharedMedicine(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          usageInstructions: _usageController.text.trim(),
          dosage: _dosageController.text.trim(),
          packageSize: _packageSizeController.text.trim(),
          price: parsedPrice,
          category: _category,
          isAvailable: _isAvailable,
          requiresPrescription: _requiresPrescription,
          imageBytes: _pickedImageBytes,
          imageFileName: _pickedImageName,
        );
      } else {
        saveResult = await _sharedMedicineService.updateSharedMedicine(
          existing: existing,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          usageInstructions: _usageController.text.trim(),
          dosage: _dosageController.text.trim(),
          packageSize: _packageSizeController.text.trim(),
          price: parsedPrice,
          category: _category,
          isAvailable: _isAvailable,
          requiresPrescription: _requiresPrescription,
          imageBytes: _pickedImageBytes,
          imageFileName: _pickedImageName,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? context.tr(
                    ar: 'تم نشر الدواء بنجاح.',
                    en: 'Medicine published successfully.',
                  )
                : context.tr(
                    ar: 'تم تحديث بيانات الدواء بنجاح.',
                    en: 'Medicine details updated successfully.',
                  ),
          ),
        ),
      );

      if (saveResult.savedWithoutImage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                ar: 'تم الحفظ بدون صورة لأن Firebase Storage غير مفعل حالياً.',
                en: 'Saved without image because Firebase Storage is not enabled yet.',
              ),
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              ar: 'تعذر حفظ الدواء: $error',
              en: 'Unable to save medicine: $error',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _existing == null
        ? context.tr(ar: 'نشر دواء', en: 'Publish medicine')
        : context.tr(ar: 'تعديل الدواء', en: 'Edit medicine');

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: FutureBuilder<AppUserModel?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final profile = snapshot.data;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.maxSheetWidth,
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    children: [
                      _MedicineImagePickerCard(
                        pickedImageBytes: _pickedImageBytes,
                        networkImageUrl: _existing?.imageUrl,
                        onPickImage: _pickGalleryImage,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PharmacyProfileCard(profile: profile),
                      const SizedBox(height: AppSpacing.md),
                      DepthCard(
                        child: Column(
                          children: [
                            _EditorField(
                              controller: _nameController,
                              label: context.tr(
                                ar: 'اسم الدواء',
                                en: 'Medicine name',
                              ),
                              icon: Icons.medication_rounded,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _EditorField(
                              controller: _priceController,
                              label: context.tr(
                                ar: 'السعر بالريال اليمني',
                                en: 'Price in Yemeni Riyal',
                              ),
                              icon: Icons.payments_rounded,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _EditorField(
                              controller: _dosageController,
                              label: context.tr(
                                ar: 'الجرعة / التركيز',
                                en: 'Dosage / strength',
                              ),
                              icon: Icons.science_rounded,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _EditorField(
                              controller: _packageSizeController,
                              label: context.tr(
                                ar: 'حجم العبوة / الوحدات',
                                en: 'Pack size / units',
                              ),
                              icon: Icons.inventory_2_rounded,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            DropdownButtonFormField<String>(
                              initialValue: _category,
                              decoration: InputDecoration(
                                labelText: context.tr(
                                  ar: 'الفئة',
                                  en: 'Category',
                                ),
                                prefixIcon: const Icon(Icons.category_rounded),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'Analgesics',
                                  child: Text(
                                    context.tr(
                                      ar: 'مسكنات',
                                      en: 'Analgesics',
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Antibiotics',
                                  child: Text(
                                    context.tr(
                                      ar: 'مضادات حيوية',
                                      en: 'Antibiotics',
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Vitamins & supplements',
                                  child: Text(
                                    context.tr(
                                      ar: 'فيتامينات ومكملات',
                                      en: 'Vitamins & supplements',
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Respiratory',
                                  child: Text(
                                    context.tr(ar: 'تنفسي', en: 'Respiratory'),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Diabetes care',
                                  child: Text(
                                    context.tr(
                                      ar: 'رعاية السكري',
                                      en: 'Diabetes care',
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Dermatology',
                                  child: Text(
                                    context.tr(ar: 'جلدية', en: 'Dermatology'),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Other',
                                  child: Text(
                                    context.tr(ar: 'أخرى', en: 'Other'),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _category = value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DepthCard(
                        child: Column(
                          children: [
                            _EditorField(
                              controller: _descriptionController,
                              label: context.tr(
                                ar: 'الوصف',
                                en: 'Description',
                              ),
                              icon: Icons.description_rounded,
                              maxLines: 4,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _EditorField(
                              controller: _usageController,
                              label: context.tr(
                                ar: 'تعليمات الاستخدام',
                                en: 'Usage instructions',
                              ),
                              icon: Icons.rule_rounded,
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DepthCard(
                        child: Column(
                          children: [
                            SwitchListTile(
                              value: _isAvailable,
                              activeThumbColor: AppPalette.pharmacistPrimary,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                context.tr(
                                  ar: 'متوفر حالياً',
                                  en: 'Currently available',
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                context.tr(
                                  ar: 'يمكن للمرضى معرفة ما إذا كان هذا الدواء متوفراً الآن.',
                                  en: 'Patients can immediately see if this medicine is in stock.',
                                ),
                              ),
                              onChanged: (value) {
                                setState(() => _isAvailable = value);
                              },
                            ),
                            const Divider(),
                            SwitchListTile(
                              value: _requiresPrescription,
                              activeThumbColor: AppPalette.pharmacistPrimary,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                context.tr(
                                  ar: 'يتطلب وصفة طبية',
                                  en: 'Requires prescription',
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                context.tr(
                                  ar: 'يوضح أن المرضى يحتاجون إلى وصفة طبيب صالحة.',
                                  en: 'Indicates that patients need a valid doctor prescription.',
                                ),
                              ),
                              onChanged: (value) {
                                setState(() => _requiresPrescription = value);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveMedicine,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_rounded),
                        label: Text(
                          _isSaving
                              ? context.tr(ar: 'جارٍ الحفظ...', en: 'Saving...')
                              : _existing == null
                              ? context.tr(
                                  ar: 'نشر الدواء',
                                  en: 'Publish medicine',
                                )
                              : context.tr(
                                  ar: 'حفظ التعديلات',
                                  en: 'Save changes',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PharmacyProfileCard extends StatelessWidget {
  const _PharmacyProfileCard({required this.profile});

  final AppUserModel? profile;

  @override
  Widget build(BuildContext context) {
    final hasProfile = profile?.hasPharmacyProfile ?? false;

    return DepthCard(
      color: hasProfile ? Colors.white : const Color(0xFFFFF7E8),
      borderColor: hasProfile ? const Color(0xFFE4EAF3) : const Color(0xFFFFD89B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hasProfile
                      ? AppPalette.pharmacistPrimary.withValues(alpha: 0.10)
                      : AppPalette.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  hasProfile
                      ? Icons.storefront_rounded
                      : Icons.warning_amber_rounded,
                  color: hasProfile
                      ? AppPalette.pharmacistPrimary
                      : AppPalette.amber,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        ar: 'الملف الصيدلي الثابت',
                        en: 'Fixed pharmacy profile',
                      ),
                      style: const TextStyle(
                        fontSize: AppFontSize.sectionTitle,
                        fontWeight: FontWeight.w900,
                        color: AppPalette.text,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      hasProfile
                          ? context.tr(
                              ar: 'سيتم استخدام هذه البيانات تلقائياً في كل دواء جديد.',
                              en: 'These details will be reused automatically in every new medicine.',
                            )
                          : context.tr(
                              ar: 'أكمل الملف الصيدلي قبل النشر.',
                              en: 'Complete the pharmacy profile before publishing.',
                            ),
                      style: const TextStyle(
                        color: AppPalette.muted,
                        fontSize: AppFontSize.caption,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasProfile) ...[
            const SizedBox(height: AppSpacing.md),
            _ProfileLine(
              icon: Icons.person_outline_rounded,
              label: profile!.displayName,
            ),
            const SizedBox(height: AppSpacing.xs),
            _ProfileLine(
              icon: Icons.local_pharmacy_outlined,
              label: profile!.pharmacyName ?? '',
            ),
            const SizedBox(height: AppSpacing.xs),
            _ProfileLine(
              icon: Icons.location_on_outlined,
              label: profile!.pharmacyLocation ?? '',
            ),
            if ((profile!.pharmacyPhone ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              _ProfileLine(
                icon: Icons.phone_outlined,
                label: profile!.pharmacyPhone ?? '',
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppPalette.pharmacistPrimary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppPalette.text,
              fontSize: AppFontSize.body,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MedicineImagePickerCard extends StatelessWidget {
  const _MedicineImagePickerCard({
    required this.pickedImageBytes,
    required this.networkImageUrl,
    required this.onPickImage,
  });

  final Uint8List? pickedImageBytes;
  final String? networkImageUrl;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return DepthCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
            child: SizedBox(height: 220, child: _buildPreview()),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(ar: 'صورة الدواء', en: 'Medicine photo'),
                  style: const TextStyle(
                    fontSize: AppFontSize.sectionTitle,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.tr(
                    ar: 'اختر صورة واضحة للدواء من معرض الهاتف.',
                    en: 'Choose a clear product image from your mobile gallery.',
                  ),
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: AppFontSize.body,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: onPickImage,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: Text(
                    context.tr(
                      ar: 'اختر من المعرض',
                      en: 'Select from gallery',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (pickedImageBytes != null) {
      return Image.memory(pickedImageBytes!, fit: BoxFit.cover);
    }

    if (networkImageUrl != null && networkImageUrl!.isNotEmpty) {
      return Image.network(
        networkImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _emptyPreview(),
      );
    }

    return _emptyPreview();
  }

  Widget _emptyPreview() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF55D8B4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.add_photo_alternate_rounded,
          color: Colors.white,
          size: 72,
        ),
      ),
    );
  }
}

class _EditorField extends StatelessWidget {
  const _EditorField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return context.tr(
            ar: 'هذا الحقل مطلوب.',
            en: 'This field is required.',
          );
        }
        return null;
      },
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}

