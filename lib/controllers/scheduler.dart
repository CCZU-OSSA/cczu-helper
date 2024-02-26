import 'package:arche/arche.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Scheduler {
  late final FlutterLocalNotificationsPlugin plugin;
  static Future<Scheduler> init() async {
    var plugin = FlutterLocalNotificationsPlugin();
    var successed = await plugin.initialize(const InitializationSettings());
    if (successed == null || !successed) {
      ArcheBus.logger
          .error("Failed to initlize the Notification Native Plugin");
    }
    return Scheduler()..plugin = plugin;
  }
}
