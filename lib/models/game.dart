class Game {
  const Game({
    required this.title,
    required this.category,
    required this.rating,
    required this.image,
    this.slug = '',
    this.categorySlug = '',
    this.description = '',
    this.playsCount = 0,
    this.playUrl,
    this.trailerUrl,
    this.isHosted = false,
  });

  /// Builds a game from the `/api/v1/games` payload.
  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      title: (json['title'] as String?) ?? 'Untitled',
      slug: (json['slug'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      playsCount: (json['plays_count'] as num?)?.toInt() ?? 0,
      // A game with no category still has to render.
      category: ((json['category'] as String?) ?? 'GAME').toUpperCase(),
      categorySlug: (json['category_slug'] as String?) ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      image: (json['image'] as String?) ?? '',
      playUrl: json['play_url'] as String?,
      trailerUrl: json['trailer_url'] as String?,
      isHosted: json['source_type'] == 'zip',
    );
  }

  final String title;

  /// Identifies the game to the backend.
  final String slug;
  final String category;

  /// Matches a [GameCategory] slug; empty when uncategorised.
  final String categorySlug;
  final double rating;
  final String description;

  /// How many times the game has been opened — its popularity.
  final int playsCount;

  /// Either a bundled asset path or an absolute URL from the backend.
  final String image;

  /// Where the game opens; null when the backend has no source for it.
  final String? playUrl;

  /// Trailer video, when one has been uploaded.
  final String? trailerUrl;

  bool get hasTrailer => (trailerUrl ?? '').isNotEmpty;

  /// True when the backend hosts the bundle rather than linking out.
  final bool isHosted;

  bool get hasImage => image.isNotEmpty;

  bool get imageIsRemote =>
      image.startsWith('http://') || image.startsWith('https://');
}
