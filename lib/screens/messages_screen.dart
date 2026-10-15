import 'package:flutter/material.dart';

import '../models/conversation.dart';
import '../state/auth_scope.dart';
import '../state/chat_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/glass_panel.dart';
import '../widgets/member_avatar.dart';
import '../widgets/page_header.dart';
import 'chat_screen.dart';
import 'sign_in_gate.dart';

/// Conversation list, pushed from the Community header.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with SignInGate {
  var _asked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Threads belong to a member. Without one there is nothing to show and
    // nothing to do here, so ask rather than present an empty list — which
    // reads as "you have no messages" when the truth is "we do not know who
    // you are". Also catches a session ending while this screen is open.
    if (!AuthScope.of(context).isSignedIn) {
      _asked = false;
      requireSignIn();
      return;
    }

    if (_asked) return;
    _asked = true;

    // After the frame: loading notifies its listeners, and this screen is one
    // of them — asking during a build would be a setState inside a build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Threads may have moved on since the app last looked.
      if (mounted) ChatScope.of(context).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ChatScope.of(context);
    final chats = controller.conversations;

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: 'Messages',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.load,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceContainer,
              child: chats.isEmpty
                  ? _Empty(loading: controller.isLoading)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.marginMobile,
                        AppTheme.lg,
                        AppTheme.marginMobile,
                        AppTheme.xl,
                      ),
                      itemCount: chats.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppTheme.sm),
                      itemBuilder: (context, index) =>
                          _ConversationTile(chat: chats[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scrollable so the pull-to-refresh still works with nothing in the list.
class _Empty extends StatelessWidget {
  const _Empty({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.xl),
      children: [
        const SizedBox(height: AppTheme.xl),
        if (loading)
          const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          )
        else
          Text(
            'No messages yet. Open somebody\'s profile to start one.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.chat});

  final Conversation chat;

  @override
  Widget build(BuildContext context) {
    final last = chat.lastMessage;
    final unread = chat.unread > 0;

    return GlassPanel(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(conversationId: chat.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.md),
            child: Row(
              children: [
                Stack(
                  children: [
                    MemberAvatar(
                      name: chat.name,
                      accent: chat.accent,
                      image: chat.avatar,
                      size: 48,
                    ),
                    if (chat.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.online,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surfaceContainer,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppTheme.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.cardTitle.copyWith(
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (last != null) ...[
                            const SizedBox(width: AppTheme.sm),
                            Text(
                              TimeFormat.relative(last.sentAt),
                              style: AppTextStyles.labelSm.copyWith(
                                fontSize: 10,
                                color: unread
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (last != null && last.isMine) ...[
                            const Icon(
                              AppIcons.doneAll,
                              size: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppTheme.xs),
                          ],
                          Expanded(
                            child: Text(
                              last?.text ?? 'No messages yet',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMd.copyWith(
                                fontSize: 14,
                                color: unread
                                    ? AppColors.onSurface
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (unread) ...[
                            const SizedBox(width: AppTheme.sm),
                            _UnreadBadge(count: chat.unread),
                          ],
                        ],
                      ),
                    ],
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

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: AppTextStyles.labelSm.copyWith(
          fontSize: 11,
          color: AppColors.onPrimaryContainer,
        ),
      ),
    );
  }
}
