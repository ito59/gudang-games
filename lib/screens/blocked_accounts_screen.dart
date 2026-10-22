import 'package:flutter/material.dart';

import '../l10n/language.dart';
import '../models/community_member.dart';
import '../services/member_repository.dart';
import '../state/auth_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_panel.dart';
import '../widgets/member_avatar.dart';
import '../widgets/page_header.dart';
import 'sign_in_gate.dart';

/// Everyone the signed-in member has blocked, and the way back.
///
/// Blocking is deliberately quiet everywhere else — nothing announces it and
/// the blocked member is never told — which is exactly why this list has to
/// exist. A decision with no visible record is one nobody can revisit.
class BlockedAccountsScreen extends StatefulWidget {
  const BlockedAccountsScreen({super.key, this.members});

  /// Injected by tests; built from the ambient [Auth] otherwise.
  final MemberRepository? members;

  @override
  State<BlockedAccountsScreen> createState() => _BlockedAccountsScreenState();
}

class _BlockedAccountsScreenState extends State<BlockedAccountsScreen>
    with SignInGate {
  MemberRepository? _members;

  List<CommunityMember> _blocked = const [];
  var _loading = true;

  /// Ids with an unblock in flight, so a second tap cannot send a second
  /// request for the same member.
  final _busy = <int>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // The list is one member's own. Signed out there is nobody whose it is.
    if (!AuthScope.of(context).isSignedIn) {
      requireSignIn();
      return;
    }

    if (_members != null) return;
    _members = widget.members ?? MemberRepository(auth: AuthScope.of(context));
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final blocked = await _members!.blocked();
    if (!mounted) return;

    setState(() {
      _blocked = blocked;
      _loading = false;
    });
  }

  Future<void> _unblock(CommunityMember member) async {
    if (!_busy.add(member.id)) return;
    setState(() {});

    final blocked = await _members!.setBlocked(member.id, false);
    if (!mounted) return;

    setState(() {
      _busy.remove(member.id);
      // Off the list straight away when it worked: this screen is only the
      // blocked ones, so an unblocked member has no row left to sit in.
      if (blocked == false) {
        _blocked = _blocked.where((held) => held.id != member.id).toList();
      }
    });

    if (blocked != false) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              context.tr('Gagal menyimpan. Coba lagi.', 'That did not save. Try again.'),
            ),
          ),
        );
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.tr('Blokir ${member.name} sudah dibuka.', '${member.name} is unblocked.'))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: context.tr('Akun diblokir', 'Blocked accounts'),
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceContainer,
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.marginMobile,
                        AppTheme.lg,
                        AppTheme.marginMobile,
                        AppTheme.xl,
                      ),
                      children: [
                        if (_blocked.isEmpty)
                          const _Empty()
                        else ...[
                          Text(
                            context.tr(
                              'Mereka tidak bisa mengirim pesan ke kamu atau melihat postinganmu, '
                              'dan mereka tidak diberi tahu.',
                              'They cannot message you or see your posts, and '
                              'they have not been told.',
                            ),
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppTheme.lg),
                          for (final member in _blocked) ...[
                            _BlockedRow(
                              member: member,
                              busy: _busy.contains(member.id),
                              onUnblock: () => _unblock(member),
                            ),
                            const SizedBox(height: AppTheme.sm),
                          ],
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedRow extends StatelessWidget {
  const _BlockedRow({
    required this.member,
    required this.busy,
    required this.onUnblock,
  });

  final CommunityMember member;
  final bool busy;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.md),
        child: Row(
          children: [
            MemberAvatar(
              name: member.name,
              accent: member.accent,
              image: member.avatar,
              size: 40,
            ),
            const SizedBox(width: AppTheme.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                  ),
                  Text(
                    '@${member.handle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: busy ? null : onUnblock,
              child: Text(
                busy ? context.tr('Memproses…', 'Working…') : context.tr('Buka blokir', 'Unblock'),
                style: AppTextStyles.labelSm.copyWith(
                  color: busy ? AppColors.onSurfaceVariant : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.xl),
        child: Column(
          children: [
            const Icon(
              AppIcons.block,
              size: 32,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppTheme.md),
            Text(
              context.tr('Kamu belum memblokir siapa pun.', 'You have not blocked anyone.'),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
