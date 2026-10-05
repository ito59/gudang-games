import 'package:flutter/material.dart';

import 'community_post.dart';

/// Where the signed-in member stands with somebody else, told from their own
/// side: the same row reads as `requested` to whoever asked and `pending` to
/// whoever still has to answer.
enum Friendship {
  /// Nobody has asked yet.
  none,

  /// The signed-in member asked and is waiting.
  requested,

  /// The other member asked; the answer is owed by the signed-in one.
  pending,

  friends,

  /// This is the signed-in member's own profile.
  self;

  static Friendship fromName(String? name) =>
      Friendship.values.firstWhere((value) => value.name == name,
          orElse: () => Friendship.none);
}

class CommunityMember {
  const CommunityMember({
    required this.id,
    required this.name,
    required this.handle,
    required this.accent,
    required this.playing,
    this.isOnline = false,
    required this.bio,
    required this.gamesOwned,
    required this.hoursPlayed,
    required this.achievements,
    this.avatar,
    this.friendship = Friendship.none,
    this.blocked = false,
  });

  /// Builds a member from the `/api/v1/members` payload.
  factory CommunityMember.fromJson(Map<String, dynamic> json) {
    return CommunityMember(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      handle: (json['handle'] as String?) ?? '',
      accent: CommunityPost.colorFrom(json['accent'] as String?),
      playing: json['playing'] as String?,
      isOnline: json['is_online'] == true,
      bio: (json['bio'] as String?) ?? '',
      gamesOwned: (json['games_owned'] as num?)?.toInt() ?? 0,
      hoursPlayed: (json['hours_played'] as num?)?.toInt() ?? 0,
      achievements: (json['achievements'] as num?)?.toInt() ?? 0,
      // A photo the member uploaded wins over the one Google had on file;
      // seeded members carry a bundled asset path, which [MemberAvatar]
      // recognises too.
      avatar: (json['avatar'] as String?) ?? json['google_avatar'] as String?,
      friendship: Friendship.fromName(json['friendship'] as String?),
      blocked: json['blocked'] == true,
    );
  }

  /// What a post already says about its writer, so their profile can open
  /// with a name and a face instead of a spinner. The rest — bio, stats, the
  /// friendship — only the member call knows, and the screen waits for it.
  factory CommunityMember.fromPost(CommunityPost post) => CommunityMember(
    id: post.authorId,
    name: post.author,
    handle: post.handle,
    accent: post.accent,
    avatar: post.authorAvatar,
    playing: null,
    bio: '',
    gamesOwned: 0,
    hoursPlayed: 0,
    achievements: 0,
  );

  /// The backend's user id, and what every member call is addressed to.
  final int id;
  final String name;
  final String handle;
  final Color accent;

  /// What their profile says they are into; says nothing about presence.
  final String? playing;

  /// Whether the app has heard from them in the last few minutes, as the
  /// server judges it.
  final bool isOnline;
  final String bio;
  final int gamesOwned;
  final int hoursPlayed;
  final int achievements;

  /// Photo when there is one; otherwise the initials avatar is used.
  final String? avatar;
  final Friendship friendship;

  /// Whether the signed-in member has blocked this one. Being blocked *by*
  /// them is deliberately not told — the server does not say, and the app
  /// has nothing useful to do with it.
  final bool blocked;

  bool get isFriend => friendship == Friendship.friends;

  CommunityMember copyWith({Friendship? friendship, bool? blocked}) =>
      CommunityMember(
    id: id,
    name: name,
    handle: handle,
    accent: accent,
    playing: playing,
    isOnline: isOnline,
    bio: bio,
    gamesOwned: gamesOwned,
    hoursPlayed: hoursPlayed,
    achievements: achievements,
    avatar: avatar,
    friendship: friendship ?? this.friendship,
    blocked: blocked ?? this.blocked,
  );
}
