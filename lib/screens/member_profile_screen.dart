import 'package:flutter/material.dart';

import '../l10n/language.dart';
import '../models/community_member.dart';
import '../models/community_post.dart';
import '../services/feed_repository.dart';
import '../services/member_repository.dart';
import '../services/report_repository.dart';
import '../state/auth_scope.dart';
import '../state/chat_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_panel.dart';
import '../widgets/gradient_button.dart';
import '../widgets/member_avatar.dart';
import '../widgets/news_card.dart';
import '../widgets/page_header.dart';
import '../widgets/post_card.dart';
import '../widgets/report_sheet.dart';
import '../widgets/section_title.dart';
import 'article_screen.dart';
import 'chat_screen.dart';
import 'post_actions.dart';
import 'sign_in_gate.dart';

/// Read-only profile of another player: who they are, what they have posted,
/// and the one button that connects the two of you.
///
/// The signed-in user's own profile is [ProfileScreen], which is editable and
/// carries the settings menu.
class MemberProfileScreen extends StatefulWidget {
  const MemberProfileScreen({
    super.key,
    required this.memberId,
    this.known,
    this.repository,
    this.members,
    this.reports,
  });

  final int memberId;

  /// What the caller already knows — enough to draw the header before the
  /// member call answers. Null when the tap carried nothing but an id.
  final CommunityMember? known;

  /// Injected by tests; built from the ambient [Auth] otherwise.
  final FeedRepository? repository;
  final MemberRepository? members;
  final ReportRepository? reports;

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen>
    with SignInGate, PostActions {
  FeedRepository? _repository;
  MemberRepository? _members;
  ReportRepository? _reports;

  /// Null until the member call answers; [_shown] falls back to what the
  /// caller passed so the header does not start empty.
  CommunityMember? _member;
  var _loading = true;

  /// Set while a friend call is in flight, so the button cannot be tapped
  /// into a second request.
  var _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repository != null) return;

