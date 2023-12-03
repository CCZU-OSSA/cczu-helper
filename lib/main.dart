import 'package:cczu_helper/controller/bus.dart';
import 'package:cczu_helper/controller/config.dart';
import 'package:cczu_helper/controller/logger.dart';
import 'package:cczu_helper/pages/settings.dart';
import 'package:cczu_helper/pages/query_check.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var logger = ApplicationLogger();
  var config = await getPlatConfig(path: "app.config.json");
  runApp(Provider.value(
    value: ApplicationBus(config: config, logger: logger),
    child: const MyApp(),
  ));
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _StateHomePage();
}

final _pages = [const QueryCheckPage(), const SettingsPage()];

class _StateHomePage extends State<HomePage> {
  int _idx = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (value) => setState(() {
          _idx = value;
        }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "主页"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "设置")
        ],
      ),
    );
  }
}
