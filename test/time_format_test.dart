import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/utils/time_format.dart';

String _two(int value) => value.toString().padLeft(2, '0');

void main() {
  group('the reader\'s own clock', () {
    test('a time from the server is shown in local time, not UTC', () {
      // What the backend sends: an instant, in UTC.
      final sent = DateTime.utc(2026, 9, 9, 7, 55);
      final onTheWall = sent.toLocal();

      expect(
        TimeFormat.clock(sent),
        '${_two(onTheWall.hour)}:${_two(onTheWall.minute)}',
      );
    });

    test('a local time is left alone', () {
      final local = DateTime(2026, 9, 9, 14, 55);

      // toLocal() on something already local must not shift it again.
      expect(TimeFormat.clock(local), '14:55');
    });

    test('the day separator follows the local date', () {
      // Late evening in Jakarta is already the next day in Greenwich, so a
      // message sent now must still read as Today.
      final now = DateTime.now();
      expect(TimeFormat.daySeparator(now.toUtc()), 'Today');

      final yesterday = now.subtract(const Duration(days: 1));
      expect(TimeFormat.daySeparator(yesterday.toUtc()), 'Yesterday');
    });

    test('two instants an hour apart across UTC midnight are one day', () {
      // 23:30 and 00:30 UTC are different days in Greenwich; whether they
      // are the same day for the reader depends on where they are, and
      // sameDay has to answer for the reader.
      final before = DateTime.utc(2026, 9, 9, 23, 30);
      final after = DateTime.utc(2026, 9, 10, 0, 30);

      expect(
        TimeFormat.sameDay(before, after),
        before.toLocal().day == after.toLocal().day,
      );
    });

    test('an elapsed time is the same whichever zone it is read in', () {
      final now = DateTime.now();
      final earlier = now.subtract(const Duration(hours: 3));

      expect(TimeFormat.relative(earlier, now: now), '3h');
      // Same instant, expressed as UTC: the answer must not change.
      expect(TimeFormat.relative(earlier.toUtc(), now: now), '3h');
    });

    test('an old message falls back to its local date', () {
      final now = DateTime.now();
      final old = now.subtract(const Duration(days: 30));
      final local = old.toLocal();

      expect(
        TimeFormat.relative(old.toUtc(), now: now),
        startsWith('${local.day} '),
      );
    });
  });
}
