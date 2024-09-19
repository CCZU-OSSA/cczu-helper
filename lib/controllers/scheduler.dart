import 'dart:io';

import 'package:arche/arche.dart';
import 'package:arche/modules/application.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:cczu_helper/views/pages/calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

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

  static Future<bool> requestAndroidPermission() async {
    var aplugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()!;
    return (await aplugin.requestNotificationsPermission() == true) &&
        (await aplugin.requestExactAlarmsPermission() == true);
  }

  static Future<void> init() async {
    initializeTimeZones();
    var successed = await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings("@mipmap/ic_launcher"),
      ),
    );
    if (successed == null || !successed) {
      ArcheBus.logger
          .error("Failed to initlize the Notification Native Plugin");
    } else {
      ArcheBus.logger.info("Initlize Notification Plugin Successfully");
    }
  }

  static void scheduleCalendar(int id, CalendarData data, Duration add) async {
    var start = data.start.toDateTime()!;
    var time = DateFormat('a hh:mm',
            Localizations.localeOf(viewKey.currentContext!).languageCode)
        .format(start);
    await plugin.zonedSchedule(
      id,
      data.summary,
      "${data.location} ($time)",
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
      -1,
      "测试通知",
      "如果能够看到这条通知说明权限正常",
      TZDateTime.from(DateTime.now().add(const Duration(seconds: 1)),
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

  static void reScheduleAll() {
    cancelAll().then((value) async => await scheduleAll());
  }

  static Future<void> scheduleAll() async {
    var now = DateTime.now();
    var configs = ArcheBus().of<ApplicationConfigs>();

    if (configs.notificationsEnable.getOr(false)) {
      var reminder =
          Duration(minutes: configs.notificationsReminder.getOr(15) * -1);

      var platdir = (await platCalendarDataDirectory.getValue());
      var schedulerDay = configs.notificationsDay.getOr(true);

      platdir
          .listSync()
          .where((item) => extension(item.path) == ".ics")
          .map((item) {
            final calendar = File(item.path);
            return ICalendarParser(
                calendar.readAsStringSync(),
                basename(item.path) == "calendar_curriculum.ics"
                    ? CalendarSource.curriculum
                    : CalendarSource.other);
          })
          .fold(<CalendarData>[], (collect, parser) {
            collect.addAll(parser.data);
            return collect;
          })
          .where(
            (element) =>
                !element.isAllday &&
                element.start
                    .toDateTime()!
                    .add(reminder)
                    .isAfter(now.toLocal()) &&
                (schedulerDay
                    ? now.isSameDay(element.start.toDateTime()!)
                    : true),
          )
          .indexed
          .forEach((data) => scheduleCalendar(data.$1, data.$2, reminder));
    }
  }
}

extension SameDay on DateTime {
  bool isSameDay(DateTime other) {
    return other.day == day && other.month == month && other.year == year;
  }
}
