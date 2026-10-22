import 'dart:convert';

import 'package:http/http.dart' as http;

import '../l10n/language.dart';
import '../state/auth_scope.dart';
import 'api_config.dart';

/// The kinds of thing that can be reported, named as the API names them.
enum ReportTarget { message, post, comment, user }

/// One entry in the reason list. The labels come from the server so the app
/// and the admin queue are never describing the same report differently.
class ReportReason {
  const ReportReason({required this.value, required this.label});

  final String value;
  final String label;
}

/// Reporting content, and the reasons somebody may give.
///
/// Nothing here hides anything: a report is filed for a human to read. What
/// the reporter can do about it themselves is block, which is a member call.
class ReportRepository {
  ReportRepository({required this.auth, http.Client? client})
    : _client = client ?? http.Client();

  final Auth auth;
  final http.Client _client;

  /// Used if the server cannot be reached. The sheet is worth opening with a
  /// stale list — a report filed under a slightly wrong reason still reaches
  /// a human, and an empty sheet reaches nobody.
  static List<ReportReason> get fallbackReasons => [
    ReportReason(
      value: 'spam',
      label: tr('Spam atau penipuan', 'Spam or scam'),
    ),
    ReportReason(
      value: 'harassment',
      label: tr('Pelecehan atau perundungan', 'Harassment or bullying'),
    ),
    ReportReason(value: 'hate', label: tr('Ujaran kebencian', 'Hate speech')),
    ReportReason(
      value: 'sexual',
      label: tr('Konten seksual', 'Sexual content'),
    ),
    ReportReason(
      value: 'violence',
      label: tr('Kekerasan atau ancaman', 'Violence or threats'),
    ),
    ReportReason(value: 'other', label: tr('Lainnya', 'Something else')),
  ];

  Future<List<ReportReason>> reasons() async {
    try {
      final response = await _client
          .get(ApiConfig.endpoint('report-reasons'))
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 200) return fallbackReasons;

      final body = jsonDecode(response.body);
      final data = (body is Map<String, dynamic>) ? body['data'] : null;
      if (data is! List) return fallbackReasons;

      final reasons = data
          .whereType<Map<String, dynamic>>()
          .map(
            (json) => ReportReason(
              value: (json['value'] as String?) ?? '',
              label: (json['label'] as String?) ?? '',
            ),
          )
          .where((reason) => reason.value.isNotEmpty)
          .toList();

      return reasons.isEmpty ? fallbackReasons : reasons;
    } catch (_) {
      return fallbackReasons;
    }
  }

  /// Files a report. Returns null when it was filed — including when it had
  /// already been filed, which the server answers as success — and a message
  /// to show when it was not.
  Future<String?> submit({
    required ReportTarget target,
    required String id,
    required String reason,
    String? note,
  }) async {
    // Ids travel as strings through the models; the API wants the number.
    final numericId = int.tryParse(id);
    if (numericId == null) {
      return tr('Itu tidak bisa dilaporkan.', 'That cannot be reported.');
    }

    try {
      final response = await _client
          .post(
            ApiConfig.endpoint('reports'),
            headers: {...auth.headers, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'type': target.name,
              'id': numericId,
              'reason': reason,
              if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
            }),
          )
          .timeout(ApiConfig.timeout);

      if (auth.wasRejected(response)) {
        return tr('Masuk untuk melaporkan ini.', 'Sign in to report this.');
      }
      if (response.statusCode == 200 || response.statusCode == 201) return null;

      return _messageOf(response.body) ??
          tr('Laporan tidak terkirim.', 'That report did not send.');
    } catch (_) {
      return tr('Laporan tidak terkirim.', 'That report did not send.');
    }
  }

  static String? _messageOf(String body) {
    try {
      final decoded = jsonDecode(body);
      final message = decoded is Map<String, dynamic> ? decoded['message'] : null;
      return message is String && message.isNotEmpty ? message : null;
    } catch (_) {
      return null;
    }
  }
}
