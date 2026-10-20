import 'dart:async';

import 'package:flutter/material.dart';

import '../models/game.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'featured_card.dart';

/// Auto-advancing carousel of featured games, one [FeaturedCard] each, with a
/// dot indicator.
///
/// Autoplay pauses while the user is touching the slider and resumes when
/// they let go. It is skipped entirely when the platform asks for reduced
/// motion, and when only one slide is supplied.
class HeroSlider extends StatefulWidget {
  const HeroSlider({
    super.key,
    required this.games,
    this.autoPlay = true,
    this.interval = const Duration(seconds: 5),
    this.transition = const Duration(milliseconds: 550),
    this.onPlay,
  });

  final List<Game> games;
  final bool autoPlay;
  final Duration interval;
  final Duration transition;
  final ValueChanged<Game>? onPlay;

  @override
  State<HeroSlider> createState() => _HeroSliderState();
}

class _HeroSliderState extends State<HeroSlider> {
  static const _shadowRoom = AppTheme.md;

  final _controller = PageController();
  Timer? _timer;
  int _index = 0;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the OS "reduce motion" setting: no unattended animation.
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _restartTimer();
  }

  @override
  void didUpdateWidget(HeroSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoPlay != oldWidget.autoPlay ||
        widget.interval != oldWidget.interval ||
        widget.games.length != oldWidget.games.length) {
      _restartTimer();
    }
  }

  @override
  void dispose() {
    // A periodic timer outlives the element unless it is cancelled here.
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  bool get _canAutoPlay =>
      widget.autoPlay && !_reduceMotion && widget.games.length > 1;

  void _restartTimer() {
    _timer?.cancel();
    if (!_canAutoPlay) return;
    _timer = Timer.periodic(widget.interval, (_) => _advance());
  }

  void _advance() {
    if (!mounted || !_controller.hasClients) return;
    final next = (_index + 1) % widget.games.length;
    _controller.animateToPage(
      next,
      duration: widget.transition,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          // Extra room below the card so the button's shadow is not cut off
          // by the page view's clip.
          height: FeaturedCard.heightFor(context) + _shadowRoom,
          child: Listener(
            // Hold the rotation while a finger is down so a slide cannot be
            // yanked out from under the user mid-read.
            onPointerDown: (_) => _timer?.cancel(),
            onPointerUp: (_) => _restartTimer(),
            onPointerCancel: (_) => _restartTimer(),
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.games.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) {
                final game = widget.games[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.marginMobile,
                    0,
                    AppTheme.marginMobile,
                    _shadowRoom,
                  ),
                  child: FeaturedCard(
                    game: game,
                    onPlay: () => widget.onPlay?.call(game),
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.games.length > 1) ...[
          _Dots(count: widget.games.length, index: _index),
        ],
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}
