import 'package:flutter/material.dart';

import '../../app/localization/app_localization.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/depth_card.dart';
import '../../data/models/app_user_model.dart';
import '../../data/services/auth_service.dart';

class PharmacistPendingScreen extends StatelessWidget {
  const PharmacistPendingScreen({super.key, required this.profile});

  final AppUserModel profile;

  @override
  Widget build(BuildContext context) {
    return _StatusScaffold(
      title: context.tr(
        ar: 'طلب الصيدلي قيد المراجعة',
        en: 'Pharmacist request under review',
      ),
      subtitle: context.tr(
        ar: 'تم إنشاء حساب ${profile.username.isEmpty ? profile.email : profile.username} بنجاح، لكن لا يمكن فتح لوحة الصيدلي قبل موافقة الإدارة.',
        en: 'The account ${profile.username.isEmpty ? profile.email : profile.username} was created successfully, but the pharmacist dashboard will stay locked until admin approval.',
      ),
      gradient: const [Color(0xFFEAF8F6), Color(0xFFD6F3EE)],
      icon: Icons.hourglass_top_rounded,
      primaryActionLabel: context.tr(ar: 'تسجيل الخروج', en: 'Sign out'),
      onPrimaryAction: () async {
        await AuthService().signOut();
      },
      body: [
        _InfoTile(
          icon: Icons.verified_user_outlined,
          title: context.tr(ar: 'الحالة الحالية', en: 'Current status'),
          message: context.tr(
            ar: 'في انتظار موافقة المسؤول على حساب الصيدلي.',
            en: 'Waiting for admin approval for the pharmacist account.',
          ),
        ),
        _InfoTile(
          icon: Icons.email_outlined,
          title: context.tr(ar: 'ما الذي يحدث الآن؟', en: 'What happens now?'),
          message: context.tr(
            ar: 'بعد الموافقة ستفتح لك واجهة الصيدلي تلقائياً في المرة التالية.',
            en: 'Once approved, the pharmacist interface will open automatically the next time you enter.',
          ),
        ),
      ],
    );
  }
}

class PharmacistRejectedScreen extends StatelessWidget {
  const PharmacistRejectedScreen({super.key, required this.profile});

  final AppUserModel profile;

  @override
  Widget build(BuildContext context) {
    return _StatusScaffold(
      title: context.tr(
        ar: 'تم إيقاف وصول حساب الصيدلي',
        en: 'Pharmacist account access stopped',
      ),
      subtitle: context.tr(
        ar: 'الحساب ${profile.username.isEmpty ? profile.email : profile.username} لا يملك حالياً موافقة إدارية للدخول كصيدلي.',
        en: 'The account ${profile.username.isEmpty ? profile.email : profile.username} does not currently have admin approval to enter as a pharmacist.',
      ),
      gradient: const [Color(0xFFFFF0F0), Color(0xFFFFE3E5)],
      icon: Icons.block_rounded,
      primaryActionLabel: context.tr(
        ar: 'العودة وتسجيل الخروج',
        en: 'Go back and sign out',
      ),
      onPrimaryAction: () async {
        await AuthService().signOut();
      },
      body: [
        _InfoTile(
          icon: Icons.admin_panel_settings_outlined,
          title: context.tr(ar: 'السبب', en: 'Reason'),
          message: context.tr(
            ar: 'تم رفض أو إيقاف طلب الصيدلي من قبل الإدارة.',
            en: 'The pharmacist request was rejected or stopped by the admin team.',
          ),
        ),
        _InfoTile(
          icon: Icons.support_agent_outlined,
          title: context.tr(ar: 'الخطوة التالية', en: 'Next step'),
          message: context.tr(
            ar: 'يمكنك التواصل مع المشرف أو استخدام حساب مريض معتمد.',
            en: 'You can contact the administrator or use an approved patient account.',
          ),
        ),
      ],
    );
  }
}

class _StatusScaffold extends StatelessWidget {
  const _StatusScaffold({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.icon,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.body,
  });

  final String title;
  final String subtitle;
  final List<Color> gradient;
  final IconData icon;
  final String primaryActionLabel;
  final Future<void> Function() onPrimaryAction;
  final List<Widget> body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: DepthCard(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppPalette.patientPrimary.withValues(
                            alpha: 0.10,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: AppPalette.patientPrimary,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: AppPalette.text,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppPalette.muted,
                          height: 1.6,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ...body.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: item,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          onPrimaryAction();
                        },
                        child: Text(primaryActionLabel),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppPalette.patientPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(color: AppPalette.muted, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
