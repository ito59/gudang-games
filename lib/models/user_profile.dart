class UserProfile {
  const UserProfile({
    required this.name,
    required this.username,
    required this.bio,
    required this.location,
    required this.avatar,
    required this.gamesOwned,
    required this.hoursPlayed,
    required this.achievements,
    this.avatarUrl,
  });

  /// Builds a profile from `/api/v1/me`.
  factory UserProfile.fromJson(
    Map<String, dynamic> json, {
    required String fallbackAvatar,
  }) {
    return UserProfile(
      name: (json['name'] as String?) ?? '',
      username: (json['handle'] as String?) ?? '',
      bio: (json['bio'] as String?) ?? '',
      location: (json['location'] as String?) ?? '',
      // The bundled image stays as the backstop for a member with no photo.
      avatar: fallbackAvatar,
      // A photo the member uploaded wins over the one Google had on file:
      // choosing it was a deliberate act, signing in with Google was not.
      avatarUrl: _remote(json['avatar']) ?? json['google_avatar'] as String?,
      gamesOwned: (json['games_owned'] as num?)?.toInt() ?? 0,
      hoursPlayed: (json['hours_played'] as num?)?.toInt() ?? 0,
      achievements: (json['achievements'] as num?)?.toInt() ?? 0,
    );
  }

  /// A URL the app can fetch. `avatar` also carries bundled asset paths for
  /// seeded members, and those belong in [avatar], not here.
  static String? _remote(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return value.startsWith('http') ? value : null;
  }

  /// What the app sends back when the member edits their profile. Only the
  /// four fields they own — stats and email are not theirs to set here.
  Map<String, dynamic> toEditJson() => {
    'name': name,
    'username': username,
    'bio': bio,
    'location': location,
  };

  final String name;
  final String username;
  final String bio;
  final String location;
  /// Bundled asset path, used when there is no photo to fetch.
  final String avatar;

  /// The member's own photo: one they uploaded, or the one their Google
  /// account came with. Null leaves [avatar] to stand in.
  final String? avatarUrl;

  final int gamesOwned;
  final int hoursPlayed;
  final int achievements;

  UserProfile copyWith({
    String? name,
    String? username,
    String? bio,
    String? location,
  }) {
    return UserProfile(
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      avatar: avatar,
      avatarUrl: avatarUrl,
      gamesOwned: gamesOwned,
      hoursPlayed: hoursPlayed,
      achievements: achievements,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.name == name &&
      other.username == username &&
      other.bio == bio &&
      other.location == location &&
      other.avatar == avatar &&
      other.avatarUrl == avatarUrl &&
      other.gamesOwned == gamesOwned &&
      other.hoursPlayed == hoursPlayed &&
      other.achievements == achievements;

  @override
  int get hashCode => Object.hash(
    name,
    username,
    bio,
    location,
    avatar,
    avatarUrl,
    gamesOwned,
    hoursPlayed,
    achievements,
  );
}
