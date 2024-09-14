import 'package:arche/arche.dart';
import 'package:cczu_helper/models/navstyle.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

var themeModeTr = StringTranslator(ThemeMode.values)
    .translate(ThemeMode.dark, "深色")
    .translate(ThemeMode.light, "浅色")
    .translate(ThemeMode.system, "跟随系统");
var navStyleTr = StringTranslator(NavigationStyle.values)
    .translate(NavigationStyle.nav, "仅导航栏")
    .translate(NavigationStyle.top, "仅顶部栏")
    .translate(NavigationStyle.both, "显示所有");
var calendarViewTr = StringTranslator(
        [CalendarView.week, CalendarView.day, CalendarView.schedule])
    .translate(CalendarView.day, "天")
    .translate(CalendarView.week, "星期")
    .translate(CalendarView.schedule, "日程");
