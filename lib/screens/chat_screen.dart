import 'package:flutter/material.dart';

import '../l10n/language.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../services/member_repository.dart';
import '../services/report_repository.dart';
import '../state/auth_scope.dart';
import '../state/chat_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/chat_composer.dart';
import '../widgets/member_avatar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/page_header.dart';
import '../widgets/report_sheet.dart';
import 'sign_in_gate.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.reports,
    this.members,
  });

  final String conversationId;

  /// Injected by tests; built from the ambient [Auth] otherwise.
  final ReportRepository? reports;
  final MemberRepository? members;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SignInGate {
  final _scroll = ScrollController();
  var _lastCount = 0;

  ReportRepository? _reports;
  MemberRepository? _members;

  @override
  void initState() {
    super.initState();
    // Reading the thread is what clears the unread badge, and the history
    // only arrives once it is opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && AuthScope.of(context).isSignedIn) {
        ChatScope.of(context).loadThread(widget.conversationId);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = AuthScope.of(context);
    _reports ??= widget.reports ?? ReportRepository(auth: auth);
    _members ??= widget.members ?? MemberRepository(auth: auth);

    // A thread is one member's half of a conversation. Signed out there is
    // nobody whose half this is — including when a session ends while the
    // thread is on screen.
    if (!AuthScope.of(context).isSignedIn) requireSignIn();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(ChatController controller, String text) async {
    final error = await controller.send(widget.conversationId, text);
    if (error == null || !mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
  }

  /// The report and block menu behind a long press on somebody else's line.
  ///
  /// Blocking from here closes the thread, because the thread is the first
  /// thing a block takes away — staying on a screen that can no longer load
  /// would be a worse answer than leaving it.
  Future<void> _actOn(ChatMessage message, Conversation chat) async {
    final action = await showContentActions(
      context,
      subject: context.tr('pesan ini', 'this message'),
      blockName: chat.name,
    );
    if (action == null || !mounted) return;

    switch (action) {
      case ContentAction.report:
        final filed = await showReportSheet(
          context,
          target: ReportTarget.message,
          id: message.id,
          subject: context.tr('pesan ini', 'this message'),
          repository: _reports!,
        );
        if (!filed || !mounted) return;
        _say(
          context.tr(
            'Makasih — moderator akan memeriksanya.',
            'Thanks — a moderator will look at it.',
          ),
        );

      case ContentAction.block:
        if (!await confirmBlock(context, name: chat.name)) return;

        final blocked = await _members!.setBlocked(chat.memberId, true);
        if (!mounted) return;

        if (blocked != true) {
          _say(
            context.tr(
              'Gagal disimpan. Coba lagi.',
              'That did not save. Try again.',
            ),
          );
          return;
        }

        await ChatScope.of(context).load();
        if (!mounted) return;

        _say(
          context.tr(
            '${chat.name} sudah diblokir.',
            '${chat.name} is blocked.',
          ),
        );
        Navigator.of(context).pop();

      case ContentAction.unblock:
        break;
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ChatScope.of(context);
    final chat = controller.byId(widget.conversationId);

    // The thread went away — signed out, or never listed. Nothing to show.
    if (chat == null) {
      return Scaffold(
        body: Column(
          children: [
            PageHeader(
              title: 'Chat',
              onBack: () => Navigator.of(context).pop(),
            ),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    // Follow the conversation when a message arrives.
    if (chat.messages.length != _lastCount) {
      _lastCount = chat.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: chat.name,
            onBack: () => Navigator.of(context).pop(),
            trailing: _Presence(chat: chat),
          ),
          Expanded(
            child: chat.messages.isEmpty
                ? _EmptyThread(name: chat.name)
                : _Thread(
                    chat: chat,
                    scroll: _scroll,
                    onMessageHeld: (message) => _actOn(message, chat),
                  ),
          ),
          ChatComposer(onSend: (text) => _send(controller, text)),
        ],
      ),
    );
  }
}

class _Presence extends StatelessWidget {
  const _Presence({required this.chat});

  final Conversation chat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chat.isOnline)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: AppTheme.xs),
              decoration: const BoxDecoration(
                color: AppColors.online,
                shape: BoxShape.circle,
              ),
            ),
          MemberAvatar(
            name: chat.name,
            accent: chat.accent,
            image: chat.avatar,
            size: 34,
          ),
        ],
      ),
    );
  }
}

class _Thread extends StatelessWidget {
  const _Thread({
    required this.chat,
    required this.scroll,
    required this.onMessageHeld,
  });

  final Conversation chat;
  final ScrollController scroll;
  final void Function(ChatMessage message) onMessageHeld;

  @override
  Widget build(BuildContext context) {
    final messages = chat.messages;

    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.md,
        vertical: AppTheme.md,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final previous = index == 0 ? null : messages[index - 1];
        final startsDay =
            previous == null ||
            !TimeFormat.sameDay(previous.sentAt, message.sentAt);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (startsDay) DaySeparator(day: message.sentAt),
            MessageBubble(
              message: message,
              // Only theirs, and only once it has an id the server knows.
              onLongPress: message.isMine || message.id.startsWith('pending-')
                  ? null
                  : () => onMessageHeld(message),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.xl),
        child: Text(
          context.tr(
            'Belum ada pesan dengan $name.\nSapa dulu, yuk.',
            'No messages with $name yet.\nSay something.',
          ),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
