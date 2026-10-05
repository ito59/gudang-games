import 'package:flutter/material.dart';

import '../models/community_post.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'glass_panel.dart';

/// An announcement from the team, sitting in the same feed as members' posts
/// but reading as what it is: a cover, a headline, and an opening line.
///
/// The card is deliberately not a [PostCard] with extra fields. News is read,
/// not scrolled past — the whole card is one tap into the article, and the
/// counts stay as a footnote rather than the point.
class NewsCard extends StatelessWidget {
  const NewsCard({
    super.key,
    required this.post,
    required this.onOpen,
    this.liked = false,
  });

  final CommunityPost post;
  final VoidCallback onOpen;
  final bool liked;

  @override
  Widget build(BuildContext context) {
    final excerpt = post.paragraphs.isEmpty ? post.body : post.paragraphs.first;

    return GlassPanel(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
            ),
            padding: const EdgeInsets.all(AppTheme.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.image != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _Cover(post: post),
                    ),
                  ),
                  const SizedBox(height: AppTheme.md),
                ],
                Row(
                  children: [
                    const _NewsBadge(),
                    const SizedBox(width: AppTheme.sm),
                    Expanded(
                      child: Text(
                        post.timeAgo,
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.sm),
                Text(
                  post.title ?? 'From the team',
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.xs),
                Text(
                  excerpt,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppTheme.md),
                Row(
                  children: [
                    Icon(
                      AppIcons.favorite,
                      size: 16,
                      fill: liked ? 1 : 0,
                      color: liked
                          ? AppColors.tertiary
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppTheme.xs),
                    Text(
                      '${post.likes}',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppTheme.md),
                    const Icon(
                      AppIcons.modeComment,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppTheme.xs),
                    Text(
                      '${post.comments}',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Read',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(
                      AppIcons.chevronRight,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    const fallback = ColoredBox(color: AppColors.surfaceContainerHigh);

    if (post.imageIsRemote) {
      return Image.network(
        post.image!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    return Image.asset(
      post.image!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class _NewsBadge extends StatelessWidget {
  const _NewsBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.bolt, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            'NEWS',
            style: AppTextStyles.labelSm.copyWith(
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
