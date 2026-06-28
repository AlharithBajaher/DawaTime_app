import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization/app_localization.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/animated_welcome_banner.dart';
import '../../app/widgets/depth_card.dart';
import '../../app/widgets/home_navigation_chrome.dart';
import '../../app/widgets/profile_editor_sheet.dart';
import '../../app/widgets/profile_side_drawer.dart';
import '../../data/models/app_user_model.dart';
import '../../data/models/password_reset_request_model.dart';
import '../../data/services/admin_notification_service.dart';
import '../../data/services/auth_service.dart';
import '../settings/settings_page.dart';

part 'admin_home_sections.dart';

enum _AdminSection {
  dashboard,
  requests,
  pharmacists,
  patients,
  access,
}

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final AuthService _authService = AuthService();
  final AdminNotificationService _notificationService =
      AdminNotificationService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<AppUserModel> _cachedUsers = const <AppUserModel>[];
  bool _hasWelcomedAdmin = false;
  bool _welcomeBannerVisible = false;
  String _welcomeDisplayName = '';
  _AdminSection _currentSection = _AdminSection.dashboard;
  final Map<_AdminSection, int> _visibleCounts = {
    _AdminSection.requests: 6,
    _AdminSection.pharmacists: 6,
    _AdminSection.patients: 8,
    _AdminSection.access: 6,
  };


  String _tr({required String ar, required String en}) =>
      context.tr(ar: ar, en: en);

  void _showStatusMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _updateCachedApproval(String userId, String approvalStatus) {
    _cachedUsers = _cachedUsers
        .map(
          (user) => user.uid == userId
              ? user.copyWith(approvalStatus: approvalStatus)
              : user,
        )
        .toList(growable: false);
  }

  int _visibleCount(_AdminSection section) =>
      _visibleCounts[section] ?? 6;

  void _showMore(_AdminSection section) {
    setState(() {
      _visibleCounts[section] = (_visibleCounts[section] ?? 6) + 6;
    });
  }

  AppUserModel? _cachedAdminProfile(String uid) {
    for (final user in _cachedUsers) {
      if (user.uid == uid) {
        return user;
      }
    }
    return null;
  }

  Future<void> _handleApprovalChange({
    required AppUserModel user,
    required String approvalStatus,
    required String adminUid,
  }) async {
    try {
      await _authService.updatePharmacistApproval(
        userId: user.uid,
        approvalStatus: approvalStatus,
        adminUid: adminUid,
      );
      setState(() {
        _updateCachedApproval(user.uid, approvalStatus);
      });
      _showStatusMessage(
        approvalStatus == 'approved'
            ? _tr(
                ar: 'تمت الموافقة على حساب الصيدلي بنجاح.',
                en: 'The pharmacist account was approved successfully.',
              )
            : _tr(
                ar: 'تم تحديث حالة حساب الصيدلي.',
                en: 'The pharmacist account status was updated.',
              ),
      );
    } catch (error) {
      _showStatusMessage(
        _tr(
          ar: 'تعذر تحديث حالة الحساب: $error',
          en: 'The account status could not be updated: $error',
        ),
      );
    }
  }

  Future<void> _issueResetAccessCode({
    required PasswordResetRequestModel request,
    required String adminUid,
  }) async {
    try {
      final code = await _authService.issuePasswordResetCode(
        requestId: request.id,
        adminUid: adminUid,
      );
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              _tr(
                ar: 'رمز الوصول لإعادة تعيين كلمة المرور',
                en: 'Password reset access code',
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr(
                    ar: 'شارك هذا الرمز مع المستخدم على البريد: ${request.email}',
                    en: 'Share this code with the user at: ${request.email}',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SelectableText(
                  code,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: AppPalette.adminPrimary,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (mounted) {
                    _showStatusMessage(
                      _tr(ar: 'تم نسخ الرمز.', en: 'Code copied.'),
                    );
                  }
                },
                icon: const Icon(Icons.copy_rounded),
                label: Text(_tr(ar: 'نسخ', en: 'Copy')),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(_tr(ar: 'إغلاق', en: 'Close')),
              ),
            ],
          );
        },
      );
    } catch (error) {
      _showStatusMessage(
        _tr(
          ar: 'تعذر إصدار رمز الوصول: $error',
          en: 'Could not issue access code: $error',
        ),
      );
    }
  }

  void _showWelcome(String adminName) {
    if (_hasWelcomedAdmin) {
      return;
    }

    _hasWelcomedAdmin = true;
    _welcomeDisplayName = adminName;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              ar: 'مرحبًا بعودتك، $adminName',
              en: 'Welcome back, $adminName',
            ),
          ),
        ),
      );
    });
  }

  void _showNotificationsPanel() {
    _notificationService.markNotificationsSeen();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      0,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_rounded,
                            color: AppPalette.adminPrimary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _tr(
                            ar: 'التسجيلات الجديدة',
                            en: 'New registrations',
                          ),
                          style: const TextStyle(
                            fontSize: AppFontSize.title,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: StreamBuilder<
                        UnmodifiableListView<AdminNotificationItem>>(
                      stream: _notificationService.watchNewRegistrations(),
                      builder: (context, snapshot) {
                        final items = snapshot.data;
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              _tr(
                                ar: 'حدث خطأ في تحميل الإشعارات',
                                en: 'Error loading notifications',
                              ),
                            ),
                          );
                        }
                        if (items == null || items.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.notifications_none_rounded,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  _tr(
                                    ar: 'لا توجد تسجيلات جديدة',
                                    en: 'No new registrations',
                                  ),
                                  style: const TextStyle(
                                    color: AppPalette.muted,
                                    fontSize: AppFontSize.body,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (_, index) {
                            final item = items[index];
                            final isPharmacist =
                                item.role == 'pharmacist';
                            final isPending =
                                item.approvalStatus == 'pending';
                            return Container(
                              decoration: BoxDecoration(
                                color: item.isRead
                                    ? Colors.white
                                    : AppPalette.adminPrimary
                                        .withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                                border: Border.all(
                                  color: item.isRead
                                      ? Colors.grey.withValues(alpha: 0.15)
                                      : AppPalette.adminPrimary
                                          .withValues(alpha: 0.25),
                                ),
                              ),
                              padding: const EdgeInsets.all(
                                AppSpacing.md,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: isPharmacist
                                        ? AppPalette.amber
                                            .withValues(alpha: 0.15)
                                        : AppPalette.patientPrimary
                                            .withValues(alpha: 0.15),
                                    child: Icon(
                                      isPharmacist
                                          ? Icons.local_pharmacy_rounded
                                          : Icons.person_rounded,
                                      color: isPharmacist
                                          ? AppPalette.amber
                                          : AppPalette.patientPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: AppFontSize.body,
                                          ),
                                        ),
                                        const SizedBox(
                                            height: AppSpacing.xxs),
                                        Text(
                                          item.email,
                                          style: TextStyle(
                                            color: AppPalette.muted,
                                            fontSize:
                                                AppFontSize.caption,
                                          ),
                                        ),
                                        const SizedBox(
                                            height: AppSpacing.xxs),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                horizontal: AppSpacing
                                                    .xs,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isPharmacist
                                                    ? AppPalette.amber
                                                        .withValues(
                                                            alpha: 0.12)
                                                    : AppPalette
                                                        .patientPrimary
                                                        .withValues(
                                                            alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  AppRadius.pill,
                                                ),
                                              ),
                                              child: Text(
                                                item.roleLabel,
                                                style: TextStyle(
                                                  fontSize: AppFontSize
                                                      .caption,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  color: isPharmacist
                                                      ? AppPalette.amber
                                                      : AppPalette
                                                          .patientPrimary,
                                                ),
                                              ),
                                            ),
                                            if (isPending) ...[
                                              const SizedBox(
                                                  width: AppSpacing.xs),
                                              Container(
                                                padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                  horizontal:
                                                      AppSpacing.xs,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppPalette
                                                      .coral
                                                      .withValues(
                                                          alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                    AppRadius.pill,
                                                  ),
                                                ),
                                                child: Text(
                                                  _tr(
                                                    ar: 'بانتظار الموافقة',
                                                    en: 'Awaiting approval',
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize:
                                                        AppFontSize
                                                            .caption,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    color:
                                                        AppPalette.coral,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isPharmacist && isPending)
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(sheetContext);
                                        setState(() {
                                          _currentSection =
                                              _AdminSection.requests;
                                        });
                                      },
                                      child: Text(
                                        _tr(
                                          ar: 'اعتماد',
                                          en: 'Approve',
                                        ),
                                        style: const TextStyle(
                                          color:
                                              AppPalette.adminPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
      roleLabel: _tr(ar: 'مسؤول المنصة', en: 'Platform administrator'),
      accentColor: AppPalette.adminPrimary,
      showPharmacyFields: false,
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

  String _sectionTitle(_AdminSection section) {
    switch (section) {
      case _AdminSection.dashboard:
        return _tr(ar: 'الرئيسية', en: 'Admin home');
      case _AdminSection.requests:
        return _tr(ar: 'الطلبات والموافقات', en: 'Requests & approvals');
      case _AdminSection.pharmacists:
        return _tr(ar: 'الصيادلة المعتمدون', en: 'Approved pharmacists');
      case _AdminSection.patients:
        return _tr(ar: 'حسابات المرضى', en: 'Patient accounts');
      case _AdminSection.access:
        return _tr(ar: 'التحكم والصلاحيات', en: 'Control & access');
    }
  }

  String _sectionSubtitle(_AdminSection section) {
    switch (section) {
      case _AdminSection.dashboard:
        return _tr(
          ar: 'عرض بصري سريع لحالة المنصة مع انتقال واضح إلى كل صفحة تشغيلية.',
          en: 'A visual snapshot of platform health with clear handoff to each operational page.',
        );
      case _AdminSection.requests:
        return _tr(
          ar: 'مراجعة موافقات الصيادلة وطلبات إعادة تعيين كلمة المرور من مساحة عمل واحدة.',
          en: 'Review pharmacist approvals and password reset requests from one clean workspace.',
        );
      case _AdminSection.pharmacists:
        return _tr(
          ar: 'متابعة حسابات الصيادلة المعتمدة وإدارة حالة الوصول مباشرة.',
          en: 'Track approved pharmacist accounts and manage access state directly.',
        );
      case _AdminSection.patients:
        return _tr(
          ar: 'صفحة واضحة لاستعراض حسابات المرضى وبياناتهم الأساسية.',
          en: 'A clear page for browsing patient accounts and their basic details.',
        );
      case _AdminSection.access:
        return _tr(
          ar: 'إدارة حسابات المسؤولين والحسابات المرفوضة من صفحة تحكم واحدة.',
          en: 'Manage admin accounts and rejected accounts in one control page.',
        );
    }
  }

  IconData _sectionIcon(_AdminSection section) {
    switch (section) {
      case _AdminSection.dashboard:
        return Icons.auto_awesome_rounded;
      case _AdminSection.requests:
        return Icons.pending_actions_rounded;
      case _AdminSection.pharmacists:
        return Icons.local_pharmacy_rounded;
      case _AdminSection.patients:
        return Icons.people_alt_rounded;
      case _AdminSection.access:
        return Icons.admin_panel_settings_rounded;
    }
  }

  String _normalizedRole(AppUserModel user) {
    final role = user.role.trim().toLowerCase();
    switch (role) {
      case 'pharmacist':
      case 'pharmacy':
      case 'صيدلي':
      case 'صيدلية':
        return 'pharmacist';
      case 'patient':
      case 'user':
      case 'مريض':
        return 'patient';
      case 'admin':
      case 'إداري':
      case 'ادمن':
      case 'أدمن':
        return 'admin';
      default:
        return role;
    }
  }

  String _normalizedApproval(AppUserModel user) {
    final status = user.approvalStatus.trim().toLowerCase();
    switch (status) {
      case 'approved':
      case 'معتمد':
      case 'مقبول':
        return 'approved';
      case 'pending':
      case 'معلق':
      case 'قيد المراجعة':
        return 'pending';
      case 'rejected':
      case 'مرفوض':
        return 'rejected';
      default:
        return status;
    }
  }

  bool _hasPharmacyDetails(AppUserModel user) {
    return (user.pharmacyName ?? '').trim().isNotEmpty ||
        (user.pharmacyLocation ?? '').trim().isNotEmpty ||
        (user.pharmacyPhone ?? '').trim().isNotEmpty;
  }

  bool _isLikelyPharmacist(AppUserModel user) {
    final role = _normalizedRole(user);
    if (role == 'pharmacist') {
      return true;
    }
    final approval = _normalizedApproval(user);
    if (approval == 'pending' || approval == 'rejected') {
      return true;
    }
    return _hasPharmacyDetails(user);
  }

  bool _isLikelyPatient(AppUserModel user) {
    if (_isLikelyAdmin(user) || _isLikelyPharmacist(user)) {
      return false;
    }
    return true;
  }

  bool _isLikelyAdmin(AppUserModel user) {
    final role = _normalizedRole(user);
    return role == 'admin';
  }

  Widget _buildOverviewSection({
    required List<AppUserModel> pending,
    required List<AppUserModel> approved,
    required List<AppUserModel> patients,
    required List<AppUserModel> admins,
    required List<AppUserModel> rejected,
  }) {
    return Column(
      children: [
        _AdminHighlightCard(
          title: _tr(
            ar: 'ملخص لوحة اليوم',
            en: 'Today dashboard summary',
          ),
          subtitle: _tr(
            ar: 'راجع حالة المنصة بسرعة، ثم افتح أي قسم لمتابعة الإشراف والإدارة.',
            en: 'Review platform status at a glance, then open any section to continue moderation and management.',
          ),
          children: [
            _QuickInsightTile(
              icon: Icons.pending_actions_rounded,
              color: AppPalette.amber,
              label: _tr(ar: 'طلبات معلقة', en: 'Pending requests'),
              value: '${pending.length}',
            ),
            _QuickInsightTile(
              icon: Icons.local_pharmacy_rounded,
              color: AppPalette.success,
              label: _tr(ar: 'صيادلة معتمدون', en: 'Approved pharmacists'),
              value: '${approved.length}',
            ),
            _QuickInsightTile(
              icon: Icons.people_alt_rounded,
              color: AppPalette.patientPrimary,
              label: _tr(ar: 'المرضى', en: 'Patients'),
              value: '${patients.length}',
            ),
            _QuickInsightTile(
              icon: Icons.admin_panel_settings_rounded,
              color: AppPalette.adminPrimary,
              label: _tr(ar: 'المسؤولون', en: 'Admins'),
              value: '${admins.length}',
            ),
            _QuickInsightTile(
              icon: Icons.block_rounded,
              color: AppPalette.coral,
              label: _tr(ar: 'المرفوضون', en: 'Rejected'),
              value: '${rejected.length}',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _AdminHintCard(
          icon: Icons.tips_and_updates_rounded,
          title: _tr(ar: 'تنظيم أفضل', en: 'Better organization'),
          message: _tr(
          ar: 'تم تقسيم صفحة الإدارة إلى أقسام واضحة للصيادلة والمرضى والمسؤولين والطلبات والحسابات المرفوضة مع خيار عرض المزيد عند الحاجة.',
          en: 'The admin area is now split into dedicated sections for pharmacists, patients, admins, requests, and rejected accounts with a load-more flow when needed.',
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsSection({
    required List<AppUserModel> pending,
    required String adminUid,
  }) {
    final visiblePending = pending.take(_visibleCount(_AdminSection.requests));

    return Column(
      children: [
        _AdminContentCard(
          title: _tr(
            ar: 'طلبات الصيادلة المعلقة',
            en: 'Pending pharmacist requests',
          ),
          subtitle: _tr(
            ar: 'اعتمد أو ارفض حسابات الصيادلة قبل دخولهم لوحة الصيدلي.',
            en: 'Approve or reject pharmacist accounts before they enter the pharmacist dashboard.',
          ),
          child: pending.isEmpty
              ? _EmptyPanel(
                  message: _tr(
                    ar: 'لا توجد طلبات صيادلة معلقة حاليًا.',
                    en: 'There are no pending pharmacist requests right now.',
                  ),
                )
              : Column(
                  children: [
                    ...visiblePending.map(
                      (user) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _AdminUserTile(
                          user: user,
                          badgeColor: AppPalette.amber,
                          badgeLabel: _tr(ar: 'معلق', en: 'Pending'),
                          primaryActionLabel: _tr(ar: 'اعتماد', en: 'Approve'),
                          secondaryActionLabel: _tr(ar: 'رفض', en: 'Reject'),
                          onPrimaryAction: () async {
                            await _handleApprovalChange(
                              user: user,
                              approvalStatus: 'approved',
                              adminUid: adminUid,
                            );
                          },
                          onSecondaryAction: () async {
                            await _handleApprovalChange(
                              user: user,
                              approvalStatus: 'rejected',
                              adminUid: adminUid,
                            );
                          },
                        ),
                      ),
                    ),
                    if (pending.length > _visibleCount(_AdminSection.requests))
                      _LoadMoreButton(
                        label: _tr(ar: 'عرض المزيد', en: 'Load more'),
                        onTap: () => _showMore(_AdminSection.requests),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        _AdminContentCard(
          title: _tr(
            ar: 'طلبات إعادة تعيين كلمة المرور',
            en: 'Password reset requests',
          ),
          subtitle: _tr(
            ar: 'راجع الطلبات وأصدر رمز وصول مؤقت لكل مستخدم يحتاج استعادة كلمة المرور.',
            en: 'Review requests and issue a temporary access code for each user who needs password reset access.',
          ),
          child: StreamBuilder<List<PasswordResetRequestModel>>(
            stream: _authService.watchPasswordResetRequests(),
            builder: (context, snapshot) {
              final requests =
                  snapshot.data ?? const <PasswordResetRequestModel>[];
              final actionable = requests
                  .where((request) => request.isPending || request.isCodeSent)
                  .toList(growable: false);

              if (actionable.isEmpty) {
                return _EmptyPanel(
                  message: _tr(
                    ar: 'لا توجد طلبات إعادة تعيين كلمة المرور حاليًا.',
                    en: 'There are no password reset requests right now.',
                  ),
                );
              }

              return Column(
                children: actionable
                    .take(6)
                    .map(
                      (request) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _PasswordResetRequestTile(
                          request: request,
                          onIssueCode: () async {
                            await _issueResetAccessCode(
                              request: request,
                              adminUid: adminUid,
                            );
                          },
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsersSection({
    required _AdminSection section,
    required List<AppUserModel> users,
    required String title,
    required String subtitle,
    required String badgeLabel,
    required Color badgeColor,
    String? searchButtonLabel,
    VoidCallback? onSearchTap,
    String? activeSearchLabel,
    String? actionLabel,
    Future<void> Function(AppUserModel user)? onAction,
  }) {
    final visibleUsers = users.take(_visibleCount(section));

    return _AdminContentCard(
      title: title,
      subtitle: subtitle,
      actionLabel: searchButtonLabel,
      onActionTap: onSearchTap,
      child: users.isEmpty
          ? _EmptyPanel(
              message: _tr(
                ar: 'لا توجد بيانات للعرض في هذا القسم حاليًا.',
                en: 'There is no data to display in this section right now.',
              ),
            )
          : Column(
              children: [
                if (activeSearchLabel != null && activeSearchLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.adminPrimary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          activeSearchLabel,
                          style: const TextStyle(
                            color: AppPalette.adminPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: AppFontSize.caption,
                          ),
                        ),
                      ),
                    ),
                  ),
                ...visibleUsers.map(
                  (user) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _AdminUserTile(
                      user: user,
                      badgeColor: badgeColor,
                      badgeLabel: badgeLabel,
                      primaryActionLabel: actionLabel,
                      onPrimaryAction: onAction == null
                          ? null
                          : () async => onAction(user),
                    ),
                  ),
                ),
                if (users.length > _visibleCount(section))
                  _LoadMoreButton(
                    label: _tr(ar: 'عرض المزيد', en: 'Load more'),
                    onTap: () => _showMore(section),
                  ),
              ],
            ),
    );
  }

  Widget _buildAccessSection({
    required List<AppUserModel> admins,
    required List<AppUserModel> rejected,
    required String adminUid,
  }) {
    return Column(
      children: [
        _buildUsersSection(
          section: _AdminSection.access,
          users: admins,
          title: _tr(ar: 'حسابات المسؤولين', en: 'Admin accounts'),
          subtitle: _tr(
            ar: 'هذه الحسابات تدير المنصة وتراجع الموافقات وطلبات الاستعادة.',
            en: 'These accounts manage the platform and review approvals and recovery requests.',
          ),
          badgeLabel: _tr(ar: 'مسؤول', en: 'Admin'),
          badgeColor: AppPalette.adminPrimary,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildUsersSection(
          section: _AdminSection.access,
          users: rejected,
          title: _tr(ar: 'الحسابات المرفوضة', en: 'Rejected accounts'),
          subtitle: _tr(
            ar: 'استعادة حسابات الصيادلة المرفوضة من نفس صفحة التحكم عند الحاجة.',
            en: 'Restore rejected pharmacist accounts from the same control page when needed.',
          ),
          badgeLabel: _tr(ar: 'مرفوض', en: 'Rejected'),
          badgeColor: AppPalette.coral,
          actionLabel: _tr(ar: 'استعادة', en: 'Restore'),
          onAction: (user) async {
            await _handleApprovalChange(
              user: user,
              approvalStatus: 'approved',
              adminUid: adminUid,
            );
          },
        ),
      ],
    );
  }

  Widget _buildPharmacistsSection({
    required List<AppUserModel> pharmacists,
    required String adminUid,
  }) {
    final filtered = pharmacists;
    final visible = filtered.take(_visibleCount(_AdminSection.pharmacists));

    return _AdminContentCard(
      title: _tr(ar: 'حسابات الصيادلة', en: 'Pharmacist accounts'),
      subtitle: _tr(
        ar: 'جميع حسابات الصيادلة تظهر هنا مع حالتها والإجراءات الإدارية المناسبة.',
        en: 'All pharmacist accounts are listed here with their status and the proper admin actions.',
      ),
      child: filtered.isEmpty
          ? _EmptyPanel(
              message: _tr(
                ar: 'لم يتم العثور على حسابات صيادلة مطابقة.',
                en: 'No matching pharmacist accounts were found.',
              ),
            )
          : Column(
              children: [
                ...visible.map((user) {
                  final status = user.approvalStatus;
                  final isPending = status == 'pending';
                  final isRejected = status == 'rejected';
                  final badgeColor = isPending
                      ? AppPalette.amber
                      : isRejected
                      ? AppPalette.coral
                      : AppPalette.success;
                  final badgeLabel = isPending
                      ? _tr(ar: 'معلق', en: 'Pending')
                      : isRejected
                      ? _tr(ar: 'مرفوض', en: 'Rejected')
                      : _tr(ar: 'معتمد', en: 'Approved');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _AdminUserTile(
                      user: user,
                      badgeColor: badgeColor,
                      badgeLabel: badgeLabel,
                      primaryActionLabel: isPending
                          ? _tr(ar: 'اعتماد', en: 'Approve')
                          : isRejected
                          ? _tr(ar: 'استعادة', en: 'Restore')
                          : _tr(ar: 'إيقاف', en: 'Suspend'),
                      secondaryActionLabel: isPending
                          ? _tr(ar: 'رفض', en: 'Reject')
                          : null,
                      onPrimaryAction: () async {
                        await _handleApprovalChange(
                          user: user,
                          approvalStatus: isRejected ? 'approved' : isPending ? 'approved' : 'rejected',
                          adminUid: adminUid,
                        );
                      },
                      onSecondaryAction: isPending
                          ? () async {
                              await _handleApprovalChange(
                                user: user,
                                approvalStatus: 'rejected',
                                adminUid: adminUid,
                              );
                            }
                          : null,
                    ),
                  );
                }),
                if (filtered.length > _visibleCount(_AdminSection.pharmacists))
                  _LoadMoreButton(
                    label: _tr(ar: 'عرض المزيد', en: 'Load more'),
                    onTap: () => _showMore(_AdminSection.pharmacists),
                  ),
              ],
            ),
    );
  }

  Widget _buildCurrentSection({
    required List<AppUserModel> pharmacists,
    required List<AppUserModel> pending,
    required List<AppUserModel> approved,
    required List<AppUserModel> patients,
    required List<AppUserModel> admins,
    required List<AppUserModel> rejected,
    required String adminUid,
  }) {
    switch (_currentSection) {
      case _AdminSection.dashboard:
        return _buildOverviewSection(
          pending: pending,
          approved: approved,
          patients: patients,
          admins: admins,
          rejected: rejected,
        );
      case _AdminSection.requests:
        return _buildRequestsSection(pending: pending, adminUid: adminUid);
      case _AdminSection.pharmacists:
        final allPharmacists = pharmacists;
        return _buildPharmacistsSection(
          pharmacists: allPharmacists,
          adminUid: adminUid,
        );
      case _AdminSection.patients:
        final filteredPatients = patients;
        return _buildUsersSection(
          section: _AdminSection.patients,
          users: filteredPatients,
          title: _tr(ar: 'حسابات المرضى', en: 'Patient accounts'),
          subtitle: _tr(
            ar: 'نظرة واضحة على جميع حسابات المرضى المسجلة داخل التطبيق.',
            en: 'A clean overview of every patient account registered inside the app.',
          ),
          badgeLabel: _tr(ar: 'مريض', en: 'Patient'),
          badgeColor: AppPalette.patientPrimary,
        );
      case _AdminSection.access:
        return _buildAccessSection(
          admins: admins,
          rejected: rejected,
          adminUid: adminUid,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final adminUid = currentUser?.uid ?? '';
    final adminEmail = currentUser?.email ?? 'admin@dawatime.app';
    final adminName = adminEmail.split('@').first;

    _showWelcome(adminName);

    return Scaffold(
      key: _scaffoldKey,
      drawer: ProfileSideDrawer(
        profile: _cachedAdminProfile(adminUid),
        fallbackName: adminName,
        fallbackEmail: adminEmail,
        roleLabel: _tr(ar: 'مسؤول المنصة', en: 'Platform administrator'),
        accentColor: AppPalette.adminPrimary,
        onOpenSettings: _openSettingsFromDrawer,
        onEditProfile: () => _openProfileEditor(
          profile: _cachedAdminProfile(adminUid),
          displayName: adminName,
          email: adminEmail,
        ),
        onSignOut: _authService.signOut,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F3FF), Color(0xFFE8E3FF), Color(0xFFFCFBFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<AppUserModel>>(
            stream: _authService.watchAllUsers(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                _cachedUsers = snapshot.data!;
              }

              final users = snapshot.data ?? _cachedUsers;
              final pharmacists = users
                  .where(_isLikelyPharmacist)
                  .toList(growable: false);
              final pending = pharmacists
                  .where((user) => _normalizedApproval(user) == 'pending')
                  .toList(growable: false);
              final approved = pharmacists
                  .where((user) => _normalizedApproval(user) == 'approved')
                  .toList(growable: false);
              final rejected = pharmacists
                  .where((user) => _normalizedApproval(user) == 'rejected')
                  .toList(growable: false);
              final patients = users
                  .where(_isLikelyPatient)
                  .toList(growable: false);
              final admins = users
                  .where(_isLikelyAdmin)
                  .toList(growable: false);
              AppUserModel? currentAdmin;
              for (final user in users) {
                if (user.uid == adminUid) {
                  currentAdmin = user;
                  break;
                }
              }
              final resolvedAdminName =
                  currentAdmin?.displayName.trim().isNotEmpty == true
                  ? currentAdmin!.displayName
                  : adminName;
              final resolvedAdminEmail = currentAdmin?.email ?? adminEmail;

              return Stack(
                children: [
                  Column(
                    children: [
                      StreamBuilder<int>(
                        stream: _notificationService.watchUnreadCount(),
                        builder: (context, badgeSnapshot) {
                          final badgeCount = badgeSnapshot.data ?? 0;
                          return HomeTopActionBar(
                            profile: currentAdmin,
                            fallbackName: resolvedAdminName,
                            roleLabel: _tr(
                              ar: 'غرفة التحكم الإدارية',
                              en: 'Administrative control room',
                            ),
                            accentColors: const [
                              AppPalette.adminPrimary,
                              Color(0xFF8A7CFF),
                            ],
                            trailingIcon: Icons.notifications_rounded,
                            trailingBadgeCount: badgeCount,
                            onTrailingIconPressed: () =>
                                _showNotificationsPanel(),
                            onMenuPressed: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                          );
                        },
                      ),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppLayout.maxContentWidth,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: KeyedSubtree(
                                key: ValueKey(_currentSection),
                                child: ListView(
                                  padding: AppSpacing.pagePadding,
                                  children: [
                                    if (snapshot.hasError)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: AppSpacing.md,
                                        ),
                                        child: _StreamStatusCard(
                                          message: _tr(
                                            ar: 'حدثت مشكلة مؤقتة في مزامنة الحسابات مع Firebase. ستبقى آخر بيانات متاحة ظاهرة حتى لا تختفي المهام.',
                                            en: 'There was a temporary problem syncing accounts with Firebase. The latest available data will stay visible so tasks do not disappear.',
                                          ),
                                        ),
                                      ),
                                    if (_currentSection ==
                                        _AdminSection.access) ...[
                                      _AdminOverviewCard(
                                        adminName: resolvedAdminName,
                                        adminEmail: resolvedAdminEmail,
                                        adminRole: _tr(
                                          ar: 'مسؤول المنصة',
                                          en: 'Platform administrator',
                                        ),
                                        totalUsers: users.length,
                                        pendingCount: pending.length,
                                        pharmacistCount: approved.length,
                                        patientCount: patients.length,
                                        adminCount: admins.length,
                                        rejectedCount: rejected.length,
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                    ],
                                    if (_currentSection != _AdminSection.dashboard) ...[
                                      _AdminPageHero(
                                        title: _sectionTitle(_currentSection),
                                        subtitle: _sectionSubtitle(_currentSection),
                                        icon: _sectionIcon(_currentSection),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                    ],
                                    _buildCurrentSection(
                                      pharmacists: pharmacists,
                                      pending: pending,
                                      approved: approved,
                                      patients: patients,
                                      admins: admins,
                                      rejected: rejected,
                                      adminUid: adminUid,
                                    ),
                                    const SizedBox(height: 120),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  AnimatedWelcomeBanner(
                    visible: _welcomeBannerVisible,
                    displayName: _welcomeDisplayName,
                    accentColor: AppPalette.adminPrimary,
                    icon: Icons.workspace_premium_rounded,
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: AnimatedHomeBottomBar(
        selectedIndex: _AdminSection.values.indexOf(_currentSection),
        activeColor: AppPalette.adminPrimary,
        horizontalInset: AppSpacing.sm,
      onDestinationSelected: (index) {
        final section = _AdminSection.values[index];
        if (section == _AdminSection.requests ||
            section == _AdminSection.pharmacists) {
          _notificationService.markNotificationsSeen();
        }
        setState(() {
          _currentSection = section;
        });
      },
        items: [
          HomeBottomBarItem(
            icon: Icons.space_dashboard_outlined,
            selectedIcon: Icons.space_dashboard_rounded,
            label: _tr(ar: 'الرئيسية', en: 'Home'),
          ),
          HomeBottomBarItem(
            icon: Icons.pending_actions_outlined,
            selectedIcon: Icons.pending_actions_rounded,
            label: _tr(ar: 'الطلبات', en: 'Requests'),
          ),
          HomeBottomBarItem(
            icon: Icons.local_pharmacy_outlined,
            selectedIcon: Icons.local_pharmacy_rounded,
            label: _tr(ar: 'الصيادلة', en: 'Pharmacists'),
          ),
          HomeBottomBarItem(
            icon: Icons.groups_outlined,
            selectedIcon: Icons.groups_rounded,
            label: _tr(ar: 'المرضى', en: 'Patients'),
          ),
          HomeBottomBarItem(
            icon: Icons.admin_panel_settings_outlined,
            selectedIcon: Icons.admin_panel_settings_rounded,
            label: _tr(ar: 'التحكم', en: 'Control'),
          ),
        ],
      ),
    );
  }
}






