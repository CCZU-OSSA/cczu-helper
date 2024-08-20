import 'package:arche/arche.dart';
import 'package:cczu_helper/models/barbehavior.dart';
import 'package:flutter/material.dart';

var thememodeTr = StringTranslator(ThemeMode.values)
    .translate(ThemeMode.dark, "深色")
    .translate(ThemeMode.light, "浅色")
    .translate(ThemeMode.system, "跟随系统")
    .defaultValue("跟随系统");
var barBehaviorTr = StringTranslator(BarBehavior.values)
    .translate(BarBehavior.bottom, "仅底部栏")
    .translate(BarBehavior.top, "仅顶部栏")
    .translate(BarBehavior.both, "显示所有");
