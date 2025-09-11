import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:arche/arche.dart';
import 'package:arche/extensions/io.dart';
import 'package:cczu_helper/models/navstyle.dart';
import 'package:cczu_helper/views/pages/calendar.dart';
import 'package:cczu_helper/views/services/iccard/electric_bill.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
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

// Need initialize the configs first
FutureLazyDynamicCan<Uint8List?> calendarBackgroundData =
    FutureLazyDynamicCan(builder: () async {
  final configs = ArcheBus().of<ApplicationConfigs>();
  final background = configs.calendarBackgroundImage.tryGet();
  if (background == null) {
    return null;
  }
  final file = (await platCalendarDataDirectory.getValue()).subFile(background);
  if (await file.exists()) {
    return await file.readAsBytes();
  }
  return null;
});

FutureLazyDynamicCan<List<ICalendarParser>?> icalendarParsersData =
    FutureLazyDynamicCan(builder: () async {
  return (await platCalendarDataDirectory.getValue())
      .listSync()
      .where((item) => extension(item.path) == ".ics")
      .map((item) {
    final calendar = File(item.path);
    return ICalendarParser(
        calendar.readAsStringSync(),
        basename(item.path) == "calendar_curriculum.ics"
            ? CalendarSource.curriculum
            : CalendarSource.other);
  }).toList();
});

Future<void> ensurePlatDirectoryValue() async {
  await platDirectory.reload();
  await platUserDataDirectory.reload();
  await platCalendarDataDirectory.reload();
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
        generator("calendarview_v2"),
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

  ConfigEntry<bool> get firstUse => generator("first_use");
  ConfigEntry<bool> get weakAnimation => generator("weak_animation");
  ConfigEntry<bool> get funDream => generator("fun_dream");

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
  ConfigEntry<bool> get calendarColorful => generator("calendar_colorful");
  ConfigEntry<bool> get calendarShowViewHeader =>
      generator("calendar_show_view_header");
  ConfigEntry<bool> get calendarShowController =>
      generator("calendar_show_controller");
  ConfigEntry<bool> get calendarShowTimeRule =>
      generator("calendar_show_time_rule");
  ConfigEntry<int> get calendarTimeIntervalMinutes =>
      generator("calendar_time_interval_minutes");
  ConfigEntry<bool> get calendarShowAlldayAppionments =>
      generator("calendar_show_allday_appionments");
  ConfigEntryConverter<int, TimeOfDay> get calendarTimeStart =>
      ConfigEntryConverter(
        generator("calendar_time_start_v2"),
        forward: (value) {
          return TimeOfDay(hour: value ~/ 100, minute: value % 100);
        },
        reverse: (value) {
          return value.hour * 100 + value.minute;
        },
      );
  ConfigEntryConverter<int, TimeOfDay> get calendarTimeEnd =>
      ConfigEntryConverter(
        generator("calendar_time_end_v2"),
        forward: (value) {
          return TimeOfDay(hour: value ~/ 100, minute: value % 100);
        },
        reverse: (value) {
          return value.hour * 100 + value.minute;
        },
      );
  ConfigEntryConverter<List<dynamic>, List<SubscribeElectricBillRoom>>
      get subscribeElectricBillRooms => ConfigEntryConverter(
            generator("subscribe_electric_bill_rooms"),
            forward: (value) {
              return value
                  .map((e) => SubscribeElectricBillRoom.fromJson(e))
                  .toList();
            },
            reverse: (value) {
              return value.map((e) => e.toJson()).toList();
            },
          );
}
