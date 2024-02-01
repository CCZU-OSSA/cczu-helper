import 'package:arche/arche.dart';
import 'package:cczu_helper/controller/config.dart';
import 'package:cczu_helper/pages/query.dart';
import 'package:cczu_helper/pages/settings.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var config = await getPlatConfig(path: "app.config.json");
  ArcheBus()
      .provide(config)
      .provide(ApplicationConfigs(ConfigEntry.withConfig(config)));
  runApp(const MyApp());
}

final _defaultLightColorScheme =
    ColorScheme.fromSwatch(primarySwatch: Colors.blue);

final _defaultDarkColorScheme = ColorScheme.fromSwatch(
    primarySwatch: Colors.blue, brightness: Brightness.dark);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp(
          title: 'CCZU Helper',
          darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
            colorScheme: darkDynamic ?? _defaultDarkColorScheme,
          ),
          theme: ThemeData.light(
            useMaterial3: true,
          ).copyWith(
            colorScheme: lightDynamic ?? _defaultLightColorScheme,
          ),
          home: const HomePage()),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: NavigationView.pageView(direction: Axis.vertical, items: [
      NavigationItem(icon: Icon(Icons.home), page: QueryPage(), label: "主页"),
      NavigationItem(
          icon: Icon(Icons.settings), page: SettingsPage(), label: "设置"),
    ]));
  }
}
