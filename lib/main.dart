import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:arche/extensions/io.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/platform.dart';
import 'package:cczu_helper/controllers/scheduler.dart';
import 'package:cczu_helper/messages/generated.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:cczu_helper/views/pages/calendar.dart';
import 'package:cczu_helper/views/pages/login.dart';
import 'package:cczu_helper/views/pages/services.dart';
import 'package:cczu_helper/views/pages/settings.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rinf/rinf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await initializeRust(assignRustSignal);
      var logger = ArcheLogger();
      var platDir = await platDirectory.getValue();
      var configPath = platDir.subPath("app.config.json");
      var config = ArcheConfig.path(configPath);
      logger.info("Application Config Stored in `$configPath`");

      FlutterError.onError = logger.error;
      var bus = ArcheBus();
      var configs =
          ApplicationConfigs(ConfigEntry.withConfig(config, generateMap: true));
      bus.provide(ArcheLogger()).provide(config).provide(configs);

      if (Platform.isAndroid) {
        await Scheduler.init();
      }

      logger.info("Run Application in `main`...");

      runApp(
        MainApplication(key: rootKey),
      );
      if (Platform.isAndroid) {
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.transparent,
            statusBarColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
          ),
        );
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    },
    (error, stack) async {
      var bus = ArcheBus();
      var logger = ArcheBus.logger;
      logger.error(error);
      logger.error(stack);

      if (bus.has<ApplicationConfigs>()) {
        ApplicationConfigs configs = bus.of();
        if (configs.autosavelog.getOr(false)) {
          await (await platDirectory.getValue())
              .subFile("error.log")
              .writeAsString(logger.getLogs().join("\n"));
        }
      }
    },
  );
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

class MainApplicationState extends State<MainApplication>
    with RefreshMountedStateMixin {
  late ApplicationConfigs configs;

  @override
  void initState() {
    super.initState();
    configs = ArcheBus().of();
  }

  final _appLifecycleListener = AppLifecycleListener(
    onExitRequested: () async {
      finalizeRust();
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
    var useSystemFont = configs.useSystemFont.getOr(true);
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp(
          scaffoldMessengerKey: messagerKey,
          localizationsDelegates: const [
            GlobalWidgetsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            SfGlobalLocalizations.delegate,
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
            useMaterial3: true,
            colorScheme: darkDynamic ?? _defaultDarkColorScheme,
            typography: Typography.material2021(),
          ),
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: useSystemFont ? null : "Default",
            useMaterial3: true,
            colorScheme: lightDynamic ?? _defaultLightColorScheme,
            typography: Typography.material2021(),
          ),
          themeMode: configs.themeMode.getOr(ThemeMode.system),
          home: MainView(
            key: viewKey,
          )),
    );
  }
}

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<StatefulWidget> createState() => MainViewState();
}

class MainViewState extends State<MainView> with RefreshMountedStateMixin {
  bool _loginReady = false;
  int currentIndex = 0;
  var viewItems = [
    NavigationItem(
      icon: const Icon(Icons.calendar_month),
      page: CurriculumPage(
        key: curriculmKey,
      ),
      label: "课表",
    ),
    const NavigationItem(
      icon: Icon(Icons.school),
      page: ServicePage(),
      label: "服务",
    ),
    NavigationItem(
      icon: const Icon(Icons.settings),
      page: SettingsPage(
        key: settingKey,
      ),
      label: "设置",
    ),
  ];
  late ApplicationConfigs configs;

  @override
  void initState() {
    super.initState();
    configs = ArcheBus().of();
    if (configs.notificationsEnable.getOr(false) &&
        configs.notificationsDay.getOr(true)) {
      ArcheBus.logger.info("try to `reScheduleAll` Notifications");
      Scheduler.reScheduleAll(context);
    }
    platDirectory.getValue().then((subdir) {
      var subfile = subdir.subFile("error.log");
      if (subfile.existsSync()) {
        var data = subfile.readAsStringSync();
        subfile.deleteSync();

        ComplexDialog.instance.text(
          context: context,
          title: const Text("错误日志处理"),
          content: Wrap(
            direction: Axis.vertical,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text("检测到存在未处理的错误日志"),
              Padding(
                padding: const EdgeInsets.all(8),
                child: FilledButton.icon(
                  onPressed: () {
                    Share.shareXFiles([
                      XFile.fromData(
                        utf8.encode(data),
                        mimeType: "text/plain",
                        name: "error.log",
                      )
                    ]);
                  },
                  icon: const Icon(Icons.share),
                  label: const Text("分享"),
                ),
              ),
              Visibility(
                visible: !Platform.isAndroid,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: FilledButton.icon(
                    onPressed: () {
                      saveFile(data, fileName: "error.log");
                    },
                    icon: const Icon(Icons.save),
                    label: const Text("保存"),
                  ),
                ),
              )
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var themeMode = configs.themeMode.getOr(ThemeMode.system);
    bool isDark = themeMode == ThemeMode.system
        ? MediaQuery.of(context).platformBrightness == Brightness.dark
        : themeMode == ThemeMode.dark;

    if (!_loginReady && !configs.skipLoginPage.getOr(false)) {
      return AccountLoginPage(
        loginCallback: (context) {
          _loginReady = true;
          refreshMounted();
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(viewItems[currentIndex].label),
        forceMaterialTransparency: true,
      ),
      drawer: NavigationDrawer(
        selectedIndex: currentIndex,
        onDestinationSelected: navKey.currentState?.pushIndex,
        children: <Widget>[
              ListTile(
                leading: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back)),
                title: const Text("常大助手"),
                subtitle: const Text("CCZU HELPER"),
                trailing: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() {
                    configs.themeMode
                        .write(isDark ? ThemeMode.light : ThemeMode.dark);
                    rootKey.currentState?.refreshMounted();
                    settingKey.currentState?.refresh();
                  }),
                  onLongPress: () => setState(() {
                    configs.themeMode.write(ThemeMode.system);
                    rootKey.currentState?.refreshMounted();
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
        transitionBuilder: (child, animation) => FadeTransition(
          key: ValueKey(child),
          opacity: animation,
          child: child,
        ),
        showBar: configs.showBar.getOr(true),
        direction: isWideScreen(context) ? Axis.horizontal : Axis.vertical,
        pageViewCurve: Curves.fastLinearToSlowEaseIn,
        onPageChanged: (value) => setState(() => currentIndex = value),
        items: viewItems,
        labelType: NavigationLabelType.selected,
      ),
    );
  }
}
