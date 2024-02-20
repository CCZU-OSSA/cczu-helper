import 'dart:io';

import 'package:arche/arche.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

FutureLazyDynamicCan<Directory> platDirectory =
    FutureLazyDynamicCan(builder: getPlatDirectory);

Future<Directory> getPlatDirectory() async {
  if (Platform.isWindows) {
    return Directory("").absolute;
  }

  return (await getExternalStorageDirectory() ??
      await getApplicationCacheDirectory());
}

class ApplicationConfigs {
  final ConfigEntry<T> Function<T>(String key) generator;
  const ApplicationConfigs(this.generator);

  ConfigEntry<String> get username => generator<String>("username");
  ConfigEntry<String> get password => generator("password");
  ConfigEntry<String> get termid => generator("termid");
  ConfigEntry<String> get termname => generator("termname");
  ConfigEntry<bool> get useSystemFont => generator("usesystemfont");
  ConfigEntry<bool> get showBar => generator("showbar");
  ConfigEntryConverter<int, ThemeMode> get themeMode => ConfigEntryConverter(
        generator("thememode"),
        forward: (value) => ThemeMode.values[value],
        reverse: (value) => ThemeMode.values.indexOf(value),
      );
  ConfigEntry<bool> get material3 => generator("material3");
  ConfigEntry<bool> get pageview => generator("pageview");
  ConfigEntry<double> get cardsize => generator("cardsize");
}
