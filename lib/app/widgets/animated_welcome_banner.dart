import 'package:flutter/material.dart';

import '../localization/app_localization.dart';
import '../theme/app_metrics.dart';
import '../theme/app_theme.dart';

class AnimatedWelcomeBanner extends StatelessWidget {
  const AnimatedWelcomeBanner({
    super.key,
    required this.visible,
    required this.displayName,
    required this.accentColor,
    required this.icon,
  });

  final bool visible;
  final String displayName;
  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutBack,
        offset: visible ? Offset.zero : const Offset(0, -1.2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 280),
          opacity: visible ? 1 : 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.22),
                          blurRadius: 30,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  accentColor,
                                  accentColor.withValues(alpha: 0.68),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Icon(icon, color: Colors.white),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  context.tr(
                                    ar: 'أهلاً بعودتك، $displayName',
                                    en: 'Welcome back, $displayName',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: AppFontSize.title,
                                    fontWeight: FontWeight.w900,
                                    color: AppPalette.text,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  context.tr(
                                    ar: 'تم تجهيز صفحتك ويمكنك المتابعة الآن بسلاسة.',
                                    en: 'Your workspace is ready and navigation is live now.',
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: AppFontSize.body,
                                    color: AppPalette.muted,
                                    height: 1.4,
                                  ),
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
            ),
          ),
        ),
      ),
    );
  }
}
