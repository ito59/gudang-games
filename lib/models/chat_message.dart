/// How far an outgoing message has got. Only meaningful for one's own.
enum MessageStatus {
  /// On screen, not yet acknowledged by the server.
  sending,

  /// Stored. Whether the other person has seen it is not yet known.
  sent,

  /// They have read up to at least this message.
  read,
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.isMine,
    this.status = MessageStatus.sent,
    this.authorId = 0,
  });

  final String id;
  final String text;
  final DateTime sentAt;

  /// True for messages written by the signed-in user. The server does not
  /// say — it reports who wrote each one, and the controller compares that
  /// with whoever is signed in.
  final bool isMine;

  /// Who wrote it, so [isMine] can be worked out once the viewer is known.
  final int authorId;

  /// Only meaningful for outgoing messages. Defaults to [MessageStatus.sent]
  /// — a message is not read until somebody says it was.
  final MessageStatus status;

  ChatMessage copyWith({MessageStatus? status, bool? isMine}) => ChatMessage(
    id: id,
    text: text,
    sentAt: sentAt,
    isMine: isMine ?? this.isMine,
    status: status ?? this.status,
    authorId: authorId,
  );
}
