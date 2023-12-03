import 'dart:convert';
import 'dart:io';

import 'package:cczu_helper/controller/logger.dart';
import 'package:path_provider/path_provider.dart';

class ApplicationConfig {
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
      getApplicationSupportDirectory().then((value) {
        _path = "${value.absolute.path}/$_path";
        _checkInit();
      });
    } else {
      _checkInit();
    }
  }

  Map read() {
    return jsonDecode(configfile.readAsStringSync());
  }

  void write<K, V>(K key, V value) {
    var m = read();
    m[key] = value;
    configfile.writeAsStringSync(jsonEncode(m));
  }

  V getOrWrite<K, V>(K key, V fallback) {
    var v = read();
    if (v.containsKey(key)) {
      return v[key];
    } else {
      write(key, fallback);
      return fallback;
    }
  }

  V get<K, V>(K key) {
    return read()[key];
  }

  bool has<K>(K key) {
    return read().containsKey(key);
  }

  V getOrDefault<K, V>(K key, V fallback) {
    var v = read();
    if (v.containsKey(key)) {
      return v[key];
    } else {
      return fallback;
    }
  }
}
