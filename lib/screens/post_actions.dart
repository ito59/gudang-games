import 'package:flutter/material.dart';

import '../models/community_post.dart';
import '../services/feed_repository.dart';
import '../services/member_repository.dart';
import '../services/report_repository.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/report_sheet.dart';
import 'sign_in_gate.dart';

/// Liking, commenting and moderating, shared by every screen that shows
/// posts.
///
/// The community feed and a member's profile show the same cards and owe the
/// same behaviour — an optimistic like that rolls back, and a thread that
/// leaves the count where the server put it — so the rules live in one place
/// rather than being written twice and drifting apart.
mixin PostActions<T extends StatefulWidget> on State<T>, SignInGate<T> {
  /// Supplied by the screen, which owns its repositories.
  FeedRepository get feed;

  ReportRepository get reports;

  MemberRepository get memberApi;

  List<CommunityPost> posts = const [];

  void snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void replacePost(CommunityPost post) {
    setState(() {
      posts = [
        for (final candidate in posts)
          candidate.id == post.id ? post : candidate,
      ];
    });
  }

  /// Flips the like straight away and rolls back if the server disagrees —
  /// waiting on a round trip for a tap this small reads as a broken button.
  Future<void> toggleLike(CommunityPost post) async {
    if (!await ensureSignedIn()) return;
    if (!mounted) return;

    final liked = !post.likedByMe;
    replacePost(
      post.copyWith(
        likedByMe: liked,
        likes: (post.likes + (liked ? 1 : -1)).clamp(0, 1 << 31),
      ),
    );

    final likes = await feed.setLiked(post.id, liked);
    if (!mounted) return;

    if (likes == null) {
      replacePost(post);
      snack('That like did not save.');
      return;
    }

    replacePost(post.copyWith(likedByMe: liked, likes: likes));
  }

  Future<void> openComments(CommunityPost post) async {
    final added = await showCommentsSheet(
      context,
      post: post,
      repository: feed,
      reports: reports,
      ensureSignedIn: ensureSignedIn,
    );
    if (added == null || added == 0 || !mounted) return;

    replacePost(post.copyWith(comments: post.comments + added));
  }

  /// The menu behind a post's "More": report it, or block whoever wrote it.
  ///
  /// Both need an account — a report nobody can be held to is worthless, and
  /// a block has to belong to somebody to mean anything.
  Future<void> moreOnPost(CommunityPost post) async {
    final action = await showContentActions(
      context,
      subject: 'this post',
      blockName: post.author,
    );
    if (action == null || !mounted) return;

    switch (action) {
      case ContentAction.report:
        if (!await ensureSignedIn()) return;
        if (!mounted) return;

        final filed = await showReportSheet(
          context,
          target: ReportTarget.post,
          id: post.id,
          subject: 'this post',
          repository: reports,
        );
        if (filed) snack('Thanks — a moderator will look at it.');

      case ContentAction.block:
        await blockAuthor(post);

      case ContentAction.unblock:
        break;
    }
  }

  /// Blocks a post's author and takes everything of theirs off the screen at
  /// once, rather than leaving it there until the next refresh.
  Future<void> blockAuthor(CommunityPost post) async {
    if (!await ensureSignedIn()) return;
    if (!mounted) return;
    if (!await confirmBlock(context, name: post.author)) return;
    if (!mounted) return;

    final blocked = await memberApi.setBlocked(post.authorId, true);
    if (!mounted) return;

    if (blocked != true) {
      snack('That did not save. Try again.');
      return;
    }

    setState(() {
      posts = posts
          .where((candidate) => candidate.authorId != post.authorId)
          .toList();
    });
    snack('${post.author} is blocked.');
  }
}
