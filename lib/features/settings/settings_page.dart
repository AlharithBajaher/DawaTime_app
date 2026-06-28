import 'package:flutter/material.dart';

import '../../app/localization/app_localization.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/depth_card.dart';
import '../../app/widgets/support_center_sheet.dart';
import 'backup_screen.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const String _appVersion = '0.0.1';

  @override
  Widget build(BuildContext context) {
    final localeController = context.localeController;

    return Scaffold(
      appBar: AppBar(title: Text(context.t(AppText.settings))),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3F7FF), Color(0xFFEAF2FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.maxSheetWidth,
              ),
              child: ListView(
                padding: AppSpacing.pagePaddingWide,
                children: [
                  DepthCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t(AppText.settings),
                          style: const TextStyle(
                            fontSize: AppFontSize.pageTitle,
                            fontWeight: FontWeight.w900,
                            color: AppPalette.text,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          context.t(AppText.settingsSubtitle),
                          style: const TextStyle(
                            color: AppPalette.muted,
                            fontSize: AppFontSize.body,
                            height: 1.6,
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
                          context.t(AppText.language),
                          style: const TextStyle(
                            fontSize: AppFontSize.title,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.text,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          context.t(AppText.languageSubtitle),
                          style: const TextStyle(
                            color: AppPalette.muted,
                            fontSize: AppFontSize.body,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _LanguageOptionTile(
                          label: context.t(AppText.arabic),
                          selected: localeController.locale.languageCode == 'ar',
                          onTap: () {
                            localeController.updateLocale(const Locale('ar'));
                          },
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _LanguageOptionTile(
                          label: context.t(AppText.english),
                          selected: localeController.locale.languageCode == 'en',
                          onTap: () {
                            localeController.updateLocale(const Locale('en'));
                          },
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
                            ar: 'النسخ الاحتياطي',
                            en: 'Backup & restore',
                          ),
                          style: const TextStyle(
                            fontSize: AppFontSize.title,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.text,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          context.tr(
                            ar: 'احفظ بياناتك أو استعدها من نسخة سابقة',
                            en: 'Backup your data or restore from a previous backup',
                          ),
                          style: const TextStyle(
                            color: AppPalette.muted,
                            fontSize: AppFontSize.body,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _SettingsActionTile(
                          icon: Icons.backup_rounded,
                          label: context.tr(
                            ar: 'إدارة النسخ الاحتياطي',
                            en: 'Manage backup & restore',
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BackupScreen(),
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
                          context.tr(
                            ar: 'الدعم والتواصل',
                            en: 'Support & contact',
                          ),
                          style: const TextStyle(
                            fontSize: AppFontSize.title,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.text,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _SettingsActionTile(
                          icon: Icons.support_agent_rounded,
                          label: context.tr(
                            ar: 'التواصل مع دعم دوا تايم',
                            en: 'Contact DawaTime support',
                          ),
                          onTap: () =>
                              SupportCenterSheet.showSupportSheet(context),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _SettingsActionTile(
                          icon: Icons.code_rounded,
                          label: context.tr(
                            ar: 'المصمم والمطور',
                            en: 'Designer & developer',
                          ),
                          onTap: () =>
                              SupportCenterSheet.showDeveloperSheet(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DepthCard(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.new_releases_rounded,
                          color: AppPalette.patientPrimary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          context.tr(
                            ar: 'الإصدار: $_appVersion',
                            en: 'Version: $_appVersion',
                          ),
                          style: const TextStyle(
                            fontSize: AppFontSize.bodyLarge,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Center(
                    child: Text(
                      '© 2026 DawaTime',
                      style: TextStyle(
                        color: AppPalette.muted,
                        fontSize: AppFontSize.body,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFF),
            border: Border.all(color: const Color(0xFFE1EAF8)),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppPalette.patientPrimary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
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
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected
                  ? AppPalette.patientPrimary
                  : const Color(0xFFD9E3F4),
              width: selected ? 1.6 : 1,
            ),
            color: selected
                ? AppPalette.patientPrimary.withValues(alpha: 0.08)
                : const Color(0xFFF8FBFF),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppPalette.patientPrimary : AppPalette.muted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: AppFontSize.bodyLarge,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
