import 'package:flutter/material.dart';

import '../l10n/language.dart';
import '../services/notification_settings.dart';
import '../state/auth_scope.dart';
import '../state/push_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_panel.dart';
import '../widgets/page_header.dart';
import 'sign_in_gate.dart';

/// What the member wants their phone to tell them about.
///
/// Both on by default: somebody who installs a chat app expects to be told
/// when they are written to, and turning it off should be a choice they make
/// rather than one they have to find.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.repository});

  /// Injected by tests; built from the ambient [Auth] otherwise.
  final NotificationRepository? repository;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SignInGate {
  NotificationRepository? _repository;

  /// The switches show these until the server answers, which is what stops
  /// them flicking from off to on in front of somebody.
  NotificationSettings? _settings;
  var _loading = true;

  /// Set while a save is in flight, so a switch cannot be flipped twice.
  var _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!AuthScope.of(context).isSignedIn) {
      requireSignIn();
      return;
    }

    if (_repository != null) return;
    _repository =
        widget.repository ?? NotificationRepository(auth: AuthScope.of(context));
    _load();
  }

  Future<void> _load() async {
    final settings = await _repository?.fetch();
    if (!mounted) return;

    setState(() {
      _loading = false;
      _settings = settings;
    });
  }

  Future<void> _set({bool? chat, bool? news}) async {
    final current = _settings;
    if (current == null || _saving) return;

    // Both taken before the round trip, which is an async gap this context
    // must not be read across.
    final push = PushScope.maybeOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.tr(
      'Pengaturan itu gagal disimpan.',
      'That setting did not save.',
    );

    // Flipped straight away: a switch that waits on a round trip feels
    // broken, and there is a truthful state to fall back to.
    setState(() {
      _saving = true;
      _settings = current.copyWith(chat: chat, news: news);
    });

    final saved = await _repository?.save(chat: chat, news: news);
    if (!mounted) return;

    setState(() {
      _saving = false;
      // Back to what it was, rather than leaving a switch showing a
      // preference nobody holds.
      _settings = saved ?? current;
    });

    // News reaches phones by topic, so whether this one hears it is decided
    // here rather than on the server.
    if (saved != null && news != null) {
      await push?.applyNewsPreference(on: saved.news, topic: saved.newsTopic);
    }

    if (saved == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(failed)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: context.tr('Notifikasi', 'Notifications'),
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.marginMobile),
              children: [
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(AppTheme.xl),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (settings == null)
                  const _CouldNotLoad()
                else ...[
                  _Switch(
                    label: context.tr('Pesan', 'Messages'),
                    detail: context.tr(
                      'Saat ada yang mengirimi kamu pesan.',
                      'When somebody writes to you.',
                    ),
                    value: settings.chat,
                    onChanged: (on) => _set(chat: on),
                  ),
                  const SizedBox(height: AppTheme.sm),
                  _Switch(
                    label: context.tr('Kabar dari tim', 'News from the team'),
                    detail: context.tr(
                      'Game baru dan pengumuman.',
                      'New games and announcements.',
                    ),
                    value: settings.news,
                    onChanged: (on) => _set(news: on),
                  ),
                  if (!settings.pushAvailable) ...[
                    const SizedBox(height: AppTheme.md),
                    const _NotDeliverableYet(),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({
    required this.label,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      // A ListTile paints its ink on the nearest Material, and the panel is
      // only a DecoratedBox — without this the framework says so.
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: SwitchListTile.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.md,
            vertical: AppTheme.xs,
          ),
          title: Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface),
          ),
          subtitle: Text(
            detail,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Said plainly rather than leaving somebody to wonder why a switch they
/// turned on changes nothing.
class _NotDeliverableYet extends StatelessWidget {
  const _NotDeliverableYet();

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.md),
        child: Text(
          context.tr(
            'Server ini belum bisa mengirim notifikasi, jadi tidak akan ada '
            'yang masuk selama aplikasi ditutup. Pilihan kamu di sini tetap '
            'disimpan untuk nanti.',
            'This server cannot send notifications yet, so nothing will arrive '
            'while the app is closed. Your choices here are saved for when it '
            'can.',
          ),
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _CouldNotLoad extends StatelessWidget {
  const _CouldNotLoad();

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.lg),
        child: Text(
          context.tr(
            'Pengaturan kamu gagal dimuat. Tarik ke bawah atau coba lagi nanti.',
            'Could not load your settings. Pull down or try again later.',
          ),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
