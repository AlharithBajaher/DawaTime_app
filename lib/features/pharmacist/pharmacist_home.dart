import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/localization/app_localization.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/animated_welcome_banner.dart';
import '../../app/widgets/depth_card.dart';
import '../../app/widgets/home_navigation_chrome.dart';
import '../../app/widgets/profile_editor_sheet.dart';
import '../../app/widgets/profile_side_drawer.dart';
import '../../data/models/app_user_model.dart';
import '../../data/models/pharmacy_rating_model.dart';
import '../../data/models/pharmacy_task_model.dart';
import '../../data/models/shared_medicine_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/pharmacy_rating_service.dart';
import '../../data/services/pharmacy_service.dart';
import '../../data/services/shared_medicine_service.dart';
import '../settings/settings_page.dart';
import 'pharmacist_inventory_editor_page.dart';
import 'pharmacist_medicine_editor_page.dart';

part 'pharmacist_home_sections.dart';
part 'pharmacist_medicine_tab.dart';
part 'pharmacist_inventory_tab.dart';

const EdgeInsets _pharmacistPagePadding = EdgeInsets.fromLTRB(
  AppSpacing.lg,
  AppSpacing.xs,
  AppSpacing.lg,
  120,
);

class PharmacistHome extends StatefulWidget {
  const PharmacistHome({super.key});

  @override
  State<PharmacistHome> createState() => _PharmacistHomeState();
}

class _PharmacistHomeState extends State<PharmacistHome> {
  final AuthService _authService = AuthService();
  final PharmacyService _pharmacyService = PharmacyService();
  final PharmacyRatingService _pharmacyRatingService = PharmacyRatingService();
  final SharedMedicineService _sharedMedicineService = SharedMedicineService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  bool _hasWelcomedUser = false;
  bool _welcomeBannerVisible = false;
  String _welcomeDisplayName = '';