    final auth = AuthScope.of(context);
    _repository = widget.repository ?? FeedRepository(auth: auth);
    _members = widget.members ?? MemberRepository(auth: auth);
    _reports = widget.reports ?? ReportRepository(auth: auth);
    _load();
  }

  @override
  FeedRepository get feed => _repository!;

  @override
  ReportRepository get reports => _reports!;

  @override
  MemberRepository get memberApi => _members!;

  MemberRepository get _memberApi => _members!;

  CommunityMember? get _shown => _member ?? widget.known;

  Future<void> _load() async {
    setState(() => _loading = true);

    // Together: the profile is one screen, not a header that arrives before
    // the posts under it.
    final (member, result) = await (
      _memberApi.fetch(widget.memberId),
      feed.fetchFeed(authorId: widget.memberId),
    ).wait;
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (member != null) _member = member;
      posts = result.posts;
    });
  }

  @override
  Widget build(BuildContext context) {
    final member = _shown;
    final loaded = _member;

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: member?.name ?? context.tr('Profil', 'Profile'),
            onBack: () => Navigator.of(context).pop(),
            // Not on one's own profile: there is nobody to report or block.
            trailing: loaded == null || loaded.friendship == Friendship.self
                ? null
                : IconButton(
                    onPressed: () => _moreOnMember(loaded),
                    tooltip: context.tr('Lainnya', 'More'),
                    icon: const Icon(
                      AppIcons.moreHoriz,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceContainer,
              child: ListView(
                padding: const EdgeInsets.only(
                  top: AppTheme.lg,
                  bottom: AppTheme.xl,
                ),
                children: [
                  if (member != null)
                    _Identity(member: member, full: loaded != null),
                  const SizedBox(height: AppTheme.lg),
                  if (loaded != null && loaded.blocked) ...[
                    const _BlockedNotice(),
                    const SizedBox(height: AppTheme.xl),
                  ] else if (loaded != null &&
                      loaded.friendship != Friendship.self) ...[
                    _Actions(
                      member: loaded,
                      busy: _busy,
                      onFriend: _onFriendAction,
                      onDecline: _decline,
                      onNeedsAccount: ensureSignedIn,
                    ),
                    const SizedBox(height: AppTheme.xl),
                  ],
                  if (loaded != null) ...[
                    _Stats(member: loaded),
                    const SizedBox(height: AppTheme.xl),
                  ],
                  _Gutter(child: SectionTitle(context.tr('Postingan', 'Posts'))),
                  const SizedBox(height: AppTheme.md),
                  ..._postList(member),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _postList(CommunityMember? member) {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.all(AppTheme.xl),
          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      ];
    }

    if (posts.isEmpty) {
      return [
        _Gutter(
          child: GlassPanel(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.lg),
              child: Text(
                context.tr(
                  '${member?.name ?? 'Dia'} belum membuat postingan.',
                  '${member?.name ?? 'They'} has not posted yet.',
                ),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ];
    }

    return [
      for (final post in posts) ...[
        _Gutter(
          child: post.isNews
              ? NewsCard(
                  post: post,
                  liked: post.likedByMe,
                  onOpen: () => _openArticle(post),
                )
              : PostCard(
                  post: post,
                  liked: post.likedByMe,
                  onToggleLike: () => toggleLike(post),
                  onComment: () => openComments(post),
                  onShare: () => snack(context.tr('Bagikan — segera hadir', 'Share — coming soon')),
                  onMore: () => moreOnPost(post),
                ),
        ),
        const SizedBox(height: AppTheme.md),
      ],
    ];
  }

  Future<void> _openArticle(CommunityPost post) async {
    final updated = await Navigator.of(context).push<CommunityPost>(
      MaterialPageRoute(
        builder: (_) =>
            ArticleScreen(
              post: post,
              repository: widget.repository,
              reports: widget.reports,
              members: widget.members,
            ),
      ),
    );
    if (updated != null && mounted) replacePost(updated);
  }

  /// Report or block, from the header rather than the row of buttons: these
  /// are not the ordinary things to do on somebody's profile.
  Future<void> _moreOnMember(CommunityMember member) async {
    final action = await showContentActions(
      context,
      subject: member.name,
      blockName: member.name,
      blocked: member.blocked,
    );
    if (action == null || !mounted) return;

    switch (action) {
      case ContentAction.report:
        if (!await ensureSignedIn()) return;
        if (!mounted) return;

        final filed = await showReportSheet(
          context,
          target: ReportTarget.user,
          id: '${member.id}',
          subject: member.name,
          repository: reports,
        );
        if (filed && mounted) {
          snack(
            context.tr(
              'Terima kasih — moderator akan memeriksanya.',
              'Thanks — a moderator will look at it.',
            ),
          );
        }

      case ContentAction.block:
        if (!await confirmBlock(context, name: member.name)) return;
        await _setBlocked(member, true);

      case ContentAction.unblock:
        await _setBlocked(member, false);
    }
  }

  /// Reloads rather than patching the one field: blocking also ends the
  /// friendship and empties their posts, and the server is the only thing
  /// that knows the whole of what changed.
  Future<void> _setBlocked(CommunityMember member, bool blocked) async {
    if (!await ensureSignedIn()) return;
    if (!mounted) return;

    setState(() => _busy = true);
    final now = await _memberApi.setBlocked(member.id, blocked);
    if (!mounted) return;

    setState(() => _busy = false);

    if (now == null) {
      snack(context.tr('Gagal menyimpan. Coba lagi.', 'That did not save. Try again.'));
      return;
    }

    await _load();
    if (!mounted) return;

    snack(
      now
          ? context.tr('${member.name} diblokir.', '${member.name} is blocked.')
          : context.tr('Blokir ${member.name} sudah dibuka.', '${member.name} is unblocked.'),
    );
  }

  /// What the one friend button does depends on where the pair stands.
  Future<void> _onFriendAction() async {
    final member = _member;
    if (member == null || _busy) return;
    if (!await ensureSignedIn()) return;
    if (!mounted) return;

    switch (member.friendship) {
      case Friendship.none:
        await _friendCall(
          () => _memberApi.addFriend(member.id),
          done: context.tr(
            'Permintaan pertemanan terkirim ke ${member.name}.',
            'Friend request sent to ${member.name}.',
          ),
        );
      case Friendship.requested:
        await _friendCall(
          () => _memberApi.removeFriend(member.id),
          done: context.tr(
            'Permintaan ke ${member.name} dibatalkan.',
            'Request to ${member.name} withdrawn.',
          ),
        );
      case Friendship.pending:
        await _friendCall(
          () => _memberApi.acceptFriend(member.id),
          done: context.tr(
            'Kamu dan ${member.name} sekarang berteman.',
            'You and ${member.name} are friends.',
          ),
        );
      case Friendship.friends:
        if (!await _confirmRemove(member)) return;
        if (!mounted) return;
        await _friendCall(
          () => _memberApi.removeFriend(member.id),
          done: context.tr(
            '${member.name} dihapus dari temanmu.',
            'Removed ${member.name} from your friends.',
          ),
        );
      case Friendship.self:
        break;
    }
  }

  /// Turning down a request is a separate button, not the same one worn down
  /// to a different meaning.
  Future<void> _decline() async {
    final member = _member;
    if (member == null || _busy) return;

    await _friendCall(
      () => _memberApi.removeFriend(member.id),
      done: context.tr(
        'Permintaan dari ${member.name} ditolak.',
        'Request from ${member.name} declined.',
      ),
    );
  }

  Future<void> _friendCall(
    Future<Friendship?> Function() call, {
    required String done,
  }) async {
    setState(() => _busy = true);
    final state = await call();
    if (!mounted) return;

    setState(() {
      _busy = false;
      if (state != null) _member = _member?.copyWith(friendship: state);
    });

    snack(
      state == null
          ? context.tr('Gagal menyimpan. Coba lagi.', 'That did not save. Try again.')
          : done,
    );
  }

  Future<bool> _confirmRemove(CommunityMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: Text(
          context.tr('Hapus ${member.name}?', 'Remove ${member.name}?'),
          style: AppTextStyles.titleMd.copyWith(color: AppColors.onSurface),
        ),
        content: Text(
          context.tr(
            'Kalian tidak lagi berteman. Kalian berdua bisa mengirim permintaan lagi nanti.',
            'You will stop being friends. Either of you can ask again later.',
          ),
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('Simpan teman', 'Keep')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              context.tr('Hapus', 'Remove'),
              style: TextStyle(color: AppColors.tertiary),
            ),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }
}

/// Shown in place of the Message and friend buttons, so a blocked profile
/// explains itself rather than just looking oddly empty.
class _BlockedNotice extends StatelessWidget {
  const _BlockedNotice();

  @override
  Widget build(BuildContext context) {
    return _Gutter(
      child: GlassPanel(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.lg),
          child: Row(
            children: [
              const Icon(
                AppIcons.block,
                size: 20,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: AppTheme.md),
              Expanded(
                child: Text(
                  context.tr(
                    'Kamu memblokir anggota ini. Buka blokir dari menu di atas '
                    'untuk mengirim pesan lagi.',
                    'You blocked this member. Unblock them from the menu above '
                    'to message them again.',
                  ),
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Gutter extends StatelessWidget {
  const _Gutter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMobile),
      child: child,
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.member, required this.full});

  final CommunityMember member;

  /// False while only the name and face are known, which keeps an empty bio
  /// and a wrong "Offline" off the screen until the member call answers.
  final bool full;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMobile),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: member.accent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: member.accent.withValues(alpha: 0.25),
                  blurRadius: 24,
                ),
              ],
            ),
            child: MemberAvatar(
              name: member.name,
              accent: member.accent,
              image: member.avatar,
              size: 98,
            ),
          ),
          const SizedBox(height: AppTheme.md),
          Text(
            member.name,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineLgMobile.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppTheme.xs),
          Text(
            '@${member.handle}',
            style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
          ),
          if (full) ...[
            const SizedBox(height: AppTheme.md),
            _StatusPill(member: member),
            const SizedBox(height: AppTheme.md),
            Text(
              member.bio,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    final online = member.isOnline;
    final color = online ? AppColors.online : AppColors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppTheme.sm),
          Flexible(
            child: Text(
              !online
                  ? context.tr('Offline', 'Offline')
                  : member.playing == null
                  ? context.tr('Online', 'Online')
                  : context.tr('Sedang main ${member.playing}', 'Playing ${member.playing}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.member,
    required this.busy,
    required this.onFriend,
    required this.onDecline,
    required this.onNeedsAccount,
  });

  final CommunityMember member;
  final bool busy;
  final VoidCallback onFriend;
  final VoidCallback onDecline;

  /// Messaging somebody is writing to them, so it needs an account first.
  final Future<bool> Function() onNeedsAccount;

  @override
  Widget build(BuildContext context) {
    final pending = member.friendship == Friendship.pending;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMobile),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  icon: AppIcons.chatBubble,
                  label: context.tr('Pesan', 'Message'),
                  expand: true,
                  onPressed: () => _openChat(context),
                ),
              ),
              // While they are waiting on an answer the panel below asks for
              // it in words; a second icon for the same thing only confuses.
              if (!pending) ...[
                const SizedBox(width: AppTheme.md),
                _SecondaryAction(
                  icon: _icon,
                  tooltip: _tooltip(context),
                  onPressed: busy ? null : onFriend,
                ),
              ],
            ],
          ),
          if (pending) ...[
            const SizedBox(height: AppTheme.md),
            _RequestPanel(
              member: member,
              busy: busy,
              onAccept: onFriend,
              onDecline: onDecline,
            ),
          ],
        ],
      ),
    );
  }

  IconData get _icon => switch (member.friendship) {
    Friendship.friends => AppIcons.doneAll,
    Friendship.requested => AppIcons.schedule,
    _ => AppIcons.personAdd,
  };

  String _tooltip(BuildContext context) => switch (member.friendship) {
    Friendship.friends => context.tr(
      'Berteman — ketuk untuk menghapus',
      'Friends — tap to remove',
    ),
    Friendship.requested => context.tr(
      'Permintaan terkirim — ketuk untuk membatalkan',
      'Requested — tap to withdraw',
    ),
    _ => context.tr('Tambah teman', 'Add friend'),
  };

  Future<void> _openChat(BuildContext context) async {
    final failed = context.tr(
      'Tidak bisa membuka chat itu.',
      'Could not open that chat.',
    );
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // Taken before the sign-in prompt, which is an async gap this widget's
    // context must not be read across.
    final chats = ChatScope.of(context);

    if (!await onNeedsAccount()) return;

    final chat = await chats.openWith(member.id);
    if (chat == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failed)));
      return;
    }

    // Replace so back from the chat returns to the community, not here.
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => ChatScreen(conversationId: chat.id)),
    );
  }
}

