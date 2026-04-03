import 'package:flutter/material.dart';

import '../../../app/localization/app_localization.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/depth_card.dart';

class RoleVisualConfig {
  const RoleVisualConfig({
    required this.roleKey,
    required this.roleName,
    required this.shortRoleHint,
    required this.roleDescription,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.icon,
    required this.highlightColor,
    required this.pageGradient,
    required this.heroGradient,
    required this.buttonGradient,
    required this.featureBullets,
  });

  final String roleKey;
  final String roleName;
  final String shortRoleHint;
  final String roleDescription;
  final String heroTitle;
  final String heroSubtitle;
  final IconData icon;
  final Color highlightColor;
  final List<Color> pageGradient;
  final List<Color> heroGradient;
  final List<Color> buttonGradient;
  final List<String> featureBullets;

  factory RoleVisualConfig.patient(BuildContext context) {
    return RoleVisualConfig(
      roleKey: 'patient',
      roleName: context.tr(ar: 'المريض', en: 'Patient'),
      shortRoleHint: context.tr(
        ar: 'أدوية يومية، تذكيرات، متابعة صحية',
        en: 'Daily medications, reminders, and health tracking',
      ),
      roleDescription: context.tr(
        ar: 'واجهة المريض تركز على جدول الدواء والتنبيهات والتقدم اليومي بشكل هادئ وواضح.',
        en: 'The patient view focuses on medication schedules, reminders, and daily progress in a calm, clear way.',
      ),
      heroTitle: context.tr(
        ar: 'رحلة علاجية أوضح\nمن أول شاشة',
        en: 'A clearer treatment journey\nfrom the first screen',
      ),
      heroSubtitle: context.tr(
        ar: 'اختر وضع المريض لتظهر لك تجربة تتابع الجرعات، الملخص اليومي، والإجراءات السريعة بشكل بصري حديث.',
        en: 'Choose patient mode to get a focused experience for doses, daily summaries, and quick actions.',
      ),
      icon: Icons.favorite_outline_rounded,
      highlightColor: AppPalette.patientPrimary,
      pageGradient: const [
        Color(0xFFE7F2FF),
        Color(0xFFD4E8FF),
        Color(0xFFF6FAFF),
      ],
      heroGradient: const [
        Color(0xFF1E88E5),
        Color(0xFF3AA8F7),
        Color(0xFF74D1FF),
      ],
      buttonGradient: const [Color(0xFF1E88E5), Color(0xFF5BC7FF)],
      featureBullets: [
        context.tr(
          ar: 'لوحة يومية تعرض الجرعات القادمة والالتزام.',
          en: 'A daily dashboard for upcoming doses and adherence.',
        ),
        context.tr(
          ar: 'إضافة الأدوية وتحديثها مع تنبيهات محلية فعالة.',
          en: 'Add and update medications with effective local reminders.',
        ),
        context.tr(
          ar: 'واجهة هادئة مستوحاة من التصميمات المرجعية المرفقة.',
          en: 'A calm interface inspired by the reference designs.',
        ),
      ],
    );
  }

  factory RoleVisualConfig.pharmacist(BuildContext context) {
    return RoleVisualConfig(
      roleKey: 'pharmacist',
      roleName: context.tr(ar: 'الصيدلي', en: 'Pharmacist'),
      shortRoleHint: context.tr(
        ar: 'سير عمل، مهام، متابعة تشغيلية',
        en: 'Workflow, tasks, and operational follow-up',
      ),
      roleDescription: context.tr(
        ar: 'واجهة الصيدلي تركز على الطلبات والحالات والمخزون وسير العمل داخل الصيدلية.',
        en: 'The pharmacist view focuses on requests, cases, inventory, and pharmacy workflow.',
      ),
      heroTitle: context.tr(
        ar: 'مساحة عمل صيدلية\nواضحة وسريعة',
        en: 'A pharmacy workspace\nthat feels clear and fast',
      ),
      heroSubtitle: context.tr(
        ar: 'اختر وضع الصيدلي لرؤية تجربة أكثر مهنية مع بطاقات مهام ولوحة تشغيل يومية مختلفة تماماً عن واجهة المريض.',
        en: 'Choose pharmacist mode for a more professional experience with task cards and a dedicated operations dashboard.',
      ),
      icon: Icons.local_pharmacy_outlined,
      highlightColor: AppPalette.pharmacistPrimary,
      pageGradient: const [
        Color(0xFFE6F7F4),
        Color(0xFFD2F1EA),
        Color(0xFFF5FCFA),
      ],
      heroGradient: const [
        Color(0xFF0F766E),
        Color(0xFF149C91),
        Color(0xFF59D5B7),
      ],
      buttonGradient: const [Color(0xFF0F766E), Color(0xFF55D8B4)],
      featureBullets: [
        context.tr(
          ar: 'بطاقات تشغيلية مختلفة بصرياً عن واجهة المريض منذ أول شاشة.',
          en: 'Operational cards that feel distinct from the patient experience.',
        ),
        context.tr(
          ar: 'قائمة مهام عملية قابلة للإضافة والتحديث والحذف.',
          en: 'A practical task list that can be added, updated, and removed.',
        ),
        context.tr(
          ar: 'لوحة متابعة تركز على الأولويات والطلبات الحرجة.',
          en: 'A monitoring panel focused on priorities and urgent requests.',
        ),
      ],
    );
  }
}

