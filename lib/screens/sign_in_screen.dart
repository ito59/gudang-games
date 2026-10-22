import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/language.dart';
import '../state/auth_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/gradient_button.dart';
import '../widgets/page_header.dart';

/// Signing in is only needed to write: post, like or comment.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.showUnconfiguredGoogle = kDebugMode});

  /// Whether to show the Google button when no client ID is known.
  ///
  /// In a release build it is only a dead end, so it stays hidden. In debug it
  /// is shown with the reason, because silently missing UI is the harder thing
  /// to diagnose while setting this up.
  final bool showUnconfiguredGoogle;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _busy = false;
  var _googleBusy = false;
  String? _error;

  /// The platform's own words about a failed Google sign-in, shown under the
  /// message because it is usually the line that names the cause.
  String? _errorDetail;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    final auth = AuthScope.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _googleBusy = true;
      _error = null;
      _errorDetail = null;
    });

    final error = await auth.signInWithGoogle();

    if (!mounted) return;

    if (error == null && auth.isSignedIn) {
      navigator.pop(true);
      return;
    }

    setState(() {
      _googleBusy = false;
      _error = error;
      _errorDetail = auth.lastGoogleDetail;
    });
  }

  Future<void> _submit() async {
    final auth = AuthScope.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _busy = true;
      _error = null;
    });

    final error = await auth.signIn(
      email: _email.text,
      password: _password.text,
    );

    if (!mounted) return;

    if (error == null) {
      navigator.pop(true);
      return;
    }

    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          PageHeader(
            title: context.tr('Masuk', 'Sign in'),
            onBack: () => Navigator.of(context).pop(false),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.marginMobile),
              children: [
                Text(
                  context.tr(
                    'Masuk untuk posting, menyukai, dan berkomentar. Kamu tetap '
                        'bisa menjelajah tanpa akun.',
                    'Sign in to post, like and comment. Browsing works without '
                        'an account.',
                  ),
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppTheme.lg),
                if (AuthScope.of(context).supportsGoogle ||
                    widget.showUnconfiguredGoogle) ...[
                  GoogleSignInButton(
                    busy: _googleBusy,
                    onPressed: _busy ? null : _signInWithGoogle,
                  ),
                  if (!AuthScope.of(context).supportsGoogle) ...[
                    const SizedBox(height: AppTheme.sm),
                    Text(
                      'Not configured yet — set GOOGLE_SERVER_CLIENT_ID in '
                      'backend/.env. Debug builds only.',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.lg),
                  const OrDivider(),
                  const SizedBox(height: AppTheme.lg),
                ],
                _Field(
                  controller: _email,
                  label: context.tr('Email', 'Email'),
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppTheme.md),
                _Field(
                  controller: _password,
                  label: context.tr('Kata sandi', 'Password'),
                  obscure: true,
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppTheme.md),
                  Text(
                    _error!,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.tertiary,
                    ),
                  ),
                  if (_errorDetail != null) ...[
                    const SizedBox(height: AppTheme.xs),
                    Text(
                      _errorDetail!,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: AppTheme.lg),
                if (_busy)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                else
                  GradientButton(
                    icon: AppIcons.check,
                    label: context.tr('Masuk', 'Sign in'),
                    expand: true,
                    onPressed: _googleBusy ? null : _submit,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTheme.sm),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onSubmitted: onSubmitted,
          autocorrect: false,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
