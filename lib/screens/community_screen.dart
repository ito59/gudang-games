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
import '../widgets/news_card.dart';
import '../widgets/member_avatar.dart';
import '../widgets/member_sheet.dart';
import '../widgets/page_header.dart';
import '../widgets/post_card.dart';
import '../widgets/post_composer_sheet.dart';
import '../widgets/report_sheet.dart';
import '../widgets/section_title.dart';
import 'article_screen.dart';
import 'chat_screen.dart';
import 'friend_requests_screen.dart';
import 'member_profile_screen.dart';
import 'messages_screen.dart';
import 'post_actions.dart';
import 'sign_in_gate.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({
    super.key,
    this.repository,
    this.members,
    this.reports,
  });

  /// Injected by tests; built from the ambient [Auth] otherwise.
  final FeedRepository? repository;
  final MemberRepository? members;
  final ReportRepository? reports;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SignInGate, PostActions {
  /// null = no filter ("All").
  PostKind? _filter;

  FeedRepository? _repository;
  MemberRepository? _members;
  ReportRepository? _reports;

  /// Who is online, straight from the API. Empty until it answers.
  List<CommunityMember> _online = const [];

  /// Members waiting on a friend answer. The header only mentions them when
  /// there are any — an inbox that is always empty is just noise.
  List<CommunityMember> _requests = const [];
  var _loading = true;

  /// The member the loaded feed belongs to, so a sign-in, a sign-out or the
  /// restored session can be told apart from a rebuild.
  int? _viewer;

  /// Guards against an earlier, slower feed landing on top of a later one.
  var _loadId = 0;

  /// Set when the feed could not be loaded, so the screen can say why instead
  /// of looking like an empty community.
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.of(context);

    if (_repository == null) {
      _repository = widget.repository ?? FeedRepository(auth: auth);
      _members = widget.members ?? MemberRepository(auth: auth);
      _reports = widget.reports ?? ReportRepository(auth: auth);
      _viewer = auth.user?.id;
      _load();
      return;
    }

    // `liked_by_me` is answered for whoever the request carried. The stored
    // session is restored after the first frame, so that first feed goes out
    // anonymous and comes back with every post unliked — reload as soon as
    // the viewer is known, and again whenever it changes.
    if (auth.user?.id != _viewer) {
      _viewer = auth.user?.id;
      _load();
    }
  }

  @override
  FeedRepository get feed => _repository!;

  @override
  ReportRepository get reports => _reports!;

  @override
  MemberRepository get memberApi => _members!;

  MemberRepository get _memberApi => _members!;

  List<CommunityPost> get _visiblePosts => _filter == null
      ? posts
      : posts.where((post) => post.kind == _filter).toList();

  Future<void> _load() async {
    final id = ++_loadId;
    setState(() => _loading = true);

    // One round trip each, together: neither the strip nor the request count
    // should hold up the feed.
    final (result, online, requests) = await (
      feed.fetchFeed(),
      _memberApi.online(),
      // Signed out there is nobody to have asked, and the call would 401.
      AuthScope.of(context).isSignedIn
          ? _memberApi.friendRequests()
          : Future.value(const <CommunityMember>[]),
    ).wait;
    if (!mounted || id != _loadId) return;

    setState(() {
      _loading = false;
      posts = result.posts;
      _online = online;
      _requests = requests;
      _error = result.fromBackend ? null : result.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final posts = _visiblePosts;
    final signedIn = AuthScope.of(context).isSignedIn;

    return Column(
      children: [
        PageHeader(
          title: context.tr('Komunitas', 'Community'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_requests.isNotEmpty)
                _FriendRequestsButton(
                  count: _requests.length,
                  onPressed: _openRequests,
                ),
              _MessagesButton(
                unread: ChatScope.of(context).totalUnread,
                onPressed: _openMessages,
              ),
              IconButton(
                onPressed: _compose,
                tooltip: context.tr('Postingan baru', 'New post'),
                icon: const Icon(AppIcons.editSquare, color: AppColors.primary),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceContainer,
            child: ListView(
              padding: EdgeInsets.only(
                top: AppTheme.lg,
                bottom: 40 + 80 + bottomInset,
              ),
              children: [
                // Left out entirely while the strip is empty, so a server
                // that did not answer leaves a heading over nothing.
                if (_online.isNotEmpty) ...[
                  _Gutter(
                    child: SectionTitle(context.tr('Sedang online', 'Online now')),
                  ),
                  const SizedBox(height: AppTheme.md),
                  _OnlineStrip(members: _online, onTap: _openMember),
                  const SizedBox(height: AppTheme.xl),
                ],
                _Gutter(
                  child: Row(
                    children: [
                      const Expanded(child: SectionTitle('Feed')),
                      if (signedIn)
                        Text(
                          '@${AuthScope.of(context).user?.handle ?? ''}',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.md),
                _FilterBar(
                  selected: _filter,
                  onChanged: (kind) => setState(() => _filter = kind),
                ),
                const SizedBox(height: AppTheme.md),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(AppTheme.xl),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (_error != null)
                  _FeedProblem(message: _error!, onRetry: _load)
                else if (posts.isEmpty)
                  _EmptyFeed(filtered: _filter != null, onCompose: _compose)
                else
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
                              onAuthorTap: () => _openAuthor(post),
                              onComment: () => openComments(post),
                              onShare: () => snack(
                                context.tr(
                                  'Bagikan — segera hadir',
                                  'Share — coming soon',
                                ),
                              ),
                              onMore: () => moreOnPost(post),
                            ),
                    ),
                    const SizedBox(height: AppTheme.md),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _compose() async {
    if (!await ensureSignedIn()) return;
    if (!mounted) return;

    final draft = await showPostComposer(context);
    if (draft == null || !mounted) return;

    final (post, error) = await feed.createPost(
      body: draft.body,
      kind: draft.kind,
    );
    if (!mounted) return;

    if (post == null) {
      snack(
        error ??
            context.tr(
              'Postingan tidak bisa dikirim.',
              'The post could not be sent.',
            ),
      );
      return;
    }

    setState(() {
      posts = [post, ...posts];
      // A new post that the current filter hides would look like a failure.
      if (_filter != null && _filter != post.kind) _filter = null;
    });
  }

  /// Tapping someone asks what they want first — going straight into a chat
  /// assumes an intent the tap does not carry.
  Future<void> _openMember(CommunityMember member) async {
    final navigator = Navigator.of(context);
    final chats = ChatScope.of(context);

    final action = await showMemberSheet(context, member);
    if (action == null) return;

    switch (action) {
      case MemberAction.viewProfile:
        navigator.push(
          MaterialPageRoute(
            builder: (_) => MemberProfileScreen(
              memberId: member.id,
              known: member,
              repository: widget.repository,
              members: widget.members,
              reports: widget.reports,
            ),
          ),
        );
      case MemberAction.message:
        // Messaging somebody is writing to them, so it needs an account —
        // the same as the Message button on their profile.
        if (!await ensureSignedIn()) return;

        final chat = await chats.openWith(member.id);
        if (chat == null) {
          snack(tr('Chat itu tidak bisa dibuka.', 'Could not open that chat.'));
          return;
        }

        navigator.push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
          conversationId: chat.id,
          reports: widget.reports,
          members: widget.members,
        ),
          ),
        );

      case MemberAction.report:
        if (!await ensureSignedIn()) return;
        if (!mounted) return;

        final filed = await showReportSheet(
          context,
          target: ReportTarget.user,
          id: '${member.id}',
          subject: member.name,
          repository: reports,
        );
        if (filed) {
          snack(
            tr(
              'Makasih — moderator akan memeriksanya.',
              'Thanks — a moderator will look at it.',
            ),
          );
        }

      case MemberAction.block:
      case MemberAction.unblock:
        await _setBlocked(member, action == MemberAction.block);
    }
  }

  /// Blocking or unblocking from the online strip.
  ///
  /// The strip is reloaded rather than patched: a blocked member leaves it
  /// entirely, and so does everything of theirs in the feed, which is more
  /// than this screen can work out for itself.
  Future<void> _setBlocked(CommunityMember member, bool blocked) async {
    if (!await ensureSignedIn()) return;
    if (!mounted) return;

    if (blocked && !await confirmBlock(context, name: member.name)) return;
    if (!mounted) return;

    final now = await _memberApi.setBlocked(member.id, blocked);
    if (!mounted) return;

    if (now == null) {
      snack(
        context.tr('Gagal menyimpan. Coba lagi.', 'That did not save. Try again.'),
      );
      return;
    }

    await _load();
    if (!mounted) return;

    snack(
      now
          ? context.tr('${member.name} diblokir.', '${member.name} is blocked.')
          : context.tr(
              'Blokir ${member.name} dibuka.',
              '${member.name} is unblocked.',
            ),
    );
  }

  /// The article comes back with whatever the reader changed in it, so the
  /// card behind it does not show a stale count.
  Future<void> _openArticle(CommunityPost post) async {
    final updated = await Navigator.of(context).push<CommunityPost>(
      MaterialPageRoute(
        builder: (_) => ArticleScreen(
          post: post,
          repository: widget.repository,
          reports: widget.reports,
          members: widget.members,
        ),
      ),
    );
    if (updated != null && mounted) replacePost(updated);
  }

  /// Signing in first, so somebody who taps this lands in their messages
  /// rather than on a page that asks them to sign in and forgets why.
  Future<void> _openMessages() async {
    final navigator = Navigator.of(context);
    if (!await ensureSignedIn()) return;

    navigator.push(
      MaterialPageRoute(builder: (_) => const MessagesScreen()),
    );
  }

  Future<void> _openRequests() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FriendRequestsScreen(members: widget.members),
      ),
    );
    // Answering one changes the count, and may change a post's author too.
    if (mounted) await _load();
  }

  /// The author's name is a link to them. No sheet here: the tap already says
  /// which of the two things it wants, and their profile offers the other.
  void _openAuthor(CommunityPost post) {
    if (post.authorId == 0) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MemberProfileScreen(
          memberId: post.authorId,
          known: CommunityMember.fromPost(post),
          repository: widget.repository,
          members: widget.members,
        ),
      ),
    );
  }
}

/// Only ever built when the count is above zero, so it carries no empty
/// state of its own.
class _FriendRequestsButton extends StatelessWidget {
  const _FriendRequestsButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: context.tr('Permintaan pertemanan', 'Friend requests'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(AppIcons.personAdd, color: AppColors.primary),
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.tertiary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSm.copyWith(
                  fontSize: 10,
                  color: AppColors.background,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessagesButton extends StatelessWidget {
  const _MessagesButton({required this.unread, required this.onPressed});

  final int unread;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: context.tr('Pesan', 'Messages'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(AppIcons.chatBubble, color: AppColors.primary),
          if (unread > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.tertiary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$unread',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSm.copyWith(
                    fontSize: 10,
                    color: AppColors.background,
                  ),
                ),
              ),
            ),
        ],
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

class _OnlineStrip extends StatelessWidget {
  const _OnlineStrip({required this.members, required this.onTap});

  final List<CommunityMember> members;
  final ValueChanged<CommunityMember> onTap;

  @override
  Widget build(BuildContext context) {
    // Grows with the text scale so the name below the avatar never clips.
    final scaler = MediaQuery.textScalerOf(context);
    final labelLine = scaler.scale(AppTextStyles.labelSm.fontSize!) * (16 / 12);
    final height = 56 + AppTheme.sm + labelLine;

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMobile),
        itemCount: members.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppTheme.md),
        itemBuilder: (context, index) {
          final member = members[index];
          return _OnlineMember(member: member, onTap: () => onTap(member));
        },
      ),
    );
  }
}

