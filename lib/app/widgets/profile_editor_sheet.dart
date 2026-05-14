import 'package:flutter/material.dart';

import '../../data/models/app_user_model.dart';
import '../localization/app_localization.dart';
import '../theme/app_metrics.dart';
import '../theme/app_theme.dart';
import 'depth_card.dart';

Future<void> showProfileEditorSheet({
  required BuildContext context,
  required AppUserModel? profile,
  required String fallbackName,
  required String fallbackEmail,
  required String roleLabel,
  required Color accentColor,
  required bool showPharmacyFields,
  required Future<void> Function({
    required String name,
    required String username,
    String? pharmacyName,
    String? pharmacyLocation,
    String? pharmacyPhone,
  })
  onSaveProfile,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProfileEditorSheet(
      profile: profile,
      fallbackName: fallbackName,
      fallbackEmail: fallbackEmail,
      roleLabel: roleLabel,
      accentColor: accentColor,
      showPharmacyFields: showPharmacyFields,
      onSaveProfile: onSaveProfile,
    ),
  );
}

class ProfileEditorSheet extends StatefulWidget {
  const ProfileEditorSheet({
    super.key,
    required this.profile,
    required this.fallbackName,
    required this.fallbackEmail,
    required this.roleLabel,
    required this.accentColor,
    required this.showPharmacyFields,
    required this.onSaveProfile,
  });

  final AppUserModel? profile;
  final String fallbackName;
  final String fallbackEmail;
  final String roleLabel;
  final Color accentColor;
  final bool showPharmacyFields;
  final Future<void> Function({
    required String name,
    required String username,
    String? pharmacyName,
    String? pharmacyLocation,
    String? pharmacyPhone,
  })
  onSaveProfile;

  @override
  State<ProfileEditorSheet> createState() => _ProfileEditorSheetState();
}

class _ProfileEditorSheetState extends State<ProfileEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _pharmacyNameController;
  late final TextEditingController _pharmacyLocationController;
  late final TextEditingController _pharmacyPhoneController;
  bool _isSaving = false;

  String get _resolvedName =>
      widget.profile?.displayName.trim().isNotEmpty == true
      ? widget.profile!.displayName
      : widget.fallbackName;

  String get _resolvedUsername => widget.profile?.username.trim().isNotEmpty == true
      ? widget.profile!.username
      : _resolvedName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');

  String get _resolvedEmail => widget.profile?.email ?? widget.fallbackEmail;

  String get _resolvedInitials {
    final initials = widget.profile?.initials;
    if (initials != null && initials.isNotEmpty) {
      return initials;
    }

    final source = _resolvedName.trim();
    if (source.isEmpty) {
      return 'DU';
    }

    return String.fromCharCode(source.runes.first).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _resolvedName);
    _usernameController = TextEditingController(text: _resolvedUsername);
    _pharmacyNameController = TextEditingController(
      text: widget.profile?.pharmacyName ?? '',
    );
    _pharmacyLocationController = TextEditingController(
      text: widget.profile?.pharmacyLocation ?? '',
    );
    _pharmacyPhoneController = TextEditingController(
      text: widget.profile?.pharmacyPhone ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _pharmacyNameController.dispose();
    _pharmacyLocationController.dispose();
    _pharmacyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSaveProfile(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        pharmacyName: widget.showPharmacyFields
            ? _pharmacyNameController.text.trim()
            : null,
        pharmacyLocation: widget.showPharmacyFields
            ? _pharmacyLocationController.text.trim()
            : null,
        pharmacyPhone: widget.showPharmacyFields
            ? _pharmacyPhoneController.text.trim()
            : null,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                ar: 'تم تحديث الملف الشخصي بنجاح.',
                en: 'Profile updated successfully.',
              ),
            ),
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                ar: 'تعذر تحديث الملف الشخصي: $error',
                en: 'Unable to update profile: $error',
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
    final photoUrl = widget.profile?.photoUrl;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.64,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4F6FB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppPalette.muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DepthCard(
                gradient: LinearGradient(
                  colors: [
                    widget.accentColor,
                    widget.accentColor.withValues(alpha: 0.72),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderColor: Colors.white.withValues(alpha: 0.18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white24,
                          backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl == null || photoUrl.isEmpty
                              ? Text(
                                  _resolvedInitials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: AppFontSize.sectionTitle,
                                    fontWeight: FontWeight.w900,
                                  ),
                                )
                              : null,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _resolvedName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppFontSize.pageTitle,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _resolvedEmail,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: AppFontSize.body,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        widget.roleLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppFontSize.caption,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
                      context.tr(ar: 'تعديل الملف الشخصي', en: 'Edit profile'),
                      style: const TextStyle(
                        color: AppPalette.text,
                        fontSize: AppFontSize.sectionTitle,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: context.tr(ar: 'الاسم الكامل', en: 'Full name'),
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: context.tr(ar: 'اسم المستخدم', en: 'Username'),
                        prefixIcon: const Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                    if (widget.showPharmacyFields) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _pharmacyNameController,
                        decoration: InputDecoration(
                          labelText: context.tr(
                            ar: 'اسم الصيدلية',
                            en: 'Pharmacy name',
                          ),
                          prefixIcon: const Icon(Icons.local_pharmacy_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _pharmacyLocationController,
                        decoration: InputDecoration(
                          labelText: context.tr(
                            ar: 'موقع الصيدلية',
                            en: 'Pharmacy location',
                          ),
                          prefixIcon: const Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _pharmacyPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: context.tr(ar: 'رقم التواصل', en: 'Contact phone'),
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.tr(
                          ar: 'سيتم استخدام هذه البيانات تلقائياً في كل دواء تنشره.',
                          en: 'These details will be reused automatically in every published medicine.',
                        ),
                        style: const TextStyle(
                          color: AppPalette.muted,
                          fontSize: AppFontSize.caption,
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveProfile,
                        icon: Icon(
                          _isSaving
                              ? Icons.hourglass_bottom_rounded
                              : Icons.save_rounded,
                        ),
                        label: Text(
                          _isSaving
                              ? context.tr(ar: 'جارٍ الحفظ', en: 'Saving')
                              : context.tr(ar: 'حفظ التعديلات', en: 'Save changes'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
