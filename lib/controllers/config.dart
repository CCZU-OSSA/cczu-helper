import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:arche/arche.dart';
import 'package:arche/extensions/io.dart';
import 'package:cczu_helper/models/navstyle.dart';
import 'package:cczu_helper/views/pages/calendar.dart';
import 'package:cczu_helper/views/services/iccard/electric_bill.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

FutureLazyDynamicCan<Directory> platDirectory =
    FutureLazyDynamicCan(builder: getPlatDirectory);

FutureLazyDynamicCan<Directory> platUserDataDirectory = FutureLazyDynamicCan(
    builder: () async => (await platDirectory.getValue())
        .subDirectory(Platform.isIOS ? "cczu-helper-userdata" : "userdata")
        .check());

FutureLazyDynamicCan<Directory> platCalendarDataDirectory =
    FutureLazyDynamicCan(
        builder: () async => (await platUserDataDirectory.getValue())
            .subDirectory("calendar")
            .check());

// Need initialize the configs first
FutureLazyDynamicCan<ui.Image?> calendarBackgroundData =
    FutureLazyDynamicCan(builder: () async {
  final configs = ArcheBus().of<ApplicationConfigs>();
  final background = configs.calendarBackgroundImage.tryGet();
  if (background == null) {
    return null;
  }
  final file = (await platCalendarDataDirectory.getValue()).subFile(background);
  if (await file.exists()) {
    return await decodeImageFromList(await file.readAsBytes());
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
            : CalendarSource.other,
        basename(item.path));
  }).toList();
});

/// 把时间吸附到最近的整点或半点。
///
/// 因为 SfCalendar 的时间轴要求「结束 − 开始」的分钟数能被时间间隔整除，
/// 否则库会自行改动间隔导致标尺错乱，所以这里统一把起止时间吸附到 30 的倍数。
/// 上限截到 23:30，避免 23:45 这类值四舍五入后回绕到次日 0:00。
TimeOfDay snapToHalfHour(TimeOfDay time) {
  final minutes = time.hour * 60 + time.minute;
  final snapped = (((minutes + 15) ~/ 30) * 30).clamp(0, 23 * 60 + 30);
  return TimeOfDay(hour: snapped ~/ 60, minute: snapped % 60);
}

Future<void> ensurePlatDirectoryValue() async {
  await platDirectory.reload();
  await platUserDataDirectory.reload();
  await platCalendarDataDirectory.reload();
}

Future<Directory> getPlatDirectory() async {
  if (Platform.isWindows || Platform.isLinux) {
    return Directory.current.absolute;
  }

  if (Platform.isIOS) {
    return await getApplicationDocumentsDirectory();
  }

  try {
    return await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
  } catch (_) {
    return await getApplicationDocumentsDirectory();
  }
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

  ConfigEntry<bool> get enableCustomPrimaryColor =>
      generator("enable_custom_primary_color");
  ConfigEntryConverter<int, Color> get customPrimaryColor =>
      ConfigEntryConverter(
        generator("custom_primary_color"),
        reverse: (value) => value.toARGB32(),
        forward: (value) => Color(value),
      );

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
  ConfigEntry<bool> get calendarBackgroundImageIndependentColor =>
      generator("calendar_background_image_independent_color");

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

  /// 用户手动添加的时间刻度，元素是 HHMM 整数（如 845 表示 8:45）。
  ConfigEntry<List<dynamic>> get calendarTimeSetUser =>
      generator("calendar_time_set_user");
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
