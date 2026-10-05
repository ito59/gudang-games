import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/game.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Plays a game's trailer.
class TrailerScreen extends StatefulWidget {
  const TrailerScreen({super.key, required this.game});

  final Game game;

  @override
  State<TrailerScreen> createState() => _TrailerScreenState();
}

class _TrailerScreenState extends State<TrailerScreen> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.game.trailerUrl!),
      );
      await controller.initialize();
      await controller.setLooping(false);
      await controller.play();

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (error) {
      // No video plugin on this platform, or the file will not decode.
      if (mounted) setState(() => _error = 'This trailer could not be played.');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;

    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: switch ((controller, _error)) {
                (_, final String message?) => _TrailerError(message: message),
                (final VideoPlayerController c, _) => AspectRatio(
                  aspectRatio: c.value.aspectRatio,
                  child: GestureDetector(
                    onTap: _togglePlay,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(c),
                        if (!c.value.isPlaying)
                          const Icon(
                            AppIcons.playCircle,
                            fill: 1,
                            size: 64,
                            color: Color(0xCCFFFFFF),
                          ),
                      ],
                    ),
                  ),
                ),
                _ => const CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              },
            ),

            if (controller != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: AppColors.primary,
                    bufferedColor: Color(0x33FFFFFF),
                    backgroundColor: Color(0x22FFFFFF),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.md,
                    horizontal: AppTheme.sm,
                  ),
                ),
              ),

            Positioned(
              top: AppTheme.sm,
              left: AppTheme.sm,
              child: Material(
                color: Colors.black.withValues(alpha: 0.55),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Tooltip(
                    message: 'Back',
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        AppIcons.arrowBack,
                        size: 22,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrailerError extends StatelessWidget {
  const _TrailerError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.xl),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMd.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
