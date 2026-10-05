import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// `Image.asset` resolves through the async image cache, which the test
/// binding does not drive. Without this, goldens render empty image frames.
Future<void> precacheAllImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  await tester.pumpAndSettle();
}