  Stream<AppUserModel?> _watchCurrentProfile() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Stream<AppUserModel?>.value(null);
    }

    return _authService.watchUserProfile(uid);
  }

  String _fallbackPharmacistName(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final fallback = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .trim();
    return fallback.isEmpty
        ? context.tr(ar: 'صيدلي', en: 'Pharmacist')
        : fallback;
  }

  void _syncWelcomeBanner(String displayName) {
    if (_hasWelcomedUser) {
      return;
    }

    _hasWelcomedUser = true;
    _welcomeDisplayName = displayName.trim().isEmpty
        ? context.tr(ar: 'صيدلي', en: 'Pharmacist')
        : displayName;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      setState(() => _welcomeBannerVisible = true);
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _welcomeBannerVisible = false);
        }
      });
    });
  }

  Future<void> _openTaskEditor([PharmacyTaskModel? task]) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PharmacistInventoryEditorPage(existing: task),
      ),
    );
  }

  Future<void> _deleteTask(PharmacyTaskModel task) async {
    try {
      await _pharmacyService.deleteTask(task.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              ar: 'تعذر حذف عنصر المخزون: $error',
              en: 'Unable to delete inventory item: $error',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openMedicineEditor([SharedMedicineModel? medicine]) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PharmacistMedicineEditorPage(existing: medicine),
      ),
    );
  }

  Future<void> _toggleMedicineAvailability(
    SharedMedicineModel medicine,
    bool isAvailable,
  ) async {
    try {
      await _sharedMedicineService.updateAvailability(
        medicine: medicine,
        isAvailable: isAvailable,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              ar: 'تعذر تحديث حالة التوفر: $error',
              en: 'Unable to update availability: $error',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _deleteMedicineListing(SharedMedicineModel medicine) async {
    try {
      await _sharedMedicineService.deleteSharedMedicine(medicine);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              ar: 'تعذر حذف الدواء: $error',
              en: 'Unable to delete medicine: $error',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _saveCurrentProfile({
    required String name,
    required String username,
    String? pharmacyName,
    String? pharmacyLocation,
    String? pharmacyPhone,
    String? photoUrl,
  }) async {
    await _authService.updateCurrentUserProfile(
      name: name,
      username: username,
      pharmacyName: pharmacyName,
      pharmacyLocation: pharmacyLocation,
      pharmacyPhone: pharmacyPhone,
      photoUrl: photoUrl,
    );
  }

  Future<void> _openProfileEditor({
    required AppUserModel? profile,
    required String displayName,
    required String email,
  }) async {
    await showProfileEditorSheet(
      context: context,
      profile: profile,
      fallbackName: displayName,
      fallbackEmail: email,
      roleLabel: context.tr(ar: 'صيدلي', en: 'Pharmacist'),
      accentColor: AppPalette.pharmacistPrimary,
      showPharmacyFields: true,
      onSaveProfile: _saveCurrentProfile,
      onUploadPhoto: (bytes) => _authService.uploadProfileImage(bytes),
    );
  }

  void _openSettingsFromDrawer() {
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  PharmacyRatingSummary _buildRatingSummary(List<PharmacyRatingModel> ratings) {
    if (ratings.isEmpty) {
      return const PharmacyRatingSummary(average: 0, count: 0);
    }

    final total = ratings.fold<int>(
      0,
      (runningTotal, rating) => runningTotal + rating.rating,
    );
    return PharmacyRatingSummary(
      average: total / ratings.length,
      count: ratings.length,
    );
  }

  Widget _buildPage(
    List<PharmacyTaskModel> tasks,
    List<SharedMedicineModel> sharedMedicines,
    List<PharmacyRatingModel> ratings,
    PharmacyRatingSummary ratingSummary,
    int active,
    int urgent,
    int completed,
    AppUserModel? profile,
    String fallbackEmail,
  ) {
    final pages = [
      _PharmacistMedicineTab(
        medicines: sharedMedicines,
        ratingSummary: ratingSummary,
        onCreateMedicine: _openMedicineEditor,
        onEditMedicine: _openMedicineEditor,
        onToggleAvailability: _toggleMedicineAvailability,
        onDeleteMedicine: _deleteMedicineListing,
      ),
      _WorkflowTabModern(
        tasks: tasks,
        onToggle: _pharmacyService.toggleTask,
        onAdjust: (task, delta) =>
            _pharmacyService.adjustStock(task: task, delta: delta),
        onEdit: _openTaskEditor,
        onDelete: _deleteTask,
      ),
      _PharmacistOverviewTab(
        active: active,
        urgent: urgent,
        completed: completed,
        tasks: tasks,
        ratings: ratings,
        ratingSummary: ratingSummary,
        onCreateTask: _openTaskEditor,
      ),
      _InsightsTab(tasks: tasks),
      _ModernPharmacistAccountTab(
        email: profile?.email ?? fallbackEmail,
        displayName: profile?.displayName ?? _fallbackPharmacistName(context),
        ratingSummary: ratingSummary,
        onEditProfile: () => _openProfileEditor(
          profile: profile,
          displayName: profile?.displayName ?? _fallbackPharmacistName(context),
          email: profile?.email ?? fallbackEmail,
        ),
        onSignOut: _authService.signOut,
      ),
    ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey(_selectedIndex),
        child: pages[_selectedIndex],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_selectedIndex == 4) {
      return null;
    }

    final label = _selectedIndex == 0
        ? context.tr(ar: 'نشر دواء', en: 'Publish')
        : context.tr(ar: 'عنصر مخزون', en: 'Inventory item');

    final icon = _selectedIndex == 0
        ? Icons.add_photo_alternate_rounded
        : Icons.playlist_add_rounded;

    return SizedBox(
      height: 52,
      child: FloatingActionButton.extended(
        backgroundColor: AppPalette.pharmacistPrimary,
        foregroundColor: Colors.white,
        extendedPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        extendedIconLabelSpacing: AppSpacing.xs,
        elevation: 8,
        onPressed: _selectedIndex == 0
            ? _openMedicineEditor
            : _openTaskEditor,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: AppFontSize.body,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUserModel?>(
      stream: _watchCurrentProfile(),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;
        final displayName =
            profile?.displayName ?? _fallbackPharmacistName(context);
        final email =
            profile?.email ??
            FirebaseAuth.instance.currentUser?.email ??
            'pharmacist@dawatime.app';

        _syncWelcomeBanner(displayName);

        return StreamBuilder<List<PharmacyTaskModel>>(
          stream: _pharmacyService.watchTasks(),
          builder: (context, snapshot) {
            final tasks = snapshot.data ?? const <PharmacyTaskModel>[];
            final active = tasks.where((task) => !task.isOutOfStock).length;
            final urgent = tasks.where((task) => task.isLowStock).length;
            final completed = tasks.where((task) => task.isOutOfStock).length;

            return StreamBuilder<List<SharedMedicineModel>>(
              stream: _sharedMedicineService.watchMyPublishedMedicines(),
              builder: (context, medicineSnapshot) {
                final sharedMedicines =
                    medicineSnapshot.data ?? const <SharedMedicineModel>[];
                final pharmacistId = FirebaseAuth.instance.currentUser?.uid;

                return StreamBuilder<List<PharmacyRatingModel>>(
                  stream: pharmacistId == null
                      ? Stream<List<PharmacyRatingModel>>.value(
                          const <PharmacyRatingModel>[],
                        )
                      : _pharmacyRatingService.watchRatingsForPharmacist(
                          pharmacistId,
                        ),
                  builder: (context, ratingSnapshot) {
                    final ratings =
                        ratingSnapshot.data ?? const <PharmacyRatingModel>[];
                    final ratingSummary = _buildRatingSummary(ratings);
                    final hasDataWarning =
                        snapshot.hasError ||
                        medicineSnapshot.hasError ||
                        ratingSnapshot.hasError ||
                        profileSnapshot.hasError;

                    return Scaffold(
                      key: _scaffoldKey,
                      extendBody: true,
                      drawer: ProfileSideDrawer(
                        profile: profile,
                        fallbackName: displayName,
                        fallbackEmail: email,
                        roleLabel: context.tr(ar: 'صيدلي', en: 'Pharmacist'),
                        accentColor: AppPalette.pharmacistPrimary,
                        onOpenSettings: _openSettingsFromDrawer,
                        onEditProfile: () => _openProfileEditor(
                          profile: profile,
                          displayName: displayName,
                          email: email,
                        ),
                        onSignOut: _authService.signOut,
                      ),
                      floatingActionButton: _buildFloatingActionButton(),
                      bottomNavigationBar: AnimatedHomeBottomBar(
                        selectedIndex: _selectedIndex,
                        activeColor: AppPalette.pharmacistPrimary,
                        horizontalInset: AppSpacing.sm,
                        onDestinationSelected: (index) {
                          setState(() => _selectedIndex = index);
                        },
                        items: [
                          HomeBottomBarItem(
                            icon: Icons.storefront_outlined,
                            selectedIcon: Icons.storefront_rounded,
                            label: context.tr(ar: 'الأدوية', en: 'Medicines'),
                          ),
                          HomeBottomBarItem(
                            icon: Icons.fact_check_outlined,
                            selectedIcon: Icons.fact_check_rounded,
                            label: context.tr(ar: 'المخزون', en: 'Inventory'),
                          ),
                          HomeBottomBarItem(
                            icon: Icons.dashboard_outlined,
                            selectedIcon: Icons.dashboard_rounded,
                            label: context.t(AppText.dashboard),
                          ),
                          HomeBottomBarItem(
                            icon: Icons.insights_outlined,
                            selectedIcon: Icons.insights_rounded,
                            label: context.t(AppText.insights),
                          ),
                          HomeBottomBarItem(
                            icon: Icons.person_outline_rounded,
                            selectedIcon: Icons.person_rounded,
                            label: context.t(AppText.account),
                          ),
                        ],
                      ),
                      body: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFF5FBFA), Color(0xFFE3F5F1)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: SafeArea(
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  Builder(
                                    builder: (context) {
                                      return HomeTopActionBar(
                                        profile: profile,
                                        fallbackName: displayName,
                                        roleLabel: context.tr(
                                          ar: 'لوحة تشغيل الصيدلية',
                                          en: 'Pharmacy control room',
                                        ),
                                        accentColors: const [
                                          AppPalette.pharmacistPrimary,
                                          AppPalette.pharmacistAccent,
                                        ],
                                        trailingIcon:
                                            Icons.local_pharmacy_rounded,
                                        onMenuPressed: () => _scaffoldKey
                                            .currentState
                                            ?.openDrawer(),
                                      );
                                    },
                                  ),
                                  if (hasDataWarning)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        AppSpacing.lg,
                                        AppSpacing.sm,
                                        AppSpacing.lg,
                                        0,
                                      ),
                                      child: DepthCard(
                                        color: const Color(0xFFFFF4E5),
                                        borderColor: const Color(0xFFFFDCA8),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.warning_amber_rounded,
                                              color: AppPalette.amber,
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),
                                            Expanded(
                                              child: Text(
                                                context.tr(
                                                  ar: 'تعذر تحميل بعض بيانات الصيدلية حالياً، لكن اللوحة ستبقى متاحة.',
                                                  en: 'Some pharmacy data could not be loaded right now, but the dashboard remains available.',
                                                ),
                                                style: const TextStyle(
                                                  color: AppPalette.text,
                                                  fontSize: AppFontSize.body,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: AppLayout.maxContentWidth,
                                        ),
                                        child: _buildPage(
                                          tasks,
                                          sharedMedicines,
                                          ratings,
                                          ratingSummary,
                                          active,
                                          urgent,
                                          completed,
                                          profile,
                                          email,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              AnimatedWelcomeBanner(
                                visible: _welcomeBannerVisible,
                                displayName: _welcomeDisplayName,
                                accentColor: AppPalette.pharmacistPrimary,
                                icon: Icons.auto_awesome_rounded,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
