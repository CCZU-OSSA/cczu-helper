import 'dart:async';
import 'dart:io';

import 'package:arche/arche.dart';
import 'package:arche/extensions/io.dart';
import 'package:cczu_helper/models/navstyle.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

FutureLazyDynamicCan<Directory> platDirectory =
    FutureLazyDynamicCan(builder: getPlatDirectory);

FutureLazyDynamicCan<Directory> platUserDataDirectory = FutureLazyDynamicCan(
    builder: () async =>
        (await platDirectory.getValue()).subDirectory("userdata").check());

FutureLazyDynamicCan<Directory> platCalendarDataDirectory =
    FutureLazyDynamicCan(
        builder: () async => (await platUserDataDirectory.getValue())
            .subDirectory("calendar")
            .check());

Future<void> mirgate(File from, File to) async {
  if (await from.exists()) {
    await to.writeAsBytes(await from.readAsBytes());
    await from.delete();
  }
}

Future<void> migrateUserData() async {
  var platdir = await platDirectory.getValue();
  var platUserData = await platUserDataDirectory.getValue();
  var platCalendarData = await platCalendarDataDirectory.getValue();
  var futures = [
    // App
    mirgate(platdir.subFile("app.config.json"),
        platUserData.subFile("app.config.json")),
    mirgate(platdir.subFile("accounts.json"),
        platUserData.subFile("accounts.json")),
    // Calendar
    mirgate(platdir.subFile("_curriculum.ics"),
        platCalendarData.subFile("calendar_curriculum.ics")),
  ];

  await Future.wait(futures);
}

Future<Directory> getPlatDirectory() async {
  if (Platform.isWindows || Platform.isLinux) {
    return Directory.current.absolute;
  }

  return (await getExternalStorageDirectory() ??
      await getApplicationCacheDirectory());
}

class ApplicationConfigs extends AppConfigsBase {
  ApplicationConfigs(super.config, [super.generateMap = true]);

  ConfigEntry<String> get sysfont => generator("sysfont");

  ConfigEntryConverter<int, ThemeMode> get themeMode => ConfigEntryConverter(
        generator("thememode"),
        forward: (value) => ThemeMode.values[value],
        reverse: (value) => value.index,
      );

  ConfigEntryConverter<int, NavigationStyle> get navStyle =>
      ConfigEntryConverter(
        generator("navigation_style"),
        forward: (value) => NavigationStyle.values[value],
        reverse: (value) => value.index,
      );
  ConfigEntryConverter<int, CalendarView> get calendarView =>
      ConfigEntryConverter(
        generator("calendarview"),
        forward: (value) {
          return CalendarView.values[value];
        },
        reverse: (value) {
          return value.index;
        },
      );
  ConfigEntry<bool> get autosavelog => generator("autosavelog");
  ConfigEntry<bool> get skipServiceExitConfirm =>
      generator("skipserviceexitconfirm");
  ConfigEntry<bool> get notificationsEnable =>
      generator("notifications_enable");
  ConfigEntry<int> get notificationsReminder =>
      generator("notifications_reminder");
  ConfigEntry<bool> get notificationsDay => generator("notifications_day");
  ConfigEntry<bool> get firstUse => generator("first_use");
  ConfigEntry<bool> get weakAnimation => generator("weak_animation");
  ConfigEntry<bool> get forceTransparent => generator("force_transparent");
  ConfigEntry<bool> get calendarSimple => generator("calendar_simple");

  ConfigEntry<bool> get calendarIntervalLine =>
      generator("calendar_intervalline");

  ConfigEntry<String> get calendarBackgroundImage =>
      generator("calendar_background_image");
  ConfigEntry<double> get calendarCellOpacity =>
      generator("calendar_cell_opacity");
  ConfigEntry<double> get calendarBackgroundImageOpacity =>
      generator("calendar_background_image_opacity");
  ConfigEntry<double> get calendarBackgroundImageBlur =>
      generator("calendar_background_image_blur");
}
