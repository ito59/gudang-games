import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/game.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Plays a game inside the app.
///
/// Hosted bundles and external links both open here, so leaving the app is
/// never required to play something.
class GamePlayerScreen extends StatefulWidget {
  const GamePlayerScreen({super.key, required this.game});

  final Game game;

  @override
  State<GamePlayerScreen> createState() => _GamePlayerScreenState();
}

class _GamePlayerScreenState extends State<GamePlayerScreen> {
  /// Null when this platform has no WebView implementation.
  WebViewController? _controller;
  var _progress = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();

    // Games are built for landscape far more often than not, and the chrome
    // gets out of the way while one is running.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    try {
      _controller = _buildController();
    } catch (error) {
      // No WebView on this platform (and none in unit tests). Better a clear
      // message than a crash on a screen whose whole job is to show a page.
      _error = 'Playing games is not supported on this device.';
    }
  }

  WebViewController _buildController() {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => _progress = value / 100);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _progress = 1);
          },
          onWebResourceError: (error) {
            // Sub-resources fail all the time in games; only a failed main
            // document is worth showing the user.
            if (!error.isForMainFrame!) return;
            if (mounted) setState(() => _error = error.description);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.game.playUrl!));
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            if (_error == null && _controller != null)
              WebViewWidget(controller: _controller!)
            else
              _PlayError(
                message: _error ?? 'The player could not start.',
                game: widget.game,
              ),

            if (_progress < 1 && _error == null && _controller != null)
              LinearProgressIndicator(
                value: _progress == 0 ? null : _progress,
                minHeight: 2,
                backgroundColor: Colors.transparent,
                color: AppColors.primary,
              ),

            Positioned(
              top: AppTheme.sm,
              left: AppTheme.sm,
              child: _CloseButton(onTap: () => Navigator.of(context).pop()),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainer,
      elevation: 3,
      shadowColor: AppColors.shadow,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
    );
  }
}

class _PlayError extends StatelessWidget {
  const _PlayError({required this.message, required this.game});

  final String message;
  final Game game;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.videogameAsset,
              size: 44,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppTheme.md),
            Text(
              '${game.title} could not be loaded.',
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
