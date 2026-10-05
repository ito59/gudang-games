import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Bottom `<nav>`: 80px tall, `bg-surface-container/90`, `backdrop-blur-2xl`,
/// rounded top corners. The active item is cyan on a 10% cyan pill.
class LoungeNavBar extends StatelessWidget {
  const LoungeNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadTabs = const {},
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Tabs with something waiting behind them, marked with a dot. A count
  /// belongs on the thing itself; out here the useful question is only
  /// whether it is worth a look.
  final Set<int> unreadTabs;

  static const _items = <({IconData icon, String label})>[
    (icon: AppIcons.home, label: 'Home'),
    (icon: AppIcons.sportsEsports, label: 'Library'),
    (icon: AppIcons.group, label: 'Community'),
    (icon: AppIcons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusXl),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          height: 80 + bottomInset,
          padding: EdgeInsets.only(bottom: bottomInset, left: 16, right: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: _items[i].icon,
                    label: _items[i].label,
                    selected: i == currentIndex,
                    unread: unreadTabs.contains(i),
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A dot on the corner of an icon.
///
/// Sits outside the icon's own box so it cannot nudge the row's layout —
/// the tabs must not shift sideways the moment a message arrives.
class _Marked extends StatelessWidget {
  const _Marked({required this.unread, required this.child});

  final bool unread;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!unread) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -2,
          top: -1,
          child: Semantics(
            label: 'unread',
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.tertiary,
                shape: BoxShape.circle,
                // Separates the dot from the icon behind it, whichever
                // colour the icon happens to be.
                border: Border.all(color: AppColors.surfaceContainer, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.unread,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // code.html marks the active tab with `secondary-container` (#14D1FF).
    // That cyan is the only blue accent in an otherwise violet palette, so the
    // app uses `primary` instead — the same lavender as the wordmark, section
    // titles and slider dots.
    final color = selected ? AppColors.primary : AppColors.onSurfaceVariant;

    // The pill hugs its content, so the item is centred in its slot rather
    // than stretched. The label scales down instead of overflowing when the
    // slot is narrow (small screens, large text scale).
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: Material(
          color: selected
              ? AppColors.primaryContainer.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Marked(
                    unread: unread,
                    child: Icon(
                      icon,
                      fill: selected ? 1 : 0,
                      size: 24,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: AppTheme.xs),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: (constraints.maxWidth - 24).clamp(0, 200),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        style: AppTextStyles.labelSm.copyWith(color: color),
                      ),
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
