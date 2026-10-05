import 'package:flutter/material.dart';

import '../services/feed_repository.dart';
import '../services/game_repository.dart';
import '../services/member_repository.dart';
import '../services/report_repository.dart';
import '../state/chat_scope.dart';
import '../widgets/lounge_nav_bar.dart';
import 'community_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';

/// Owns the bottom navigation and swaps the destination below it.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.gameRepository,
    this.feedRepository,
    this.memberRepository,
    this.reportRepository,
  });

  /// All injectable so a test can pump the whole app without a network.
  final GameRepository? gameRepository;
  final FeedRepository? feedRepository;
  final MemberRepository? memberRepository;
  final ReportRepository? reportRepository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// Index of the Community tab in [LoungeNavBar], which owns the order.
  static const _community = 2;

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      // IndexedStack keeps each tab's scroll position across switches.
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(repository: widget.gameRepository),
          LibraryScreen(repository: widget.gameRepository),
          CommunityScreen(
            repository: widget.feedRepository,
            members: widget.memberRepository,
            reports: widget.reportRepository,
          ),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: LoungeNavBar(
        currentIndex: _index,
        // A message arriving while somebody is on another tab should be
        // visible without them going looking for it.
        unreadTabs: {
          if (ChatScope.of(context).totalUnread > 0) _community,
        },
        onTap: (index) => setState(() => _index = index),
      ),
    );
  }
}
