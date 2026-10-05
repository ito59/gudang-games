import 'game.dart';

class FeaturedEvent {
  const FeaturedEvent({
    required this.title,
    required this.description,
    required this.season,
    required this.isLive,
    required this.image,
    this.game,
  });

  /// Builds a slide from the `/api/v1/featured` payload.
  factory FeaturedEvent.fromJson(Map<String, dynamic> json) {
    final game = json['game'];

    return FeaturedEvent(
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      season: (json['season'] as String?) ?? '',
      isLive: json['is_live'] == true,
      image: (json['image'] as String?) ?? '',
      game: game is Map<String, dynamic> ? Game.fromJson(game) : null,
    );
  }

  final String title;
  final String description;
  final String season;
  final bool isLive;
  final String image;

  /// Set when an admin promoted a game to the carousel, so the slide can open
  /// that game rather than being decoration.
  final Game? game;

  bool get imageIsRemote =>
      image.startsWith('http://') || image.startsWith('https://');
}
