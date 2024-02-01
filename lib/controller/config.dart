import 'dart:io';

import 'package:arche/arche.dart';
import 'package:path_provider/path_provider.dart';

Future<ArcheConfig> getPlatConfig({required String path}) async {
  if (Platform.isAndroid) {
    return ArcheConfig.path("${await getAndroidPath()}/$path");
  } else {
    return ArcheConfig.path(path);
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
}
