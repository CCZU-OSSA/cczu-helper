import 'dart:async';
import 'dart:io';

import 'package:arche/arche.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

FutureLazyDynamicCan<Directory> platDirectory =
    FutureLazyDynamicCan(builder: getPlatDirectory);

Future<Directory> getPlatDirectory() async {
  if (Platform.isWindows || Platform.isLinux) {
    return Directory.current.absolute;
  }

  return (await getExternalStorageDirectory() ??
      await getApplicationCacheDirectory());
}

class ApplicationConfigs {
  final ConfigEntry<T> Function<T>(String key) generator;
  const ApplicationConfigs(this.generator);
  ConfigEntry<String> get font => generator("font");

  ConfigEntry<bool> get useSystemFont => generator("usesystemfont");
  ConfigEntry<bool> get showBar => generator("showbar");
  ConfigEntryConverter<int, ThemeMode> get themeMode => ConfigEntryConverter(
        generator("thememode"),
        forward: (value) => ThemeMode.values[value],
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
}