class HeroPanel extends StatelessWidget {
  const HeroPanel({
    super.key,
    required this.config,
    required this.selectedRole,
    required this.onRoleSelected,
  });

  final RoleVisualConfig config;
  final String selectedRole;
  final ValueChanged<String> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DepthCard(
      padding: const EdgeInsets.all(24),
      gradient: LinearGradient(
        colors: config.heroGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: Colors.white.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.16),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const Spacer(),
              Text(
                context.t(AppText.appName),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            config.heroTitle,
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            config.heroSubtitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.65,
            ),
          ),
          const SizedBox(height: 28),
          RoleSelector(
            selectedRole: selectedRole,
            onRoleSelected: onRoleSelected,
          ),
          const SizedBox(height: 28),
          Center(child: RoleIllustration(config: config)),
          const SizedBox(height: 28),
          ...config.featureBullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      bullet,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthModeTabs extends StatelessWidget {
  const AuthModeTabs({
    super.key,
    required this.isRegistering,
    required this.onChanged,
  });

  final bool isRegistering;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              selected: !isRegistering,
              label: context.tr(ar: 'تسجيل الدخول', en: 'Sign in'),
              onTap: () => onChanged(false),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ModeButton(
              selected: isRegistering,
              label: context.tr(ar: 'إنشاء حساب', en: 'Create account'),
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleSelected,
  });

  final String selectedRole;
  final ValueChanged<String> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    final entries = <RoleVisualConfig>[
      RoleVisualConfig.patient(context),
      RoleVisualConfig.pharmacist(context),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: entries.map((entry) {
        final selected = selectedRole == entry.roleKey;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 220,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: selected ? 0.18 : 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: selected ? 0.30 : 0.14),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => onRoleSelected(entry.roleKey),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                          child: Icon(entry.icon, color: Colors.white),
                        ),
                        const Spacer(),
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      entry.roleName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.shortRoleHint,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class RoleIllustration extends StatelessWidget {
  const RoleIllustration({super.key, required this.config});

  final RoleVisualConfig config;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 24,
            top: 24,
            child: _FloatingBubble(
              size: 76,
              color: Colors.white.withValues(alpha: 0.15),
              icon: Icons.favorite_rounded,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 36,
            child: _FloatingBubble(
              size: 88,
              color: Colors.white.withValues(alpha: 0.18),
              icon: Icons.calendar_month_rounded,
            ),
          ),
          Positioned(
            right: 34,
            top: 14,
            child: _FloatingBubble(
              size: 64,
              color: Colors.white.withValues(alpha: 0.12),
              icon: Icons.auto_graph_rounded,
            ),
          ),
          Container(
            width: 290,
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(48),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.95),
                  Colors.white.withValues(alpha: 0.70),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 26,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 18,
                  top: 22,
                  child: Container(
                    width: 128,
                    height: 92,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: config.buttonGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 24,
                  top: 24,
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: config.highlightColor.withValues(
                      alpha: 0.12,
                    ),
                    child: Icon(
                      config.icon,
                      size: 42,
                      color: config.highlightColor,
                    ),
                  ),
                ),
                Positioned(
                  left: 32,
                  right: 32,
                  bottom: 28,
                  child: Row(
                    children: const [
                      Expanded(
                        child: _MiniTile(icon: Icons.medication_outlined),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _MiniTile(icon: Icons.shield_moon_outlined),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFF9EB3D7).withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 10),
                ),
              ]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? AppPalette.text : AppPalette.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingBubble extends StatelessWidget {
  const _FloatingBubble({
    required this.size,
    required this.color,
    required this.icon,
  });

  final double size;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Icon(icon, color: Colors.white, size: size * 0.38),
    );
  }
}

class _MiniTile extends StatelessWidget {
  const _MiniTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: const Color(0xFFF6F9FF),
      ),
      child: Icon(icon, color: AppPalette.text, size: 34),
    );
  }
}
