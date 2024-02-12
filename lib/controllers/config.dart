import 'dart:io';

import 'package:arche/arche.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

Future<String> getPlatPath({required String path}) async {
  if (Platform.isAndroid) {
    return "${await getAndroidPath()}/$path";
  } else {
    return path;
  }
}

Future<String> getAndroidPath() async {
  return (await tryGetExternalStorageDirectory() ??
          await getApplicationCacheDirectory())
      .path;
}

Future<Directory?> tryGetExternalStorageDirectory() async {
  try {
    return await getExternalStorageDirectory();
  } catch (e) {
    return null;
  }
}

class ApplicationConfigs {
  final ConfigEntry<T> Function<T>(String key) generator;
  const ApplicationConfigs(this.generator);

  ConfigEntry<String> get username => generator<String>("username");
  ConfigEntry<String> get password => generator("password");
  ConfigEntry<String> get termid => generator("termid");
  ConfigEntry<bool> get useSystemFont => generator("usesystemfont");
  ConfigEntry<bool> get showBar => generator("showbar");
  ConfigEntry<bool> get sideBar => generator("sidebar");
  ConfigEntryConverter<int, ThemeMode> get themeMode => ConfigEntryConverter(
        generator("thememode"),
        forward: (value) => ThemeMode.values[value],
        reverse: (value) => ThemeMode.values.indexOf(value),
      );
  ConfigEntry<bool> get material3 => generator("material3");
}
