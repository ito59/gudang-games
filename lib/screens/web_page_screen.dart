import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/page_header.dart';

/// One of our own web pages — the privacy policy, the terms — shown inside
/// the app, so reading them never means leaving it.
///
/// Navigation stays on the page's own host: its links between the policy and
/// the terms work, a `mailto:` opens the phone's mail app — the policy asks
/// people to write in to delete an account — and anything that would wander
/// off to another site is simply not followed.
class WebPageScreen extends StatefulWidget {
  const WebPageScreen({super.key, required this.title, required this.url});

  final String title;
  final Uri url;

  @override
  State<WebPageScreen> createState() => _WebPageScreenState();
}

class _WebPageScreenState extends State<WebPageScreen> {
  /// Null when this platform has no WebView implementation.
  WebViewController? _controller;
  var _progress = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();

    try {
      _controller = _buildController();
    } catch (_) {
      // No WebView on this platform (and none in unit tests).
      _error = 'This page cannot be shown on this device.';
    }
  }

  WebViewController _buildController() {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final target = Uri.tryParse(request.url);

            if (target?.scheme == 'mailto') {
              launchUrl(target!, mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }

            return target?.host == widget.url.host
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
          onProgress: (value) {
            if (mounted) setState(() => _progress = value / 100);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _progress = 1);
          },
          onWebResourceError: (error) {
            if (!(error.isForMainFrame ?? true)) return;
            if (mounted) {
              setState(() => _error = 'Could not reach the server.');
            }
          },
        ),
      )
      ..loadRequest(widget.url);
  }

  void _retry() {
    setState(() {
      _error = null;
      _progress = 0;
    });
    _controller?.loadRequest(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          PageHeader(
            title: widget.title,
            onBack: () => Navigator.of(context).pop(),
          ),
          if (_progress < 1 && _error == null && controller != null)
            LinearProgressIndicator(
              value: _progress == 0 ? null : _progress,
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: AppColors.primary,
            ),
          Expanded(
            child: _error != null || controller == null
                ? _PageError(
                    message: _error ?? 'This page cannot be shown.',
                    onRetry: controller == null ? null : _retry,
                  )
                : WebViewWidget(controller: controller),
          ),
        ],
      ),
    );
  }
}

class _PageError extends StatelessWidget {
  const _PageError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              AppIcons.cloudOff,
              size: 40,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppTheme.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.md),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(AppIcons.refresh, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
