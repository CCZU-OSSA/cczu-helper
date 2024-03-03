import 'package:arche/arche.dart';
import 'package:arche/extensions/io.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/views/pages/curriculum.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

@pragma('vm:entry-point')
void notificationTapBackground(
    NotificationResponse notificationResponse) async {
  await Scheduler.scheduleNext();
}

class Scheduler {
  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();
  static const notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      "cczu_helper",
      "课程表通知",
      importance: Importance.max,
      priority: Priority.high,
    ),
  );
  static Future<void> init() async {
    initializeTimeZones();
    var successed = await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings("@mipmap/ic_launcher"),
      ),
      onDidReceiveNotificationResponse: (details) async =>
          await Scheduler.scheduleNext(),
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    if (successed == null || !successed) {
      ArcheBus.logger
          .error("Failed to initlize the Notification Native Plugin");
    } else {
      ArcheBus.logger.info("Initlize Notification Plugin Successfully");
    }
  }

  static void scheduleCalendar(CalendarData data, Duration add) async {
    var start = data.start.toDateTime()!;
    await plugin.zonedSchedule(
      0,
      data.summary,
      data.location,
      TZDateTime.from(start.add(add), getLocation("Asia/Shanghai")),
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelAll() async {
    await plugin.cancelAll();
  }

  static void scheduleTest() async {
    await plugin.zonedSchedule(
      0,
      "测试通知",
      "如果能够看到这条通知说明权限正常",
      TZDateTime.from(DateTime.now().add(const Duration(seconds: 5)),
          getLocation("Asia/Shanghai")),
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<List<PendingNotificationRequest>>
      getScheduleNotifications() async {
    return await plugin.pendingNotificationRequests();
  }

  static Future<void> scheduleNext() async {
    var now = DateTime.now();
    var configs = ArcheBus().of<ApplicationConfigs>();
    if (configs.notificationsEnable.getOr(false)) {
      var sourcefile =
          (await platDirectory.getValue()).subFile("_curriculum.ics");
      if (await sourcefile.exists()) {
        Duration diff = const Duration(days: 365);
        CalendarData? data;
        ICalendarParser(await sourcefile.readAsString())
            .data
            .where((element) =>
                !element.isAllday &&
                element.start.toDateTime()!.isAfter(now.toLocal()))
            .forEach((course) {
          var tmp = course.start.toDateTime()!.difference(now).abs();
          if (tmp <= diff) {
            data = course;
            diff = tmp;
          }
        });
        if (data != null) {
          scheduleCalendar(data!,
              Duration(minutes: configs.notificationsReminder.getOr(15) * -1));
        }
      }
    }
  }
}
