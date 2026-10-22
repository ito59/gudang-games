import 'package:flutter/material.dart';

import '../l10n/language.dart';
import '../models/community_post.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'glass_panel.dart';
import 'member_avatar.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.liked,
    required this.onToggleLike,
    this.onAuthorTap,
    this.onComment,
    this.onShare,
    this.onMore,
  });

  final CommunityPost post;
  final bool liked;
  final VoidCallback onToggleLike;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  /// Opens the report and block menu. Null hides the control, so a card with
  /// nothing behind the button does not offer one.
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(post: post, onTap: onAuthorTap, onMore: onMore),
            const SizedBox(height: AppTheme.md),
            Text(
              post.body,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (post.image != null) ...[
              const SizedBox(height: AppTheme.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Bundled mock posts carry an asset path; posts from the
                      // backend carry a URL.
                      if (post.imageIsRemote)
                        Image.network(
                          post.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: AppColors.surfaceContainerHigh,
                          ),
                        )
                      else
                        Image.asset(post.image!, fit: BoxFit.cover),
                      if (post.kind == PostKind.clip)
                        const Center(
                          child: Icon(
                            AppIcons.playCircle,
                            fill: 1,
                            size: 48,
                            color: Color(0xCCFFFFFF),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            if (post.gameTag != null) ...[
              const SizedBox(height: AppTheme.md),
              _GameTag(label: post.gameTag!),
            ],
            const SizedBox(height: AppTheme.md),
            _Actions(
              post: post,
              liked: liked,
              onToggleLike: onToggleLike,
              onComment: onComment,
              onShare: onShare,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.post, this.onTap, this.onMore});

  final CommunityPost post;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar and name open the same sheet as the online strip.
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: MemberAvatar(name: post.author, accent: post.accent, size: 40),
        ),
        const SizedBox(width: AppTheme.sm),
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                ),
                Text(
                  '@${post.handle} · ${post.timeAgo}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (onMore != null)
          IconButton(
            onPressed: onMore,
            tooltip: context.tr('Lainnya', 'More'),
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              AppIcons.moreHoriz,
              size: 20,
              color: AppColors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _GameTag extends StatelessWidget {
  const _GameTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            AppIcons.videogameAsset,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppTheme.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.post,
    required this.liked,
    required this.onToggleLike,
    this.onComment,
    this.onShare,
  });

  final CommunityPost post;
  final bool liked;
  final VoidCallback onToggleLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionButton(
          icon: AppIcons.favorite,
          // The count is whatever the post carries: the screen applies a
          // pending vote optimistically before the server confirms it.
          label: '${post.likes}',
          active: liked,
          activeColor: AppColors.tertiary,
          onTap: onToggleLike,
          semanticLabel: liked
              ? context.tr('Batal suka', 'Unlike')
              : context.tr('Suka', 'Like'),
        ),
        const SizedBox(width: AppTheme.lg),
        _ActionButton(
          icon: AppIcons.modeComment,
          label: '${post.comments}',
          onTap: onComment,
          semanticLabel: context.tr('Komentar', 'Comments'),
        ),
        const Spacer(),
        _ActionButton(
          icon: AppIcons.share,
          onTap: onShare,
          semanticLabel: context.tr('Bagikan', 'Share'),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.semanticLabel,
    this.label,
    this.active = false,
    this.activeColor,
    this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final String? label;
  final bool active;
  final Color? activeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? (activeColor ?? AppColors.primary)
        : AppColors.onSurfaceVariant;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, fill: active ? 1 : 0, color: color),
              if (label != null) ...[
                const SizedBox(width: AppTheme.xs),
                Text(
                  label!,
                  style: AppTextStyles.labelSm.copyWith(color: color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
