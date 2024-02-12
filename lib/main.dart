import 'dart:ui';

import 'package:arche/arche.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/messages/generated.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:cczu_helper/views/pages/feature.dart';
import 'package:cczu_helper/views/pages/home.dart';
import 'package:cczu_helper/views/pages/settings.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeRust();
  var logger = ArcheLogger();
  var configPath = await getPlatPath(path: "app.config.json");
  var config = ArcheConfig.path(configPath);
  logger.info("Application Config Stored in `$configPath`");
  logger.info("Load Configs");
  logger.info(config.read());
  ArcheBus()
      .provide(ArcheLogger())
      .provide(config)
      .provide(ApplicationConfigs(ConfigEntry.withConfig(config)));
  logger.info("Run Application in `main`...");
  runApp(MainApplication(
    key: rootKey,
  ));
}

final _defaultLightColorScheme =
    ColorScheme.fromSwatch(primarySwatch: Colors.blue);

final _defaultDarkColorScheme = ColorScheme.fromSwatch(
    primarySwatch: Colors.blue, brightness: Brightness.dark);

class MainApplication extends StatefulWidget {
  const MainApplication({super.key});

  @override
  State<StatefulWidget> createState() => MainApplicationState();
}

class MainApplicationState extends State<MainApplication> {
  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  final _appLifecycleListener = AppLifecycleListener(
    onExitRequested: () async {
      await finalizeRust();
      return AppExitResponse.exit;
    },
  );

  @override
  void dispose() {
    super.dispose();
    _appLifecycleListener.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ApplicationConfigs configs = ArcheBus().of();
    var useSystemFont = configs.useSystemFont.getOr(true);
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp(
        localizationsDelegates: const [
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        supportedLocales: const [
          Locale.fromSubtags(languageCode: 'zh'), // generic Chinese 'zh'
          Locale.fromSubtags(
              languageCode: 'zh',
              scriptCode: 'Hans'), // generic simplified Chinese 'zh_Hans'
          Locale.fromSubtags(
              languageCode: 'zh',
              scriptCode: 'Hant'), // generic traditional Chinese 'zh_Hant'
          Locale.fromSubtags(
              languageCode: 'zh',
              scriptCode: 'Hans',
              countryCode: 'CN'), // 'zh_Hans_CN'
          Locale.fromSubtags(
              languageCode: 'zh',
              scriptCode: 'Hant',
              countryCode: 'TW'), // 'zh_Hant_TW'
          Locale.fromSubtags(
              languageCode: 'zh',
              scriptCode: 'Hant',
              countryCode: 'HK'), // 'zh_Hant_HK'
        ],
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: useSystemFont ? null : "Default",
          useMaterial3: configs.material3.getOr(true),
          colorScheme: darkDynamic ?? _defaultDarkColorScheme,
          typography: Typography.material2021(),
        ),
        theme: ThemeData(
          brightness: Brightness.light,
          fontFamily: useSystemFont ? null : "Default",
          useMaterial3: configs.material3.getOr(true),
          colorScheme: lightDynamic ?? _defaultLightColorScheme,
          typography: Typography.material2021(),
        ),
        themeMode: configs.themeMode.getOr(ThemeMode.system),
        home: MainView(key: viewKey),
      ),
    );
  }
}

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<StatefulWidget> createState() => MainViewState();
}

class MainViewState extends State<MainView> {
  int currentIndex = 0;
  var viewItems = [
    const NavigationItem(
      icon: Icon(Icons.home),
      page: HomePage(),
      label: "主页",
    ),
    const NavigationItem(
      icon: Icon(Icons.apps),
      page: FeaturesPage(),
      label: "工具箱",
    ),
    NavigationItem(
      icon: const Icon(Icons.settings),
      page: SettingsPage(
        key: settingKey,
      ),
      label: "设置",
    ),
  ];

  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ApplicationConfigs configs = ArcheBus().of();
    var themeMode = configs.themeMode.getOr(ThemeMode.system);
    bool isDark = themeMode == ThemeMode.system
        ? MediaQuery.of(context).platformBrightness == Brightness.dark
        : themeMode == ThemeMode.dark;
    return Scaffold(
      key: ValueKey(configs.material3.getOr(true)),
      appBar: AppBar(
        title: Text(viewItems[currentIndex].label),
      ),
      drawer: NavigationDrawer(
        selectedIndex: currentIndex,
        onDestinationSelected: navKey.currentState?.pushIndex,
        children: <Widget>[
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: const Text("常大助手"),
                subtitle: const Text("CCZU HELPER"),
                trailing: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() {
                    configs.themeMode
                        .write(isDark ? ThemeMode.light : ThemeMode.dark);
                    rootKey.currentState?.refresh();
                    settingKey.currentState?.refresh();
                  }),
                  onLongPress: () => setState(() {
                    configs.themeMode.write(ThemeMode.system);
                    rootKey.currentState?.refresh();
                    settingKey.currentState?.refresh();
                  }),
                  child: AnimatedRotation(
                    turns: isDark ? 0 : 1,
                    duration: Durations.medium4,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                    ),
                  ),
                ),
              )
            ] +
            viewItems
                .map(
                  (e) => NavigationDrawerDestination(
                    icon: e.icon,
                    label: Text(e.label),
                  ),
                )
                .toList(),
      ),
      body: NavigationView(
        key: navKey,
        showBar: configs.showBar.getOr(true),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        direction:
            configs.sideBar.getOr(false) ? Axis.horizontal : Axis.vertical,
        pageViewCurve: Curves.fastLinearToSlowEaseIn,
        onPageChanged: (value) => setState(() => currentIndex = value),
        items: viewItems,
        labelType: NavigationLabelType.selected,
      ),
    );
  }
}
