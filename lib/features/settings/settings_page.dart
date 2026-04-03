import 'package:flutter/material.dart';

import '../../app/localization/app_localization.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/depth_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
                          selected:
                              localeController.locale.languageCode == 'ar',
                          onTap: () {
                            localeController.updateLocale(const Locale('ar'));
                          },
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _LanguageOptionTile(
                          label: context.t(AppText.english),
                          selected:
                              localeController.locale.languageCode == 'en',
                          onTap: () {
                            localeController.updateLocale(const Locale('en'));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
