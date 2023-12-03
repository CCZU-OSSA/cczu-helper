import 'package:cczu_helper/controller/bus.dart';
import 'package:cczu_helper/pages/settings.dart';
import 'package:cczu_helper/pages/query_check.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(Provider.value(
    value: ApplicationBus(),
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => StateMyApp();
}

final _defaultLightColorScheme =
    ColorScheme.fromSwatch(primarySwatch: Colors.blue);

final _defaultDarkColorScheme = ColorScheme.fromSwatch(
    primarySwatch: Colors.blue, brightness: Brightness.dark);

class StateMyApp extends State<MyApp> {
  int? _idx;

  @override
  Widget build(BuildContext context) {
    _idx ??= 0;
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
        home: Scaffold(
          body: [const QueryCheckPage(), const SettingsPage()][_idx!],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _idx!,
            onTap: (value) => setState(() {
              _idx = value;
            }),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_filled), label: "主页"),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: "设置")
            ],
          ),
        ),
      ),
    );
  }
}
