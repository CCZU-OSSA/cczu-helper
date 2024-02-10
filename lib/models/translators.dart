import 'package:arche/arche.dart';
import 'package:flutter/material.dart';

var thememodeTr = StringTranslator(ThemeMode.values)
    .translate(ThemeMode.dark, "深色")
    .translate(ThemeMode.light, "浅色")
    .translate(ThemeMode.system, "跟随系统")
    .defaultValue("跟随系统");
