import 'package:flutter/material.dart';

import '../localization/app_localization.dart';
import '../theme/app_metrics.dart';
import '../theme/app_theme.dart';

class AppLanguageToggleButton extends StatelessWidget {
  const AppLanguageToggleButton({super.key, this.isOnDarkBackground = false});

  final bool isOnDarkBackground;

  @override
  Widget build(BuildContext context) {
    final localeController = context.localeController;
    final isArabic = localeController.isArabic;
    final backgroundColor = isOnDarkBackground
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.92);
    final borderColor = isOnDarkBackground
        ? Colors.white.withValues(alpha: 0.24)
        : AppPalette.patientPrimary.withValues(alpha: 0.10);
    final activeTextColor = isOnDarkBackground ? AppPalette.text : Colors.white;
    final inactiveTextColor = isOnDarkBackground
        ? Colors.white
        : AppPalette.muted;
    final activeFill = isOnDarkBackground
        ? Colors.white
        : AppPalette.patientPrimary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageChip(
              label: context.t(AppText.arabic),
              selected: isArabic,
              activeFill: activeFill,
              activeTextColor: activeTextColor,
              inactiveTextColor: inactiveTextColor,
              onTap: () {
                localeController.updateLocale(const Locale('ar'));
              },
            ),
            _LanguageChip(
              label: context.t(AppText.english),
              selected: !isArabic,
              activeFill: activeFill,
              activeTextColor: activeTextColor,
              inactiveTextColor: inactiveTextColor,
              onTap: () {
                localeController.updateLocale(const Locale('en'));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.activeFill,
    required this.activeTextColor,
    required this.inactiveTextColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color activeFill;
  final Color activeTextColor;
  final Color inactiveTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? activeFill : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? activeTextColor : inactiveTextColor,
                fontSize: AppFontSize.body,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