/// Shown when the other member asked first: the answer is owed here, so it is
/// spelled out rather than hidden behind an icon.
class _RequestPanel extends StatelessWidget {
  const _RequestPanel({
    required this.member,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final CommunityMember member;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(
                '${member.name} ingin berteman.',
                '${member.name} wants to be friends.',
              ),
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: AppTheme.md),
            Row(
              children: [
                Expanded(
                  child: GradientButton(
                    icon: AppIcons.check,
                    label: context.tr('Terima', 'Accept'),
                    expand: true,
                    onPressed: busy ? null : onAccept,
                  ),
                ),
                const SizedBox(width: AppTheme.md),
                _SecondaryAction(
                  icon: AppIcons.close,
                  tooltip: context.tr('Tolak', 'Decline'),
                  onPressed: busy ? null : onDecline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GlassPanel(
        radius: AppTheme.radiusLg,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Semantics(
                button: true,
                label: tooltip,
                child: Icon(
                  icon,
                  size: 22,
                  color: onPressed == null
                      ? AppColors.onSurfaceVariant
                      : AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    final stats = <({IconData icon, String value, String label})>[
      (
        icon: AppIcons.videogameAsset,
        value: '${member.gamesOwned}',
        label: context.tr('Game', 'Games'),
      ),
      (
        icon: AppIcons.schedule,
        value: '${member.hoursPlayed}',
        label: context.tr('Jam', 'Hours'),
      ),
      (
        icon: AppIcons.trophy,
        value: '${member.achievements}',
        label: context.tr('Penghargaan', 'Awards'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMobile),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: AppTheme.md),
            Expanded(
              child: GlassPanel(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.md,
                    horizontal: AppTheme.sm,
                  ),
                  child: Column(
                    children: [
                      Icon(stats[i].icon, size: 20, color: AppColors.primary),
                      const SizedBox(height: AppTheme.sm),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          stats[i].value,
                          style: AppTextStyles.titleMd.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.xs),
                      Text(
                        stats[i].label,
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
