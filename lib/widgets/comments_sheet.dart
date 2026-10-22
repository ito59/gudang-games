import 'package:flutter/material.dart';

import '../l10n/language.dart';
import '../models/community_post.dart';
import '../services/feed_repository.dart';
import '../services/report_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import 'member_avatar.dart';
import 'report_sheet.dart';

/// Reads and writes the comments on one post.
///
/// Returns how many comments were added here, so the feed can adjust its own
/// count without refetching. It is a delta rather than a total because the
/// thread is paginated: the sheet never holds every comment on a busy post.
Future<int?> showCommentsSheet(
  BuildContext context, {
  required CommunityPost post,
  required FeedRepository repository,
  required ReportRepository reports,
  required Future<bool> Function() ensureSignedIn,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _CommentsSheet(
      post: post,
      repository: repository,
      reports: reports,
      ensureSignedIn: ensureSignedIn,
    ),
  );
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({
    required this.post,
    required this.repository,
    required this.reports,
    required this.ensureSignedIn,
  });

  final CommunityPost post;
  final FeedRepository repository;
  final ReportRepository reports;
  final Future<bool> Function() ensureSignedIn;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();

  List<PostComment> _comments = const [];
  var _loading = true;
  var _sending = false;

  /// Comments written in this sheet, which is what the feed needs back.
  var _added = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final comments = await widget.repository.fetchComments(widget.post.id);
    if (!mounted) return;
    setState(() {
      _comments = comments;
      _loading = false;
    });
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;

    if (!await widget.ensureSignedIn()) return;
    if (!mounted) return;

    setState(() => _sending = true);
    final (comment, error) = await widget.repository.addComment(
      widget.post.id,
      body,
    );
    if (!mounted) return;

    setState(() {
      _sending = false;
      if (comment != null) {
        _comments = [..._comments, comment];
        _added++;
        _controller.clear();
      }
    });

    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }

  /// A long press on a comment, matching the gesture on a chat message.
  ///
  /// Only reporting: blocking from inside a sheet would empty the thread
  /// underneath the person doing it, which is a confusing place to land.
  Future<void> _report(PostComment comment) async {
    if (!await widget.ensureSignedIn()) return;
    if (!mounted) return;

    final filed = await showReportSheet(
      context,
      target: ReportTarget.comment,
      id: comment.id,
      subject: context.tr('komentar ini', 'this comment'),
      repository: widget.reports,
    );
    if (!filed || !mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Makasih — moderator akan memeriksanya.',
              'Thanks — a moderator will look at it.',
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppTheme.sm),
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.marginMobile,
                ),
                child: Row(
                  children: [
                    Text(context.tr('Komentar', 'Comments'), style: AppTextStyles.titleMd),
                    const SizedBox(width: AppTheme.sm),
                    Text(
                      // The post's own count, not the page in hand.
                      '${widget.post.comments + _added}',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(_added),
                      tooltip: context.tr('Tutup', 'Close'),
                      icon: const Icon(
                        AppIcons.close,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(AppTheme.xl),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _comments.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppTheme.xl),
                        child: Text(
                          context.tr(
                            'Belum ada komentar. Ayo tulis sesuatu.',
                            'No comments yet. Say something.',
                          ),
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.marginMobile,
                          vertical: AppTheme.sm,
                        ),
                        itemCount: _comments.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppTheme.md),
                        itemBuilder: (context, index) => _CommentTile(
                          comment: _comments[index],
                          onLongPress: () => _report(_comments[index]),
                        ),
                      ),
              ),
              const Divider(height: 1, color: AppColors.outlineVariant),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.marginMobile,
                  AppTheme.sm,
                  AppTheme.sm,
                  AppTheme.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLength: 500,
                        minLines: 1,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _send(),
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: context.tr('Tulis komentar', 'Add a comment'),
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.surfaceContainerHigh,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.md,
                            vertical: AppTheme.sm,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _sending ? null : _send,
                      tooltip: context.tr('Kirim', 'Send'),
                      icon: Icon(
                        AppIcons.send,
                        fill: 1,
                        color: _sending
                            ? AppColors.onSurfaceVariant
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.onLongPress});

  final PostComment comment;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      // Without this the press only registers on the text, not the gaps
      // between the avatar, the name and the body.
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MemberAvatar(
            name: comment.authorName,
            accent: CommunityPost.colorFrom(comment.accent),
            size: 32,
          ),
          const SizedBox(width: AppTheme.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: AppTheme.xs),
                    Text(
                      TimeFormat.relative(comment.createdAt),
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.body,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
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