class _OnlineMember extends StatelessWidget {
  const _OnlineMember({required this.member, required this.onTap});

  final CommunityMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Opacity(
                  opacity: member.isOnline ? 1 : 0.45,
                  child: MemberAvatar(
                    name: member.name,
                    accent: member.accent,
                    image: member.avatar,
                    size: 52,
                    ring: member.isOnline,
                  ),
                ),
                if (member.isOnline)
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: AppColors.online,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surfaceContainer,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              member.name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(
                color: member.isOnline
                    ? AppColors.onSurface
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final PostKind? selected;
  final ValueChanged<PostKind?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMobile),
        children: [
          _FilterChip(
            label: context.tr('Semua', 'All'),
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final kind in PostKind.values) ...[
            const SizedBox(width: AppTheme.sm),
            _FilterChip(
              label: kind.label(context),
              selected: selected == kind,
              onTap: () => onChanged(kind),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primaryContainer.withValues(alpha: 0.28)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.55)
                  : AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedProblem extends StatelessWidget {
  const _FeedProblem({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _Gutter(
      child: GlassPanel(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.xl,
            horizontal: AppTheme.md,
          ),
          child: Column(
            children: [
              Icon(
                AppIcons.cloudOff,
                size: 40,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: AppTheme.md),
              Text(
                context.tr('Feed gagal dimuat', 'The feed did not load'),
                style: AppTextStyles.cardTitle,
              ),
              const SizedBox(height: AppTheme.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppTheme.md),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(AppIcons.refresh, size: 18),
                label: Text(context.tr('Coba lagi', 'Try again')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.filtered, required this.onCompose});

  final bool filtered;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    return _Gutter(
      child: GlassPanel(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.xl,
            horizontal: AppTheme.md,
          ),
          child: Column(
            children: [
              Icon(
                AppIcons.forum,
                size: 40,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: AppTheme.md),
              Text(
                context.tr('Belum ada apa-apa', 'Nothing here yet'),
                style: AppTextStyles.cardTitle,
              ),
              const SizedBox(height: AppTheme.xs),
              Text(
                filtered
                    ? context.tr(
                        'Tidak ada postingan yang cocok dengan filter ini.',
                        'No posts match this filter.',
                      )
                    : context.tr(
                        'Jadilah yang pertama memposting sesuatu.',
                        'Be the first to post something.',
                      ),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (!filtered) ...[
                const SizedBox(height: AppTheme.md),
                TextButton.icon(
                  onPressed: onCompose,
                  icon: const Icon(AppIcons.editSquare, size: 18),
                  label: Text(context.tr('Tulis postingan', 'Write a post')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
