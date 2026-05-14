import 'package:flutter/material.dart';

import '../../data/models/app_user_model.dart';
import '../theme/app_metrics.dart';
import '../theme/app_theme.dart';

class HomeTopActionBar extends StatelessWidget {
  const HomeTopActionBar({
    super.key,
    required this.profile,
    required this.fallbackName,
    required this.roleLabel,
    required this.accentColors,
    required this.onMenuPressed,
    this.onEditProfile,
    this.trailingIcon = Icons.notifications_active_rounded,
  });

  final AppUserModel? profile;
  final String fallbackName;
  final String roleLabel;
  final List<Color> accentColors;
  final VoidCallback onMenuPressed;
  final VoidCallback? onEditProfile;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final displayName = profile?.displayName ?? fallbackName;
    final safeInitial = displayName.trim().isEmpty
        ? 'D'
        : String.fromCharCode(displayName.trim().runes.first).toUpperCase();
    final initials = profile?.initials ?? safeInitial;
    final photoUrl = profile?.photoUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: accentColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: accentColors.first.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              AppAnimatedMenuButton(onPressed: onMenuPressed),
              const SizedBox(width: AppSpacing.sm),
              CircleAvatar(
                radius: 19,
                backgroundColor: Colors.white24,
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null || photoUrl.isEmpty
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: AppFontSize.body,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppFontSize.title,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      roleLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: AppFontSize.caption,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEditProfile != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: onEditProfile,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                      child: const Icon(Icons.edit_rounded, color: Colors.white),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: AppSpacing.xs),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  color: Colors.white.withValues(alpha: 0.14),
                ),
                child: Icon(trailingIcon, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppAnimatedMenuButton extends StatefulWidget {
  const AppAnimatedMenuButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<AppAnimatedMenuButton> createState() => _AppAnimatedMenuButtonState();
}

class _AppAnimatedMenuButtonState extends State<AppAnimatedMenuButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward(from: 0);
    _controller.reset();
    if (!mounted) {
      return;
    }
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: _handleTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final value = _controller.value;
              return Transform.rotate(
                angle: value * 3.14,
                child: Icon(
                  value > 0.5 ? Icons.menu_open_rounded : Icons.menu_rounded,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class AnimatedHomeBottomBar extends StatelessWidget {
  const AnimatedHomeBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
    required this.activeColor,
    this.horizontalInset = AppLayout.bottomNavInset,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<HomeBottomBarItem> items;
  final Color activeColor;
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalInset,
        0,
        horizontalInset,
        AppLayout.bottomNavInset,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: activeColor.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++)
              Expanded(
                child: _AnimatedBottomBarTile(
                  item: items[index],
                  active: index == selectedIndex,
                  activeColor: activeColor,
                  onTap: () => onDestinationSelected(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HomeBottomBarItem {
  const HomeBottomBarItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _AnimatedBottomBarTile extends StatelessWidget {
  const _AnimatedBottomBarTile({
    required this.item,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final HomeBottomBarItem item;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: active
            ? activeColor.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  scale: active ? 1.08 : 0.96,
                  child: Icon(
                    active ? item.selectedIcon : item.icon,
                    size: 22,
                    color: active ? activeColor : AppPalette.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: TextStyle(
                    color: active ? activeColor : AppPalette.muted,
                    fontSize: AppFontSize.caption,
                    fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
