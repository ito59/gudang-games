import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, this.onLongPress});

  final ChatMessage message;

  /// Opens the report and block menu. Null on one's own messages: there is
  /// nothing to report about something you wrote yourself.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    final radius = Radius.circular(AppTheme.radiusXl);

    // A long press rather than a visible control on every bubble: reporting
    // is rare, and a flag beside each line would clutter the common case.
    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          // Keep bubbles from spanning the full width so the conversation still
          // reads as a back-and-forth.
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppTheme.sm),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: mine
                  ? const LinearGradient(
                      colors: [
                        AppColors.primaryContainer,
                        AppColors.inversePrimary,
                      ],
                    )
                  : null,
              color: mine ? null : AppColors.surfaceContainerHigh,
              border: mine
                  ? null
                  : Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.35),
                    ),
              borderRadius: BorderRadius.only(
                topLeft: radius,
                topRight: radius,
                bottomLeft: mine ? radius : const Radius.circular(4),
                bottomRight: mine ? const Radius.circular(4) : radius,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.text,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: mine
                        ? AppColors.onPrimaryContainer
                        : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      TimeFormat.clock(message.sentAt),
                      style: AppTextStyles.labelSm.copyWith(
                        fontSize: 10,
                        color: mine
                            ? AppColors.onPrimaryContainer.withValues(
                                alpha: 0.7,
                              )
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (mine) ...[
                      const SizedBox(width: AppTheme.xs),
                      Icon(
                        message.status == MessageStatus.read
                            ? AppIcons.doneAll
                            : AppIcons.check,
                        size: 13,
                        color: message.status == MessageStatus.read
                            ? AppColors.secondaryContainer
                            : AppColors.onPrimaryContainer.withValues(
                                alpha: 0.7,
                              ),
                      ),
                    ],
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

/// "Today" / "Yesterday" / date, centred between runs of messages.
class DaySeparator extends StatelessWidget {
  const DaySeparator({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            TimeFormat.daySeparator(day),
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
