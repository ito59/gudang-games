import 'package:flutter/material.dart';

import '../utils/time_format.dart';

enum PostKind {
  clip('Clips'),
  squad('Squads'),
  update('Updates'),

  /// Announcements from the team, written in the dashboard rather than the
  /// app: a headline, an article under it, and a page of its own.
  news('News');

  const PostKind(this.label);

  final String label;

  /// What a member may write. News speaks for the team, so the composer does
  /// not offer it and the backend refuses it.
  static List<PostKind> get composable =>
      values.where((kind) => kind != PostKind.news).toList();
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.author,
    required this.handle,
    required this.accent,
    this.authorAvatar,
    required this.timeAgo,
    required this.body,
    required this.kind,
    this.title,
    required this.likes,
    required this.comments,
    this.image,
    this.gameTag,
    this.likedByMe = false,
  });

  /// Builds a post from the `/api/v1/feed` payload.
  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final author = json['author'];
    final published = DateTime.tryParse(
      (json['published_at'] as String?) ?? '',
    );

    return CommunityPost(
      id: '${json['id']}',
      authorId: author is Map ? (author['id'] as num?)?.toInt() ?? 0 : 0,
      author: author is Map ? (author['name'] as String?) ?? '' : '',
      handle: author is Map ? (author['handle'] as String?) ?? '' : '',
      accent: colorFrom(author is Map ? author['accent'] as String? : null),
      authorAvatar: author is Map ? author['avatar'] as String? : null,
      timeAgo: published == null ? '' : TimeFormat.relative(published),
      title: json['title'] as String?,
      body: (json['body'] as String?) ?? '',
      kind: PostKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => PostKind.update,
      ),
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      image: json['image'] as String?,
      gameTag: json['game_tag'] as String?,
      likedByMe: json['liked_by_me'] == true,
    );
  }

  /// "#14D1FF" from the backend; falls back to the brand violet.
  static Color colorFrom(String? hex) {
    if (hex == null || hex.length != 7 || !hex.startsWith('#')) {
      return const Color(0xFF7C3AED);
    }
    final value = int.tryParse(hex.substring(1), radix: 16);
    return value == null ? const Color(0xFF7C3AED) : Color(0xFF000000 | value);
  }

  final String id;

  /// The writer's member id, so their profile is one tap away.
  final int authorId;
  final String author;
  final String handle;

  /// The writer's photo, when they have one.
  final String? authorAvatar;

  /// Tint for the initials avatar, so members stay distinguishable without
  /// needing a photo for each one.
  final Color accent;
  final String timeAgo;
  final String body;
  final PostKind kind;

  /// The headline, on news and nothing else.
  final String? title;
  final int likes;
  final int comments;
  final String? image;
  final String? gameTag;

  /// Whether the signed-in member has liked this post.
  final bool likedByMe;

  bool get isNews => kind == PostKind.news;

  /// The article split into paragraphs, as the dashboard's blank lines meant.
  List<String> get paragraphs => body
      .split(RegExp(r'\n\s*\n'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  bool get imageIsRemote =>
      (image ?? '').startsWith('http://') || (image ?? '').startsWith('https://');

  CommunityPost copyWith({int? likes, int? comments, bool? likedByMe}) {
    return CommunityPost(
      id: id,
      authorId: authorId,
      author: author,
      handle: handle,
      accent: accent,
      authorAvatar: authorAvatar,
      timeAgo: timeAgo,
      body: body,
      kind: kind,
      title: title,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      image: image,
      gameTag: gameTag,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }
}
