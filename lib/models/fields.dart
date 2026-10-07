import 'package:arche/arche.dart';
import 'package:cczu_helper/main.dart';
import 'package:cczu_helper/models/version.dart';
import 'package:cczu_helper/views/pages/settings.dart';
import 'package:material_ui/material_ui.dart';

final GlobalKey<MainApplicationState> rootKey = GlobalKey();
final GlobalKey<MainViewState> viewKey = GlobalKey();
final GlobalKey<NavigationViewState> navKey = GlobalKey();
final GlobalKey<SettingsPageState> settingKey = GlobalKey();
final GlobalKey<ScaffoldMessengerState> messagerKey = GlobalKey();

late Version appVersion;
