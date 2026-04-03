import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/localization/app_localization.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/depth_card.dart';
import '../../data/models/app_user_model.dart';
import '../../data/services/auth_service.dart';

part 'admin_home_sections.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final AuthService _authService = AuthService();
  List<AppUserModel> _cachedUsers = const <AppUserModel>[];
  bool _hasWelcomedAdmin = false;

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
                ar: 'تم اعتماد حساب الصيدلي بنجاح.',
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

  void _showWelcome(String adminName) {
    if (_hasWelcomedAdmin) {
      return;
    }

    _hasWelcomedAdmin = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              ar: 'مرحباً بعودتك، $adminName',
              en: 'Welcome back, $adminName',
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final adminUid = currentUser?.uid ?? '';
    final adminEmail = currentUser?.email ?? 'admin@dawatime.app';
    final adminName = adminEmail.split('@').first;

    _showWelcome(adminName);

    return Scaffold(
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
                  .where((user) => user.role == 'pharmacist')
                  .toList(growable: false);
              final pending = pharmacists
                  .where((user) => user.approvalStatus == 'pending')
                  .toList(growable: false);
              final approved = pharmacists
                  .where((user) => user.approvalStatus == 'approved')
                  .toList(growable: false);
              final rejected = pharmacists
                  .where((user) => user.approvalStatus == 'rejected')
                  .toList(growable: false);
              final patients = users
                  .where((user) => user.role == 'patient')
                  .toList(growable: false);
              final admins = users
                  .where((user) => user.role == 'admin')
                  .toList(growable: false);

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.maxContentWidth,
                  ),
                  child: ListView(
                    padding: AppSpacing.pagePadding,
                    children: [
                      if (snapshot.hasError)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _StreamStatusCard(
                            message: _tr(
                              ar: 'حدثت مشكلة أثناء مزامنة الحسابات مع Firebase. سنعرض آخر بيانات متاحة حتى لا تختفي طلبات الموافقة.',
                              en: 'There was a problem syncing accounts with Firebase. The latest available data will stay visible so approval requests do not disappear.',
                            ),
                          ),
                        ),
                      _AdminOverviewCard(
                        adminName: adminName,
                        adminEmail: adminEmail,
                        totalUsers: users.length,
                        pendingCount: pending.length,
                        pharmacistCount: pharmacists.length,
                        patientCount: patients.length,
                        adminCount: admins.length,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SectionCard(
                        title: _tr(
                          ar: 'طلبات الصيادلة المعلقة',
                          en: 'Pending pharmacist requests',
                        ),
                        subtitle: _tr(
                          ar: 'اعتمد أو ارفض الحسابات التي تحتاج موافقة قبل دخول واجهة الصيدلي.',
                          en: 'Approve or reject the accounts that need review before entering the pharmacist workspace.',
                        ),
                        child: pending.isEmpty
                            ? _EmptyPanel(
                                message: _tr(
                                  ar: 'لا توجد طلبات صيدلي معلقة حالياً.',
                                  en: 'There are no pending pharmacist requests right now.',
                                ),
                              )
                            : Column(
                                children: pending
                                    .map(
                                      (user) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: AppSpacing.sm,
                                        ),
                                        child: _ApprovalTile(
                                          user: user,
                                          onApprove: () async {
                                            await _handleApprovalChange(
                                              user: user,
                                              approvalStatus: 'approved',
                                              adminUid: adminUid,
                                            );
                                          },
                                          onReject: () async {
                                            await _handleApprovalChange(
                                              user: user,
                                              approvalStatus: 'rejected',
                                              adminUid: adminUid,
                                            );
                                          },
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SectionCard(
                        title: _tr(
                          ar: 'الصيادلة المعتمدون',
                          en: 'Approved pharmacists',
                        ),
                        subtitle: _tr(
                          ar: 'هؤلاء يمكنهم الدخول الكامل إلى لوحة الصيدلي.',
                          en: 'These accounts can fully access the pharmacist dashboard.',
                        ),
                        child: approved.isEmpty
                            ? _EmptyPanel(
                                message: _tr(
                                  ar: 'لا يوجد صيادلة معتمدون بعد.',
                                  en: 'There are no approved pharmacists yet.',
                                ),
                              )
                            : Column(
                                children: approved
                                    .map(
                                      (user) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: AppSpacing.sm,
                                        ),
                                        child: _SimpleUserTile(
                                          user: user,
                                          badgeColor: AppPalette.success,
                                          badgeLabel: _tr(
                                            ar: 'معتمد',
                                            en: 'Approved',
                                          ),
                                          actionLabel: _tr(
                                            ar: 'إيقاف',
                                            en: 'Suspend',
                                          ),
                                          onAction: () async {
                                            await _handleApprovalChange(
                                              user: user,
                                              approvalStatus: 'rejected',
                                              adminUid: adminUid,
                                            );
                                          },
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SectionCard(
                        title: _tr(ar: 'حسابات المرضى', en: 'Patient accounts'),
                        subtitle: _tr(
                          ar: 'عرض سريع لكل حسابات المرضى المسجلة داخل التطبيق.',
                          en: 'A quick view of all patient accounts registered inside the app.',
                        ),
                        child: patients.isEmpty
                            ? _EmptyPanel(
                                message: _tr(
                                  ar: 'لا توجد حسابات مرضى حالياً.',
                                  en: 'There are no patient accounts right now.',
                                ),
                              )
                            : Column(
                                children: patients
                                    .take(8)
                                    .map(
                                      (user) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: AppSpacing.sm,
                                        ),
                                        child: _SimpleUserTile(
                                          user: user,
                                          badgeColor: AppPalette.patientPrimary,
                                          badgeLabel: _tr(
                                            ar: 'مريض',
                                            en: 'Patient',
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SectionCard(
                        title: _tr(ar: 'حسابات الإدارة', en: 'Admin accounts'),
                        subtitle: _tr(
                          ar: 'هذه هي الحسابات التي تملك صلاحية إدارة التطبيق.',
                          en: 'These are the accounts that can manage the application.',
                        ),
                        child: admins.isEmpty
                            ? _EmptyPanel(
                                message: _tr(
                                  ar: 'لا توجد حسابات إدارة حالياً.',
                                  en: 'There are no admin accounts right now.',
                                ),
                              )
                            : Column(
                                children: admins
                                    .map(
                                      (user) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: AppSpacing.sm,
                                        ),
                                        child: _SimpleUserTile(
                                          user: user,
                                          badgeColor: AppPalette.adminPrimary,
                                          badgeLabel: _tr(
                                            ar: 'إدارة',
                                            en: 'Admin',
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SectionCard(
                        title: _tr(
                          ar: 'الحسابات المرفوضة',
                          en: 'Rejected accounts',
                        ),
                        subtitle: _tr(
                          ar: 'يمكنك إعادة اعتماد الصيادلة المرفوضين من هذه القائمة.',
                          en: 'You can restore rejected pharmacist accounts from this list.',
                        ),
                        child: rejected.isEmpty
                            ? _EmptyPanel(
                                message: _tr(
                                  ar: 'لا توجد حسابات مرفوضة حالياً.',
                                  en: 'There are no rejected accounts right now.',
                                ),
                              )
                            : Column(
                                children: rejected
                                    .map(
                                      (user) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: AppSpacing.sm,
                                        ),
                                        child: _SimpleUserTile(
                                          user: user,
                                          badgeColor: AppPalette.coral,
                                          badgeLabel: _tr(
                                            ar: 'مرفوض',
                                            en: 'Rejected',
                                          ),
                                          actionLabel: _tr(
                                            ar: 'استعادة',
                                            en: 'Restore',
                                          ),
                                          onAction: () async {
                                            await _handleApprovalChange(
                                              user: user,
                                              approvalStatus: 'approved',
                                              adminUid: adminUid,
                                            );
                                          },
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _authService.signOut();
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: Text(_tr(ar: 'تسجيل الخروج', en: 'Sign out')),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AdminOverviewCard extends StatelessWidget {
  const _AdminOverviewCard({
    required this.adminName,
    required this.adminEmail,
    required this.totalUsers,
    required this.pendingCount,
    required this.pharmacistCount,
    required this.patientCount,
    required this.adminCount,
  });

  final String adminName;
  final String adminEmail;
  final int totalUsers;
  final int pendingCount;
  final int pharmacistCount;
  final int patientCount;
  final int adminCount;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _AdminMetricData(
        label: context.tr(ar: 'الإجمالي', en: 'Total'),
        value: '$totalUsers',
      ),
      _AdminMetricData(
        label: context.tr(ar: 'معلّق', en: 'Pending'),
        value: '$pendingCount',
      ),
      _AdminMetricData(
        label: context.tr(ar: 'صيادلة', en: 'Pharmacists'),
        value: '$pharmacistCount',
      ),
      _AdminMetricData(
        label: context.tr(ar: 'مرضى', en: 'Patients'),
        value: '$patientCount',
      ),
      _AdminMetricData(
        label: context.tr(ar: 'إدارة', en: 'Admins'),
        value: '$adminCount',
      ),
    ];

    return DepthCard(
      gradient: const LinearGradient(
        colors: [AppPalette.adminPrimary, Color(0xFF8A7CFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: Colors.white.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(ar: 'لوحة التحكم الرئيسية', en: 'Main control panel'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppFontSize.hero,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr(
              ar: 'مرحباً $adminName، يمكنك من هنا متابعة الحسابات والموافقات والتحكم بسير التطبيق.',
              en: 'Welcome $adminName. From here you can review accounts, handle approvals, and control the application flow.',
            ),
            style: const TextStyle(
              color: Colors.white,
              height: 1.5,
              fontSize: AppFontSize.body,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            adminEmail,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: AppFontSize.caption,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: stats
                .map((stat) => _AdminMetricCard(data: stat))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _AdminMetricData {
  const _AdminMetricData({required this.label, required this.value});

  final String label;
  final String value;
}

class _AdminMetricCard extends StatelessWidget {
  const _AdminMetricCard({required this.data});

  final _AdminMetricData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppFontSize.metric,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              data.label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: AppFontSize.caption,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
