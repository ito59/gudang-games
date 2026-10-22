import 'package:flutter/material.dart';

import '../l10n/language.dart';
import '../models/community_post.dart';
import '../services/feed_repository.dart';
import '../services/member_repository.dart';
import '../services/report_repository.dart';
import '../state/auth_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_panel.dart';
import '../widgets/member_avatar.dart';
import '../widgets/page_header.dart';
import 'post_actions.dart';
import 'sign_in_gate.dart';

/// One announcement, read full page.
///
/// Liking and commenting happen here too, so the article is not a dead end
/// the way a plain reader would be. Whatever the reader changed is handed
/// back on the way out, so the feed behind it does not go stale.
class ArticleScreen extends StatefulWidget {
  const ArticleScreen({
    super.key,
    required this.post,
    this.repository,
    this.reports,
    this.members,
  });

  final CommunityPost post;

  /// Injected by tests; built from the ambient [Auth] otherwise.
  final FeedRepository? repository;

  /// Reaching the comment thread from here means reaching its report button
  /// too, so the article carries the same repositories the feed does.
  final ReportRepository? reports;
  final MemberRepository? members;

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen>
    with SignInGate, PostActions {
  FeedRepository? _repository;
  ReportRepository? _reports;
  MemberRepository? _members;

  @override
  void initState() {
    super.initState();
    posts = [widget.post];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.of(context);
    _repository ??= widget.repository ?? FeedRepository(auth: auth);
    _reports ??= widget.reports ?? ReportRepository(auth: auth);
    _members ??= widget.members ?? MemberRepository(auth: auth);
  }

  @override
  FeedRepository get feed => _repository!;

  @override
  ReportRepository get reports => _reports!;

  @override
  MemberRepository get memberApi => _members!;

  CommunityPost get _post => posts.first;

  @override
  Widget build(BuildContext context) {
    final post = _post;
    final paragraphs = post.paragraphs;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_post);
      },
      child: Scaffold(
        body: Column(
          children: [
            PageHeader(
              title: context.tr('Berita', 'News'),
              onBack: () => Navigator.of(context).pop(_post),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppTheme.xl),
                children: [
                  if (post.image != null)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _Cover(post: post),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.marginMobile,
                      AppTheme.lg,
                      AppTheme.marginMobile,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title ?? context.tr('Dari tim', 'From the team'),
                          style: AppTextStyles.headlineLgMobile.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppTheme.md),
                        _Byline(post: post),
                        if (post.gameTag != null) ...[
                          const SizedBox(height: AppTheme.md),
                          _GameTag(label: post.gameTag!),
                        ],
                        const SizedBox(height: AppTheme.lg),
                        for (final paragraph in paragraphs) ...[
                          Text(
                            paragraph,
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: AppTheme.md),
                        ],
                        const SizedBox(height: AppTheme.md),
                        _Actions(
                          post: post,
                          onToggleLike: () => toggleLike(post),
                          onComment: () => openComments(post),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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

class _Byline extends StatelessWidget {
  const _Byline({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MemberAvatar(
          name: post.author,
          accent: post.accent,
          image: post.authorAvatar,
          size: 36,
        ),
        const SizedBox(width: AppTheme.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                post.timeAgo,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
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
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
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
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.post,
    required this.onToggleLike,
    required this.onComment,
  });

  final CommunityPost post;
  final VoidCallback onToggleLike;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.md,
          vertical: AppTheme.sm,
        ),
        child: Row(
          children: [
            _Action(
              icon: AppIcons.favorite,
              label: '${post.likes}',
              semanticLabel: post.likedByMe
                  ? context.tr('Batal suka', 'Unlike')
                  : context.tr('Suka', 'Like'),
              active: post.likedByMe,
              activeColor: AppColors.tertiary,
              onTap: onToggleLike,
            ),
            const SizedBox(width: AppTheme.lg),
            _Action(
              icon: AppIcons.modeComment,
              label: '${post.comments}',
              semanticLabel: context.tr('Komentar', 'Comments'),
              onTap: onComment,
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    this.active = false,
    this.activeColor,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;

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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, fill: active ? 1 : 0, color: color),
              const SizedBox(width: AppTheme.xs),
              Text(
                label,
                style: AppTextStyles.labelSm.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
