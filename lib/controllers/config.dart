import 'dart:async';
import 'dart:io';

import 'package:arche/arche.dart';
import 'package:arche/extensions/io.dart';
import 'package:cczu_helper/models/channel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

FutureLazyDynamicCan<Directory> platDirectory =
    FutureLazyDynamicCan(builder: getPlatDirectory);

Future<Directory> getPlatDirectory() async {
  if (Platform.isWindows) {
    return Directory.current.absolute;
  }

  return (await getExternalStorageDirectory() ??
      await getApplicationCacheDirectory());
}

class ApplicationConfigs {
  final ConfigEntry<T> Function<T>(String key) generator;
  const ApplicationConfigs(this.generator);

  ConfigEntry<String> get currentAccountName =>
      generator<String>("currentaccount");
  ConfigEntry<String> get termid => generator("termid");
  ConfigEntry<String> get termname => generator("termname");
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
  ConfigEntry<bool> get material3 => generator("material3");
  ConfigEntry<double> get cardsize => generator("cardsize");
  ConfigEntry<bool> get autosavelog => generator("autosavelog");
  ConfigEntryConverter<FutureOr<String>, Future<AccountData>>
      get currentAccount => ConfigEntryConverter(
            currentAccountName,
            forward: (value) async {
              return (await AccountManager.accounts.getValue())[value]!;
            },
            reverse: (value) async {
              return (await value).studentID;
            },
          );

  ConfigEntry<bool> get notificationsEnable =>
      generator("notifications_enable");
  ConfigEntry<int> get notificationsReminder =>
      generator("notifications_reminder");
}

class AccountManager {
  static final FutureLazyDynamicCan<ArcheConfig> accountsStored =
      FutureLazyDynamicCan(
          builder: () async => ArcheConfig.path(
              (await platDirectory.getValue()).subPath("accouts.json")));

  static FutureLazyDynamicCan<Map<String, AccountData>> accounts =
      FutureLazyDynamicCan(
    builder: () async {
      Map<String, AccountData> accounts = {};

      for (var account in (await accountsStored.getValue()).read().entries) {
        accounts[account.key] = AccountData(
          account.key,
          account.value["onetpwd"],
          account.value["eduspwd"],
        );
      }

      return accounts;
    },
  );
}
