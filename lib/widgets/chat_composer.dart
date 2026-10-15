import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Message input bar. The send button stays disabled until there is something
/// to send, so an empty message cannot be posted by mashing the button.
class ChatComposer extends StatefulWidget {
  const ChatComposer({super.key, required this.onSend});

  final ValueChanged<String> onSend;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  var _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    final canSend = _controller.text.trim().isNotEmpty;
    if (canSend != _canSend) setState(() => _canSend = canSend);
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    // Keep the keyboard up for a quick follow-up message.
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppTheme.md,
        right: AppTheme.md,
        top: AppTheme.sm,
        bottom: AppTheme.sm + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border(
          top: BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ConstrainedBox(
              // Grows with the text, then scrolls instead of pushing the
              // send button off screen.
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                minLines: 1,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Message',
                  hintStyle: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainerHigh,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.md,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.sm),
          _SendButton(enabled: _canSend, onPressed: _send),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1 : 0.4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryContainer, AppColors.inversePrimary],
          ),
          shape: BoxShape.circle,
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: Color.fromRGBO(179, 25, 30, 0.30),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(
                AppIcons.send,
                fill: 1,
                size: 22,
                color: AppColors.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
