import 'package:flutter/material.dart';

import '../../data/models/app_user_model.dart';
import '../localization/app_localization.dart';
import '../theme/app_metrics.dart';
import '../theme/app_theme.dart';
import 'depth_card.dart';
import 'support_center_sheet.dart';

class ProfileSideDrawer extends StatelessWidget {
  const ProfileSideDrawer({
    super.key,
    required this.profile,
    required this.fallbackName,
    required this.fallbackEmail,
    required this.roleLabel,
    required this.accentColor,
    required this.onOpenSettings,
    this.onEditProfile,
    required this.onSignOut,
  });

  final AppUserModel? profile;
  final String fallbackName;
  final String fallbackEmail;
  final String roleLabel;
  final Color accentColor;
  final VoidCallback onOpenSettings;
  final VoidCallback? onEditProfile;
  final Future<void> Function() onSignOut;

  String get _resolvedName =>
      profile?.displayName.trim().isNotEmpty == true
      ? profile!.displayName
      : fallbackName;

  String get _resolvedEmail => profile?.email ?? fallbackEmail;

  String get _resolvedInitials {
    final initials = profile?.initials;
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
  Widget build(BuildContext context) {
    final photoUrl = profile?.photoUrl;

    return Drawer(
      width: 360,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            DepthCard(
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withValues(alpha: 0.72)],
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
                        radius: 28,
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
                  _HeaderPill(label: roleLabel),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DepthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(ar: 'الإعدادات والحساب', en: 'Settings & account'),
                    style: const TextStyle(
                      color: AppPalette.text,
                      fontSize: AppFontSize.sectionTitle,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (onEditProfile != null) ...[
                    _DrawerActionTile(
                      icon: Icons.edit_rounded,
                      title: context.tr(
                        ar: 'تعديل الملف الشخصي',
                        en: 'Edit profile',
                      ),
                      accentColor: accentColor,
                      onTap: () async {
                        Navigator.of(context).maybePop();
                        onEditProfile!.call();
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  _DrawerActionTile(
                    icon: Icons.support_agent_rounded,
                    title: context.tr(ar: 'دعم دواء تايم', en: 'DawaTime support'),
                    accentColor: accentColor,
                    onTap: () async {
                      Navigator.of(context).maybePop();
                      await SupportCenterSheet.showSupportSheet(context);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _DrawerActionTile(
                    icon: Icons.code_rounded,
                    title: context.tr(ar: 'تصميم وتطوير', en: 'Design & development'),
                    accentColor: accentColor,
                    onTap: () async {
                      Navigator.of(context).maybePop();
                      await SupportCenterSheet.showDeveloperSheet(context);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _DrawerActionTile(
                    icon: Icons.settings_outlined,
                    title: context.t(AppText.settings),
                    accentColor: accentColor,
                    onTap: () async => onOpenSettings(),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _DrawerActionTile(
                    icon: Icons.logout_rounded,
                    title: context.tr(ar: 'تسجيل الخروج', en: 'Sign out'),
                    accentColor: accentColor,
                    onTap: () async {
                      Navigator.of(context).maybePop();
                      await onSignOut();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: AppFontSize.caption,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  const _DrawerActionTile({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color accentColor;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () async => onTap(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppPalette.text,
                  fontSize: AppFontSize.body,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppPalette.muted),
          ],
        ),
      ),
    );
  }
}
