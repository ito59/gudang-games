import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../services/chat_repository.dart';
import '../services/realtime.dart';
import 'auth_scope.dart';

/// Holds the member's one-to-one threads, backed by the API and kept current
/// by a socket.
///
/// A sent message appears at once and is confirmed by the server's copy; the
/// other side's messages arrive on the private channel for the thread. The
/// sender's own broadcast is excluded server-side, so nothing lands twice.
class ChatController extends ChangeNotifier {
  ChatController({this._repository, this._realtime, this._auth}) {
    _auth?.addListener(_onAuthChanged);
    _listen();
  }

  final ChatRepository? _repository;
  final Realtime? _realtime;
  final Auth? _auth;

  List<Conversation> _conversations = const [];
  StreamSubscription<RealtimeEvent>? _events;

  /// Threads already listening on their channel, so opening one twice does
  /// not subscribe twice.
  final _subscribed = <String>{};

  var _loading = false;

  List<Conversation> get conversations => List.unmodifiable(_conversations);

  bool get isLoading => _loading;

  int get totalUnread =>
      _conversations.fold(0, (sum, chat) => sum + chat.unread);

  /// Null when the thread is not held — a screen opened by id should ask for
  /// it rather than assume.
  Conversation? byId(String id) =>
      _conversations.where((chat) => chat.id == id).firstOrNull;

  int? get _viewerId => _auth?.user?.id;

  Future<void> load() async {
    final repository = _repository;
    if (repository == null || !(_auth?.isSignedIn ?? false)) return;

    _loading = true;
    notifyListeners();

    final loaded = await repository.conversations();

    _conversations = loaded;
    _loading = false;
    notifyListeners();

    for (final chat in loaded) {
      unawaited(_subscribe(chat.id));
    }
  }

  /// Opens the thread with a member, making it if this is the first message.
  /// Null when the server could not be reached.
  Future<Conversation?> openWith(int memberId) async {
    final repository = _repository;
    // Signed out there is nobody to open it as. Asking anyway would earn a
    // 401, which now ends a session that was never there.
    if (repository == null || !(_auth?.isSignedIn ?? false)) return null;

    final conversation = await repository.openWith(memberId);
    if (conversation == null) return null;

    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index < 0) {
      _conversations = [conversation, ..._conversations];
      notifyListeners();
    }

