import 'package:flutter/material.dart';

import '../models/community_post.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';

/// What the composer produced.
typedef DraftPost = ({String body, PostKind kind});

/// Writes a new post. Returns the draft, or null if dismissed.
Future<DraftPost?> showPostComposer(BuildContext context) {
  return showModalBottomSheet<DraftPost>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _PostComposer(),
  );
}

class _PostComposer extends StatefulWidget {
  const _PostComposer();

  @override
  State<_PostComposer> createState() => _PostComposerState();
}

class _PostComposerState extends State<_PostComposer> {
  static const _limit = 1000;

  final _controller = TextEditingController();
  var _kind = PostKind.update;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text.trim();
    final canPost = text.isNotEmpty && text.length <= _limit;

    return Padding(
      // Lifts the sheet above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.marginMobile,
            AppTheme.sm,
            AppTheme.marginMobile,
            AppTheme.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppTheme.lg),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text('New post', style: AppTextStyles.titleMd),
              const SizedBox(height: AppTheme.md),

              Wrap(
                spacing: AppTheme.sm,
                children: [
                  for (final kind in PostKind.composable)
                    ChoiceChip(
                      label: Text(kind.label),
                      selected: _kind == kind,
                      onSelected: (_) => setState(() => _kind = kind),
                      backgroundColor: AppColors.surfaceContainerHigh,
                      selectedColor: AppColors.primaryContainer,
                      labelStyle: AppTextStyles.labelSm.copyWith(
                        color: _kind == kind
                            ? AppColors.onPrimaryContainer
                            : AppColors.onSurfaceVariant,
                      ),
                      side: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.md),

              TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 5,
                maxLength: _limit,
                textCapitalization: TextCapitalization.sentences,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'What happened in-game?',
                  hintStyle: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainerHigh,
                  counterStyle: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.sm),

              Opacity(
                // Disabled until there is something to post, so the button
                // never fails for a reason the person cannot see.
                opacity: canPost ? 1 : 0.45,
                child: IgnorePointer(
                  ignoring: !canPost,
                  child: GradientButton(
                    icon: AppIcons.send,
                    iconFill: 1,
                    label: 'Post',
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(
                      (body: text, kind: _kind),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
