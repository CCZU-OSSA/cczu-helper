import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:arche/extensions/io.dart';
import 'package:cczu_helper/controllers/accounts.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/platform.dart';
import 'package:cczu_helper/controllers/scheduler.dart';
import 'package:cczu_helper/messages/generated.dart';
import 'package:cczu_helper/models/navstyle.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:cczu_helper/views/pages/calendar.dart';
import 'package:cczu_helper/views/pages/services.dart';
import 'package:cczu_helper/views/pages/settings.dart';
import 'package:cczu_helper/views/pages/tutorial.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:rinf/rinf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:system_fonts/system_fonts.dart';

void main() {
  void catchError([ArcheLogger? logger]) async {
    var store =
        logger ?? ArcheBus.bus.provideof<ArcheLogger>(instance: ArcheLogger());

    var bus = ArcheBus();
    if (bus.has<ApplicationConfigs>()) {
      ApplicationConfigs configs = bus.of();
      if (configs.autosavelog.getOr(false)) {
        await (await platDirectory.getValue())
            .subFile("error.log")
            .writeAsString(store.getLogs().join("\n"));
      }
    }
  }

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await initializeRust(assignRustSignal);
      var logger = ArcheLogger();
      var platUserData = await platUserDataDirectory.getValue();
      // Migrate
      await migrateUserData();

      var configPath = platUserData.subPath("app.config.json");
      var config = ArcheConfig.path(configPath);
      logger.info("Application Config Stored in `$configPath`");

      FlutterError.onError = (err) async {
        logger.error(err.exception);
        logger.error(err.stack);
        catchError(logger);
      };

      //Calendar
      ICalendar.registerField(
        field: "WEEK",
        function: (value, params, event, lastEvent) {
          lastEvent['week'] = value;
          return lastEvent;
        },
      );

      var bus = ArcheBus();
      var configs = ApplicationConfigs(config);
      bus.provide(ArcheLogger()).provide(config).provide(configs);
      // Custom Font
      var customfont = platUserData.subFile("customfont");
      if (await customfont.exists()) {
        var loader = FontLoader("Custom Font")
          ..addFont(
            Future(() async {
              var data = await customfont.readAsBytes();

              return data.buffer.asByteData();
            }),
          );
        await loader.load();
        configs.sysfont.write("Custom Font");
      } else {
        // Load SystemFont
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          var font = configs.sysfont.tryGet();
          if (font != null) {
            await SystemFonts().loadFont(font);
          }
        }
      }

      if (Platform.isAndroid) {
        await Scheduler.init();
      }

      logger.info("Run Application in `main`...");
      logger.info("Try to load `MultiAccountData`");

      if (await MultiAccoutData.hasAccountsFile()) {
        bus.provide((await MultiAccoutData.readAccounts())!);
      } else {
        logger.warn("Can't find `accounts.json`");
        bus.provide(MultiAccoutData.template);
      }

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
      var logger = ArcheBus.bus.provideof<ArcheLogger>(instance: ArcheLogger());
      logger.error(error);
      logger.error(stack);

      catchError(logger);
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
  late final AppLifecycleListener _appLifecycleListener;

  @override
  void initState() {
    super.initState();
    configs = ArcheBus().of();
    _appLifecycleListener = AppLifecycleListener(
      onExitRequested: () async {
        finalizeRust();
        return AppExitResponse.exit;
      },
    );
  }

  @override
  void dispose() {
    _appLifecycleListener.dispose();

    super.dispose();
  }

  ColorScheme _generateColorScheme(ColorScheme? scheme,
      [Brightness? brightness]) {
    ColorScheme newScheme;
    if (scheme case final scheme?) {
      newScheme = ColorScheme.fromSeed(
          seedColor: scheme.primary, brightness: scheme.brightness);
    } else {
      newScheme = ColorScheme.fromSeed(
          seedColor: Colors.blue, brightness: brightness ?? Brightness.light);
    }

    return newScheme.harmonized();
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp(
        scaffoldMessengerKey: messagerKey,
        localizationsDelegates: const [
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale.fromSubtags(languageCode: 'zh'), // generic Chinese 'zh'
        ],
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: configs.sysfont.tryGet(),
          useMaterial3: true,
          colorScheme: _generateColorScheme(
              darkDynamic ?? _defaultDarkColorScheme, Brightness.dark),
          typography: Typography.material2021(),
        ),
        theme: ThemeData(
          brightness: Brightness.light,
          fontFamily: configs.sysfont.tryGet(),
          useMaterial3: true,
          colorScheme:
              _generateColorScheme(lightDynamic ?? _defaultLightColorScheme),
          typography: Typography.material2021(),
        ),
        themeMode: configs.themeMode.getOr(ThemeMode.system),
        home: MainView(
          key: viewKey,
        ),
      ),
    );
  }
}

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<StatefulWidget> createState() => MainViewState();
}

class MainViewState extends State<MainView> with RefreshMountedStateMixin {
  int currentIndex = 0;

  static var viewItems = [
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
      Scheduler.reScheduleAll();
    }

    platDirectory.then((subdir) {
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
                visible:
                    Platform.isLinux || Platform.isMacOS || Platform.isWindows,
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

    if (configs.firstUse.getOr(true)) {
      return const TutorialPage();
    }
    var theme = Theme.of(context);
    var colorScheme = theme.colorScheme;
    var navStyle = configs.navStyle.getOr(NavigationStyle.both);
    var showTop =
        navStyle == NavigationStyle.top || navStyle == NavigationStyle.both;
    return Scaffold(
      appBar: showTop
          ? AppBar(
              title: Text(viewItems[currentIndex].label),
              surfaceTintColor: Colors.transparent,
              backgroundColor: colorScheme.surfaceContainer,
              forceMaterialTransparency: configs.forceTransparent.getOr(true),
            )
          : null,
      drawer: showTop
          ? NavigationDrawer(
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
                          settingKey.currentState?.refreshMounted();
                        }),
                        onLongPress: () => setState(() {
                          configs.themeMode.write(ThemeMode.system);
                          rootKey.currentState?.refreshMounted();
                          settingKey.currentState?.refreshMounted();
                        }),
                        child: AnimatedRotation(
                          turns: isDark ? 0 : 1,
                          duration: Durations.medium4,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                                isDark ? Icons.light_mode : Icons.dark_mode),
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
            )
          : null,
      body: SafeArea(
        top: true,
        child: NavigationView(
          key: navKey,
          transitionBuilder: (child, animation) {
            if (configs.weakAnimation.getOr(true)) {
              return AnimatedSwitcher.defaultTransitionBuilder(
                  child, animation);
            }

            const begin = Offset(1, 0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.fastLinearToSlowEaseIn));
            final offsetAnimation = animation.drive(tween);
            return SlideTransition(
              position: offsetAnimation,
              child: Container(
                color: theme.scaffoldBackgroundColor,
                child: child,
              ),
            );
          },
          backgroundColor: Colors.transparent,
          showBar: navStyle == NavigationStyle.nav ||
              navStyle == NavigationStyle.both,
          direction: isWideScreen(context) ? Axis.horizontal : Axis.vertical,
          pageViewCurve: Curves.fastLinearToSlowEaseIn,
          onPageChanged: (value) => setState(() => currentIndex = value),
          items: viewItems,
          labelType: NavigationLabelType.selected,
        ),
      ),
    );
  }
}
