part of 'admin_home.dart';

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DepthCard(
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
          child,
        ],
      ),
    );
  }
}

class _ApprovalTile extends StatelessWidget {
  const _ApprovalTile({
    required this.user,
    required this.onApprove,
    required this.onReject,
  });

  final AppUserModel user;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5FF),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE9E1FF),
                child: Icon(Icons.local_pharmacy_outlined),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isEmpty ? user.username : user.name,
                      style: const TextStyle(
                        fontSize: AppFontSize.bodyLarge,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '@${user.username} • ${user.email}',
                      style: const TextStyle(
                        color: AppPalette.muted,
                        fontSize: AppFontSize.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    onReject();
                  },
                  child: Text(context.tr(ar: 'رفض', en: 'Reject')),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    onApprove();
                  },
                  child: Text(context.tr(ar: 'اعتماد', en: 'Approve')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimpleUserTile extends StatelessWidget {
  const _SimpleUserTile({
    required this.user,
    required this.badgeColor,
    required this.badgeLabel,
    this.actionLabel,
    this.onAction,
  });

  final AppUserModel user;
  final Color badgeColor;
  final String badgeLabel;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 50,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isEmpty ? user.username : user.name,
                  style: const TextStyle(
                    fontSize: AppFontSize.bodyLarge,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${user.email} • @${user.username}',
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
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: AppSpacing.xs),
            TextButton(
              onPressed: () {
                onAction!();
              },
              child: Text(actionLabel!),
            ),
          ],
        ],
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
