import 'package:flutter/material.dart';

import 'chat_message.dart';

class Conversation {
  const Conversation({
    required this.id,
    required this.memberId,
    required this.name,
    required this.handle,
    required this.accent,
    required this.messages,
    this.avatar,
    this.playing,
    this.isOnline = false,
    this.unread = 0,
    this.theirLastReadId,
  });

  final String id;

  /// The other person's member id, which is what opens the thread.
  final int memberId;
  final String name;
  final String handle;
  final Color accent;
  final List<ChatMessage> messages;
  final String? avatar;

  /// What the other person's profile says they are playing.
  final String? playing;

  /// Whether the other person has the app open, as the server judges it.
  final bool isOnline;
  final int unread;

  /// The id of the last message the other person has read, or null while
  /// they have never opened the thread. What turns one's own ticks blue.
  final int? theirLastReadId;


  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  Conversation copyWith({
    List<ChatMessage>? messages,
    int? unread,
    int? theirLastReadId,
  }) {
    return Conversation(
      id: id,
      memberId: memberId,
      name: name,
      handle: handle,
      accent: accent,
      messages: messages ?? this.messages,
      avatar: avatar,
      playing: playing,
      isOnline: isOnline,
      unread: unread ?? this.unread,
      theirLastReadId: theirLastReadId ?? this.theirLastReadId,
    );
  }
}
