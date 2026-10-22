import 'package:flutter/material.dart';

import '../l10n/language.dart';
import '../models/community_member.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'member_avatar.dart';

/// What the user picked in [showMemberSheet].
enum MemberAction { viewProfile, message, report, block, unblock }

/// Asks what to do with another player instead of assuming they want to chat.
Future<MemberAction?> showMemberSheet(
  BuildContext context,
  CommunityMember member,
) {
  return showModalBottomSheet<MemberAction>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _MemberSheet(member: member),
  );
}

class _MemberSheet extends StatelessWidget {
  const _MemberSheet({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    final status = member.playing == null
        ? context.tr('Offline', 'Offline')
        : context.tr('Sedang main ${member.playing}', 'Playing ${member.playing}');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.marginMobile,
          AppTheme.sm,
          AppTheme.marginMobile,
          AppTheme.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle.
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppTheme.lg),
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Row(
              children: [
                MemberAvatar(
                  name: member.name,
                  accent: member.accent,
                  image: member.avatar,
                  size: 52,
                ),
                const SizedBox(width: AppTheme.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 17),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (member.isOnline)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(
                                right: AppTheme.xs,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.online,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Flexible(
                            child: Text(
                              status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSm.copyWith(
                                color: member.isOnline
                                    ? AppColors.online
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.lg),
            _SheetAction(
              icon: AppIcons.accountCircle,
              label: context.tr('Lihat profil', 'View profile'),
              onTap: () => Navigator.of(context).pop(MemberAction.viewProfile),
            ),
            const SizedBox(height: AppTheme.sm),
            if (!member.blocked) ...[
              _SheetAction(
                icon: AppIcons.chatBubble,
                label: context.tr('Pesan', 'Message'),
                primary: true,
                onTap: () => Navigator.of(context).pop(MemberAction.message),
              ),
              const SizedBox(height: AppTheme.lg),
            ],
            // Set apart from the three above by the divider: these are about
            // ending something, and they should not sit a thumb's width from
            // "Message".
            const Divider(height: 1, color: AppColors.outlineVariant),
            const SizedBox(height: AppTheme.md),
            _SheetAction(
              icon: AppIcons.flag,
              label: context.tr('Laporkan ${member.name}', 'Report ${member.name}'),
              onTap: () => Navigator.of(context).pop(MemberAction.report),
            ),
            const SizedBox(height: AppTheme.sm),
            _SheetAction(
              icon: AppIcons.block,
              label: member.blocked
                  ? context.tr('Buka blokir ${member.name}', 'Unblock ${member.name}')
                  : context.tr('Blokir ${member.name}', 'Block ${member.name}'),
              danger: !member.blocked,
              onTap: () => Navigator.of(
                context,
              ).pop(member.blocked ? MemberAction.unblock : MemberAction.block),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusLg);
    final foreground = primary
        ? AppColors.onPrimaryContainer
        : danger
        ? AppColors.tertiary
        : AppColors.onSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: primary
            ? const LinearGradient(
                colors: [AppColors.primaryContainer, AppColors.inversePrimary],
              )
            : null,
        color: primary ? null : AppColors.surfaceContainerHigh,
        borderRadius: radius,
        border: primary
            ? null
            : Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.5),
              ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.md,
              vertical: 14,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: foreground),
                const SizedBox(width: AppTheme.md),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMd.copyWith(color: foreground),
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
