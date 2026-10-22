import '../l10n/language.dart';

/// Small date helpers so the app stays free of the `intl` dependency.
/// Times are shown in 24-hour form, matching the app's Indonesian audience.
///
/// Every method converts to the reader's own timezone first. The backend
/// stores and sends UTC — which is right — and `DateTime.parse` keeps it that
/// way, so reading `.hour` off what the server sent shows the clock in
/// Greenwich rather than the one on the wall. `toLocal()` is a no-op on a
/// time that is already local, so converting here is safe wherever it is
/// called from, and cannot be forgotten at a new call site.
class TimeFormat {
  const TimeFormat._();

  static String clock(DateTime time) {
    final local = time.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// "Today" / "Yesterday" / "12 Mar 2026" for a chat day separator.
  static String daySeparator(DateTime time, {DateTime? now}) {
    final today = _dateOnly((now ?? DateTime.now()).toLocal());
    final day = _dateOnly(time.toLocal());
    final difference = today.difference(day).inDays;

    if (difference == 0) return tr('Hari ini', 'Today');
    if (difference == 1) return tr('Kemarin', 'Yesterday');
    return '${day.day} ${_month(day.month)} ${day.year}';
  }

  /// Compact "now / 5m / 3h / 2d / 12 Mar" for a conversation list.
  static String relative(DateTime time, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    // An elapsed duration is the same in any timezone; the date it falls
    // back to at a week old is not.
    final diff = reference.difference(time);
    final local = time.toLocal();

    if (diff.inMinutes < 1) return tr('baru saja', 'now');
    if (diff.inMinutes < 60) {
      return tr('${diff.inMinutes} mnt', '${diff.inMinutes}m');
    }
    if (diff.inHours < 24) return tr('${diff.inHours} j', '${diff.inHours}h');
    if (diff.inDays < 7) return tr('${diff.inDays} h', '${diff.inDays}d');
    return '${local.day} ${_month(local.month)}';
  }

  /// Whether two instants fall on the same day *for the reader* — a message
  /// at 23:30 UTC and one at 00:30 UTC are one day apart in Greenwich and
  /// the same evening in Jakarta.
  static bool sameDay(DateTime a, DateTime b) {
    final x = a.toLocal();
    final y = b.toLocal();

    return x.year == y.year && x.month == y.month && x.day == y.day;
  }

  static DateTime _dateOnly(DateTime time) =>
      DateTime(time.year, time.month, time.day);

  static String _month(int month) =>
      (AppLanguage.current == AppLanguage.id ? _monthsId : _monthsEn)[month - 1];

  static const _monthsEn = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const _monthsId = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
}