    unawaited(_subscribe(conversation.id));
    return byId(conversation.id);
  }

  /// Reads a thread's history and marks it seen. Called when it is opened.
  Future<void> loadThread(String id) async {
    final repository = _repository;
    if (repository == null) return;

    final index = _conversations.indexWhere((chat) => chat.id == id);
    if (index < 0) return;

    final messages = await repository.messages(id);
    final mine = _viewerId;

    final chat = _conversations[index];
    _replace(
      index,
      chat.copyWith(
        messages: _withReadState(
          [
            for (final message in messages)
              message.copyWith(isMine: message.authorId == mine),
          ],
          chat.theirLastReadId,
        ),
        unread: 0,
      ),
    );

    unawaited(_subscribe(id));
    // Awaited: the thread is not read until the server agrees it is.
    await repository.markRead(id);
  }

  /// Clears the badge without re-reading the thread.
  void markRead(String id) {
    final index = _conversations.indexWhere((chat) => chat.id == id);
    if (index < 0 || _conversations[index].unread == 0) return;

    _replace(index, _conversations[index].copyWith(unread: 0));
    unawaited(_repository?.markRead(id) ?? Future.value());
  }

  /// Shows the message straight away and replaces it with the server's copy.
  /// Returns a message to show when it did not save.
  Future<String?> send(String id, String text) async {
    final body = text.trim();
    if (body.isEmpty) return null;

    final repository = _repository;
    final index = _conversations.indexWhere((chat) => chat.id == id);
    if (repository == null || index < 0) return 'That message did not send.';

    final pending = ChatMessage(
      id: 'pending-${DateTime.now().microsecondsSinceEpoch}',
      text: body,
      sentAt: DateTime.now(),
      isMine: true,
      status: MessageStatus.sending,
    );

    final chat = _conversations[index];
    _replace(index, chat.copyWith(messages: [...chat.messages, pending]));

    final (:message, :error) = await repository.send(
      id,
      body,
      socketId: _realtime?.socketId,
    );

    final at = _conversations.indexWhere((chat) => chat.id == id);
    if (at < 0) return null;

    final current = _conversations[at];

    if (message == null) {
      // Rolled back rather than left looking sent. The text stays in the
      // composer, so a message the filter refused can be edited and sent
      // again instead of being retyped.
      _replace(
        at,
        current.copyWith(
          messages: current.messages
              .where((held) => held.id != pending.id)
              .toList(),
        ),
      );
      return error ?? 'That message did not send.';
    }

    _replace(
      at,
      current.copyWith(
        messages: [
          for (final held in current.messages)
            if (held.id == pending.id)
              message.copyWith(isMine: true, status: MessageStatus.sent)
            else
              held,
        ],
      ),
    );
    return null;
  }

  /// Marks one's own messages read up to where the other person has got.
  ///
  /// A tick is a claim about somebody else, so it is only ever made from
  /// what they told us — never assumed because a message came back from the
  /// server.
  static List<ChatMessage> _withReadState(
    List<ChatMessage> messages,
    int? theirLastReadId,
  ) {
    if (theirLastReadId == null) return messages;

    return [
      for (final message in messages)
        if (message.isMine &&
            message.status != MessageStatus.sending &&
            (int.tryParse(message.id) ?? 0) <= theirLastReadId)
          message.copyWith(status: MessageStatus.read)
        else
          message,
    ];
  }

  /// The other person has caught up: turn the ticks blue while they watch.
  void _markRead(String conversationId, int? lastReadId) {
    final index = _conversations.indexWhere((chat) => chat.id == conversationId);
    if (index < 0) return;

    final chat = _conversations[index];
    _replace(
      index,
      chat.copyWith(
        theirLastReadId: lastReadId,
        messages: _withReadState(chat.messages, lastReadId),
      ),
    );
  }

  /// Live messages from the other side.
  void _listen() {
    final realtime = _realtime;
    if (realtime == null) return;

    _events = realtime.events.listen((event) {
      if (event.name == 'thread.read') {
        final reader = (event.data['reader_id'] as num?)?.toInt();
        // Our own read, echoed back, says nothing about the other seat.
        if (reader != null && reader != _viewerId) {
          _markRead(
            '${event.data['conversation_id']}',
            (event.data['last_read_message_id'] as num?)?.toInt(),
          );
        }
        return;
      }

      if (event.name != 'message.sent') return;

      final payload = event.data['message'];
      if (payload is! Map<String, dynamic>) return;

      final id = '${event.data['conversation_id']}';
      final index = _conversations.indexWhere((chat) => chat.id == id);
      if (index < 0) {
        // A thread this device has not listed yet; the next load picks it up.
        unawaited(load());
        return;
      }

      final message = ChatRepository.messageFrom(payload);
      final chat = _conversations[index];

      // The socket can repeat itself across a reconnect.
      if (chat.messages.any((held) => held.id == message.id)) return;

      _replace(
        index,
        chat.copyWith(
          messages: [...chat.messages, message],
          unread: chat.unread + 1,
        ),
      );
    });
  }

  Future<void> _subscribe(String conversationId) async {
    final realtime = _realtime;
    if (realtime == null || !_subscribed.add(conversationId)) return;

    await realtime.subscribe('private-conversation.$conversationId');
  }

  void _onAuthChanged() {
    if (_auth?.isSignedIn ?? false) {
      load();
      return;
    }

    // Signed out: somebody else's messages must not stay on screen.
    _conversations = const [];
    _subscribed.clear();
    notifyListeners();
  }

  void _replace(int index, Conversation updated) {
    _conversations = [..._conversations]..[index] = updated;
    notifyListeners();
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    _events?.cancel();
    _realtime?.close();
    super.dispose();
  }
}

class ChatScope extends InheritedNotifier<ChatController> {
  const ChatScope({
    super.key,
    required ChatController super.notifier,
    required super.child,
  });

  static ChatController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ChatScope>();
    assert(scope != null, 'No ChatScope found in context');
    return scope!.notifier!;
  }
}
