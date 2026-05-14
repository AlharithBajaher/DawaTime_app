part of 'admin_home.dart';

class _AdminOverviewCard extends StatelessWidget {
  const _AdminOverviewCard({
    required this.adminName,
    required this.adminEmail,
    required this.adminRole,
    required this.totalUsers,
    required this.pendingCount,
    required this.pharmacistCount,
    required this.patientCount,
    required this.adminCount,
    required this.rejectedCount,
  });

  final String adminName;
  final String adminEmail;
  final String adminRole;
  final int totalUsers;
  final int pendingCount;
  final int pharmacistCount;
  final int patientCount;
  final int adminCount;
  final int rejectedCount;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _MetricData(
        label: context.tr(ar: 'الإجمالي', en: 'Total'),
        value: '$totalUsers',
      ),
      _MetricData(
        label: context.tr(ar: 'الطلبات', en: 'Requests'),
        value: '$pendingCount',
      ),
      _MetricData(
        label: context.tr(ar: 'الصيادلة', en: 'Pharmacists'),
        value: '$pharmacistCount',
      ),
      _MetricData(
        label: context.tr(ar: 'المرضى', en: 'Patients'),
        value: '$patientCount',
      ),
      _MetricData(
        label: context.tr(ar: 'الإدارة', en: 'Admins'),
        value: '$adminCount',
      ),
      _MetricData(
        label: context.tr(ar: 'المرفوضون', en: 'Rejected'),
        value: '$rejectedCount',
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adminName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      adminEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: AppFontSize.bodyLarge,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      adminRole,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppFontSize.caption,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr(
              ar: 'متابعة شاملة للحسابات وحالة الموافقات ضمن لوحة واحدة واضحة.',
              en: 'A complete snapshot of accounts and approvals in one clear workspace.',
            ),
            style: const TextStyle(
              color: Colors.white,
              height: 1.5,
              fontSize: AppFontSize.body,
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

class _MetricData {
  const _MetricData({required this.label, required this.value});

  final String label;
  final String value;
}

class _AdminMetricCard extends StatelessWidget {
  const _AdminMetricCard({required this.data});

  final _MetricData data;

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

class _AdminContentCard extends StatelessWidget {
  const _AdminContentCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return DepthCard(
      color: Colors.white.withValues(alpha: 0.96),
      borderColor: const Color(0xFFE6E2FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppFontSize.sectionTitle,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.text,
                  ),
                ),
              ),
              if (actionLabel != null && onActionTap != null)
                OutlinedButton.icon(
                  onPressed: onActionTap,
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: Text(actionLabel!),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppPalette.muted,
              fontSize: AppFontSize.body,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _AdminPageHero extends StatelessWidget {
  const _AdminPageHero({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: DepthCard(
        gradient: const LinearGradient(
          colors: [Color(0xFFF7F4FF), Color(0xFFEEF4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderColor: const Color(0xFFE1DDFF),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppFontSize.pageTitle,
                      fontWeight: FontWeight.w900,
                      color: AppPalette.text,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppPalette.muted,
                      fontSize: AppFontSize.body,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppPalette.adminPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(icon, color: AppPalette.adminPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminHighlightCard extends StatelessWidget {
  const _AdminHighlightCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DepthCard(
      gradient: const LinearGradient(
        colors: [Color(0xFFEEF5FF), Color(0xFFF8F4FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: const Color(0xFFDCE6FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: AppFontSize.sectionTitle,
              fontWeight: FontWeight.w900,
              color: AppPalette.text,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppPalette.muted,
              fontSize: AppFontSize.body,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: children,
          ),
        ],
      ),
    );
  }
}

class _QuickInsightTile extends StatelessWidget {
  const _QuickInsightTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 172,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppPalette.text,
                    fontSize: AppFontSize.title,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: AppFontSize.caption,
                    fontWeight: FontWeight.w700,
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

class _AdminHintCard extends StatelessWidget {
  const _AdminHintCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DepthCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppPalette.adminPrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, color: AppPalette.adminPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppFontSize.bodyLarge,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: AppFontSize.body,
                    height: 1.5,
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

class _AdminUserTile extends StatelessWidget {
  const _AdminUserTile({
    required this.user,
    required this.badgeColor,
    required this.badgeLabel,
    this.primaryActionLabel,
    this.secondaryActionLabel,
    this.onPrimaryAction,
    this.onSecondaryAction,
  });

  final AppUserModel user;
  final Color badgeColor;
  final String badgeLabel;
  final String? primaryActionLabel;
  final String? secondaryActionLabel;
  final Future<void> Function()? onPrimaryAction;
  final Future<void> Function()? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final displayName = user.name.trim().isEmpty ? user.username : user.name;
    final pharmacyDetails = <String>[
      if ((user.pharmacyName ?? '').trim().isNotEmpty) user.pharmacyName!.trim(),
      if ((user.pharmacyLocation ?? '').trim().isNotEmpty)
        user.pharmacyLocation!.trim(),
      if ((user.pharmacyPhone ?? '').trim().isNotEmpty)
        user.pharmacyPhone!.trim(),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  user.role == 'pharmacist'
                      ? Icons.local_pharmacy_outlined
                      : user.role == 'admin'
                      ? Icons.admin_panel_settings_outlined
                      : Icons.person_outline_rounded,
                  color: badgeColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: AppFontSize.bodyLarge,
                        fontWeight: FontWeight.w900,
                        color: AppPalette.text,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: AppPalette.muted,
                        fontSize: AppFontSize.caption,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: AppFontSize.caption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '@${user.username}',
            style: const TextStyle(
              color: AppPalette.muted,
              fontSize: AppFontSize.caption,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (pharmacyDetails.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: pharmacyDetails
                  .map(
                    (value) => _InlineInfoChip(
                      label: value,
                      color: badgeColor,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if ((primaryActionLabel != null && onPrimaryAction != null) ||
              (secondaryActionLabel != null && onSecondaryAction != null)) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (secondaryActionLabel != null && onSecondaryAction != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        onSecondaryAction!();
                      },
                      child: Text(secondaryActionLabel!),
                    ),
                  ),
                if (secondaryActionLabel != null && onSecondaryAction != null)
                  const SizedBox(width: AppSpacing.sm),
                if (primaryActionLabel != null && onPrimaryAction != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        onPrimaryAction!();
                      },
                      child: Text(primaryActionLabel!),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineInfoChip extends StatelessWidget {
  const _InlineInfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppFontSize.caption,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PasswordResetRequestTile extends StatelessWidget {
  const _PasswordResetRequestTile({
    required this.request,
    required this.onIssueCode,
  });

  final PasswordResetRequestModel request;
  final Future<void> Function() onIssueCode;

  @override
  Widget build(BuildContext context) {
    final isCodeIssued = request.isCodeSent;
    final badgeColor = isCodeIssued
        ? const Color(0xFF1E88E5)
        : const Color(0xFFF59E0B);
    final badgeLabel = isCodeIssued
        ? context.tr(ar: 'تم إصدار رمز', en: 'Code issued')
        : context.tr(ar: 'بانتظار المعالجة', en: 'Pending');
    final expiry = request.expiresAtLocal;
    final expiryLabel = expiry == null
        ? ''
        : '${expiry.hour.toString().padLeft(2, '0')}:${expiry.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeColor.withValues(alpha: 0.14),
                ),
                child: Icon(
                  Icons.lock_reset_rounded,
                  color: badgeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  request.email,
                  style: const TextStyle(
                    fontSize: AppFontSize.bodyLarge,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: AppFontSize.caption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (expiryLabel.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.tr(
                ar: 'ينتهي الرمز عند: $expiryLabel',
                en: 'Code expires at: $expiryLabel',
              ),
              style: const TextStyle(
                color: AppPalette.muted,
                fontSize: AppFontSize.caption,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: onIssueCode,
              icon: const Icon(Icons.password_rounded, size: 18),
              label: Text(context.tr(ar: 'إصدار رمز', en: 'Issue code')),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Align(
        alignment: Alignment.center,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.expand_more_rounded),
          label: Text(label),
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppPalette.muted,
          fontSize: AppFontSize.body,
        ),
      ),
    );
  }
}

class _StreamStatusCard extends StatelessWidget {
  const _StreamStatusCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF4E8),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFFFFD48A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_problem_rounded, color: Color(0xFFC97A00)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppPalette.text,
                fontSize: AppFontSize.body,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

