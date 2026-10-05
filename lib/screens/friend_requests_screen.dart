import 'package:flutter/material.dart';

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
import 'member_profile_screen.dart';

/// Everyone waiting on an answer from the signed-in member.
///
/// Without this the request flow would be a dead end: a request is written on
/// somebody else's account, and nothing else in the app ever shows it.
class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key, this.members});

  /// Injected by tests; built from the ambient [Auth] otherwise.
  final MemberRepository? members;

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  MemberRepository? _members;
  List<CommunityMember> _requests = const [];
  var _loading = true;

  /// Ids with a call in flight, so a row cannot be answered twice.
  final _busy = <int>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_members != null) return;

    _members = widget.members ?? MemberRepository(auth: AuthScope.of(context));
    _load();
  }

  MemberRepository get _api => _members!;

  Future<void> _load() async {
    setState(() => _loading = true);
    final requests = await _api.friendRequests();
    if (!mounted) return;

    setState(() {
      _loading = false;
      _requests = requests;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: 'Friend requests',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceContainer,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.marginMobile,
                  vertical: AppTheme.lg,
                ),
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
                  else if (_requests.isEmpty)
                    GlassPanel(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.lg),
                        child: Text(
                          'Nobody is waiting on you.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final member in _requests) ...[
                      _RequestRow(
                        member: member,
                        busy: _busy.contains(member.id),
                        onOpen: () => _open(member),
                        onAccept: () => _answer(member, accept: true),
                        onDecline: () => _answer(member, accept: false),
                      ),
                      const SizedBox(height: AppTheme.sm),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(CommunityMember member) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MemberProfileScreen(
          memberId: member.id,
          known: member,
          members: widget.members,
        ),
      ),
    );
    // They may have answered it from the profile page instead.
    if (mounted) await _load();
  }

  Future<void> _answer(CommunityMember member, {required bool accept}) async {
    setState(() => _busy.add(member.id));

    final state = accept
        ? await _api.acceptFriend(member.id)
        : await _api.removeFriend(member.id);
    if (!mounted) return;

    setState(() {
      _busy.remove(member.id);
      // Answered either way, the request is no longer waiting on anybody.
      if (state != null) {
        _requests = [..._requests]..removeWhere((r) => r.id == member.id);
      }
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            state == null
                ? 'That did not save. Try again.'
                : accept
                ? 'You and ${member.name} are friends.'
                : 'Request from ${member.name} declined.',
          ),
        ),
      );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.member,
    required this.busy,
    required this.onOpen,
    required this.onAccept,
    required this.onDecline,
  });

  final CommunityMember member;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.md),
            child: Row(
              children: [
                MemberAvatar(
                  name: member.name,
                  accent: member.accent,
                  image: member.avatar,
                  size: 44,
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
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurface,
                        ),
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
                _RowAction(
                  icon: AppIcons.check,
                  label: 'Accept ${member.name}',
                  color: AppColors.primary,
                  onPressed: busy ? null : onAccept,
                ),
                _RowAction(
                  icon: AppIcons.close,
                  label: 'Decline ${member.name}',
                  color: AppColors.onSurfaceVariant,
                  onPressed: busy ? null : onDecline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      icon: Icon(icon, size: 22, color: onPressed == null ? AppColors.onSurfaceVariant : color),
    );
  }
}
