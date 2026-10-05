import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/data/mock_data.dart';
import 'package:bandar_games/theme/app_theme.dart';
import 'package:bandar_games/widgets/hero_slider.dart';

Widget _wrap(Widget child, {bool disableAnimations = false}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: child,
      ),
    ),
  );
}

void main() {
  const interval = Duration(seconds: 5);

  testWidgets('advances to the next slide on its own', (tester) async {
    await tester.pumpWidget(
      _wrap(const HeroSlider(events: featuredEvents, interval: interval)),
    );

    expect(find.text(featuredEvents[0].title), findsOneWidget);

    await tester.pump(interval);
    await tester.pumpAndSettle();
    expect(find.text(featuredEvents[1].title), findsOneWidget);

    await tester.pump(interval);
    await tester.pumpAndSettle();
    expect(find.text(featuredEvents[2].title), findsOneWidget);
  });

  testWidgets('wraps around to the first slide', (tester) async {
    await tester.pumpWidget(
      _wrap(const HeroSlider(events: featuredEvents, interval: interval)),
    );

    for (var i = 0; i < featuredEvents.length; i++) {
      await tester.pump(interval);
      await tester.pumpAndSettle();
    }

    expect(find.text(featuredEvents[0].title), findsOneWidget);
  });

  testWidgets('does not auto-advance when autoPlay is off', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const HeroSlider(
          events: featuredEvents,
          interval: interval,
          autoPlay: false,
        ),
      ),
    );

    await tester.pump(interval * 3);
    await tester.pumpAndSettle();

    expect(find.text(featuredEvents[0].title), findsOneWidget);
  });

  testWidgets('honours the reduce-motion setting', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const HeroSlider(events: featuredEvents, interval: interval),
        disableAnimations: true,
      ),
    );

    await tester.pump(interval * 3);
    await tester.pumpAndSettle();

    expect(find.text(featuredEvents[0].title), findsOneWidget);
  });

  testWidgets('cancels its timer when removed from the tree', (tester) async {
    await tester.pumpWidget(
      _wrap(const HeroSlider(events: featuredEvents, interval: interval)),
    );

    // A surviving periodic timer makes the test binding fail on teardown.
    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    await tester.pump(interval * 2);
  });
}
