import 'dart:convert';
import 'dart:io';

import 'package:cczu_helper/controller/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

abstract class Config {
  Map read();

  void write<K, V>(K key, V value);

  V getOrWrite<K, V>(K key, V fallback);

  V get<K, V>(K key);

  bool has<K>(K key);

  V getOrDefault<K, V>(K key, V fallback);
}

class WebConfig extends Config {
  final Map _data = {};

  @override
  V get<K, V>(K key) {
    return _data[key];
  }

  @override
  V getOrDefault<K, V>(K key, V fallback) {
    if (has(key)) {
      return get(key);
    } else {
      return fallback;
    }
  }

  @override
  V getOrWrite<K, V>(K key, V fallback) {
    if (has(key)) {
      return get(key);
    } else {
      write(key, fallback);
      return fallback;
    }
  }

  @override
  bool has<K>(K key) {
    return _data.containsKey(key);
  }

  @override
  Map read() {
    return _data;
  }

  @override
  void write<K, V>(K key, V value) {
    _data[key] = value;
  }
}

Config getPlatConfig({required String path}) {
  if (kIsWeb) {
    return WebConfig();
  } else {
    return ApplicationConfig(path);
  }
}

class ApplicationConfig extends Config {
  String _path;
  late File configfile;
  void _checkInit() {
    loggerCell.log(_path);
    configfile = File(_path);
    if (!configfile.existsSync()) {
      configfile.writeAsString("{}");
    }
  }

  ApplicationConfig(this._path) {
    if (Platform.isAndroid) {
      getAndroidPath().then((value) {
        _path = "$value/$_path";
        _checkInit();
      });
    } else {
      _checkInit();
    }
  }

  @override
  Map read() {
    return jsonDecode(configfile.readAsStringSync());
  }

  @override
  void write<K, V>(K key, V value) {
    var m = read();
    m[key] = value;
    configfile.writeAsStringSync(jsonEncode(m));
  }

  @override
  V getOrWrite<K, V>(K key, V fallback) {
    var v = read();
    if (v.containsKey(key)) {
      return v[key];
    } else {
      write(key, fallback);
      return fallback;
    }
  }

  @override
  V get<K, V>(K key) {
    return read()[key];
  }

  @override
  bool has<K>(K key) {
    return read().containsKey(key);
  }

  @override
  V getOrDefault<K, V>(K key, V fallback) {
    var v = read();
    if (v.containsKey(key)) {
      return v[key];
    } else {
      return fallback;
    }
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
