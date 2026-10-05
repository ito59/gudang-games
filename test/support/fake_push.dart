import 'package:bandar_games/services/push_messaging.dart';

/// A [PushMessaging] a test drives by hand.
class FakePushMessaging implements PushMessaging {
  FakePushMessaging({this.token = 'device-token'});

  /// Null stands for somebody declining the permission, or a build with no
  /// Firebase at all.
  String? token;

  var startCount = 0;
  final List<String> subscribed = [];
  final List<String> unsubscribed = [];

  @override
  Future<String?> start() async {
    startCount++;
    return token;
  }

  @override
  Future<void> subscribe(String topic) async => subscribed.add(topic);

  @override
  Future<void> unsubscribe(String topic) async => unsubscribed.add(topic);
}
