import 'package:flutter/material.dart';

import '../services/report_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'gradient_button.dart';

/// What somebody picked from [showContentActions].
enum ContentAction { report, block, unblock }

/// The small menu behind a message's long press and a post's "More".
///
/// Report and block are offered together because they answer the same moment
/// in two different ways: one asks us to look at it, the other is the
/// reporter deciding for themselves and needing nobody's agreement.
Future<ContentAction?> showContentActions(
  BuildContext context, {
  required String subject,
  String? blockName,
  bool blocked = false,
}) {
  return showModalBottomSheet<ContentAction>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.marginMobile,
          AppTheme.sm,
          AppTheme.marginMobile,
          AppTheme.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Handle(),
            _ActionTile(
              icon: AppIcons.flag,
              label: 'Report $subject',
              onTap: () => Navigator.of(context).pop(ContentAction.report),
            ),
            if (blockName != null) ...[
              const SizedBox(height: AppTheme.sm),
              _ActionTile(
                icon: AppIcons.block,
                label: blocked ? 'Unblock $blockName' : 'Block $blockName',
                danger: !blocked,
                onTap: () => Navigator.of(context).pop(
                  blocked ? ContentAction.unblock : ContentAction.block,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Asks for a reason and files the report. Returns whether one was filed.
///
/// The reasons come from the server, so the words in this sheet and the words
/// in the moderation queue are the same words.
Future<bool> showReportSheet(
  BuildContext context, {
  required ReportTarget target,
  required String id,
  required String subject,
  required ReportRepository repository,
}) async {
  final filed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ReportSheet(
      target: target,
      id: id,
      subject: subject,
      repository: repository,
    ),
  );

  return filed ?? false;
}

/// Blocking is quiet but not small: it ends the thread and the friendship.
/// Saying so before it happens is the difference between a decision and a
/// surprise.
Future<bool> confirmBlock(BuildContext context, {required String name}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surfaceContainer,
      title: Text(
        'Block $name?',
        style: AppTextStyles.titleMd.copyWith(color: AppColors.onSurface),
      ),
      content: Text(
        'You will not see their posts or messages, and they cannot reach '
        'you. They are not told. You can undo this from your profile.',
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Block', style: TextStyle(color: AppColors.tertiary)),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({
    required this.target,
    required this.id,
    required this.subject,
    required this.repository,
  });

  final ReportTarget target;
  final String id;
  final String subject;
  final ReportRepository repository;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _note = TextEditingController();

  /// Opened with the fallback list so there is never a spinner between the
  /// tap and the reasons; the server's list replaces it when it arrives.
  var _reasons = ReportRepository.fallbackReasons;
  String? _chosen;
  var _sending = false;

  @override
  void initState() {
    super.initState();
    _loadReasons();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadReasons() async {
    final reasons = await widget.repository.reasons();
    if (!mounted) return;
    setState(() => _reasons = reasons);
  }

  Future<void> _submit() async {
    final reason = _chosen;
    if (reason == null || _sending) return;

    setState(() => _sending = true);

    final error = await widget.repository.submit(
      target: widget.target,
      id: widget.id,
      reason: reason,
      note: _note.text,
    );
    if (!mounted) return;

    setState(() => _sending = false);

    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: height * 0.85),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.marginMobile,
              AppTheme.sm,
              AppTheme.marginMobile,
              AppTheme.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Handle(),
                Text('Report ${widget.subject}', style: AppTextStyles.titleMd),
                const SizedBox(height: AppTheme.xs),
                Text(
                  'A moderator reads every report. The member is not told who '
                  'reported them.',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppTheme.lg),
                for (final reason in _reasons)
                  _ReasonTile(
                    reason: reason,
                    selected: _chosen == reason.value,
                    onTap: () => setState(() => _chosen = reason.value),
                  ),
                const SizedBox(height: AppTheme.md),
                TextField(
                  controller: _note,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Anything else we should know? (optional)',
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.surfaceContainerHigh,
                    contentPadding: const EdgeInsets.all(AppTheme.md),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.lg),
                GradientButton(
                  label: _sending ? 'Sending…' : 'Send report',
                  icon: AppIcons.flag,
                  expand: true,
                  // Nothing is sent until a reason is picked: "reported, no
                  // reason given" is a queue entry nobody can act on.
                  onPressed: _chosen == null || _sending ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final ReportReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusLg);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.sm),
      child: Material(
        color: selected
            ? AppColors.primaryContainer.withValues(alpha: 0.25)
            : AppColors.surfaceContainerHigh,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.md,
              vertical: 13,
            ),
            child: Row(
              children: [
                Icon(
                  selected ? AppIcons.check : null,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppTheme.sm),
                Expanded(
                  child: Text(
                    reason.label,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: selected
                          ? AppColors.onSurface
                          : AppColors.onSurfaceVariant,
                    ),
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusLg);
    final foreground = danger ? AppColors.tertiary : AppColors.onSurface;

    return Material(
      color: AppColors.surfaceContainerHigh,
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
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: AppTheme.lg),
        decoration: BoxDecoration(
          color: AppColors.outlineVariant,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
