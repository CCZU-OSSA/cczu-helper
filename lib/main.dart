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
import 'package:cczu_helper/src/bindings/bindings.dart';
import 'package:cczu_helper/models/navstyle.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:cczu_helper/models/version.dart';
import 'package:cczu_helper/views/pages/calendar.dart';
import 'package:cczu_helper/views/pages/services.dart';
import 'package:cczu_helper/views/pages/settings.dart';
import 'package:cczu_helper/views/pages/tutorial.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rinf/rinf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:system_fonts/system_fonts.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  Future<void> catchError([ArcheLogger? logger]) async {
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
      final logger = ArcheLogger();
      try {
        WidgetsFlutterBinding.ensureInitialized();

        // Get app version
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        appVersion = parseVersion(packageInfo.version);

        // Ensure directory is initialized here for faster load
        await ensurePlatDirectoryValue();

        await initializeRust(assignRustSignal);
        final platUserData = await platUserDataDirectory.getValue();

        final configPath = platUserData.subPath("app.config.json");
        final config = ArcheConfig.path(configPath);
        logger.info("Application Config Stored in `$configPath`");
        if (!kDebugMode) {
          FlutterError.onError = (err) async {
            logger.error(err.exception);
            logger.error(err.stack);
            catchError(logger);
          };
        }

        // Calendar
        tz.initializeTimeZones();
        ICalendar.registerField(
          field: "WEEK",
          function: (value, params, event, lastEvent) {
            lastEvent['week'] = value;
            return lastEvent;
          },
        );

        var bus = ArcheBus();
        var configs = ApplicationConfigs(config);
        bus.provide(logger).provide(config).provide(configs);
        // Cache Background Image in memory for faster load
        await calendarBackgroundData.update();
        // Parse Data for fast load
        await icalendarParsersData.update();

        // Custom Font
        var customfont = platUserData.subFile("customfont");
        if (await customfont.exists()) {
          final loader = FontLoader("Custom Font")
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
      } catch (error, stack) {
        logger.error(error);
        logger.error(stack);
        await catchError(logger);
        runApp(
          FallbackLogApp(
            error: error,
            stackTrace: stack,
            logs: logger.getLogs().map((log) => log.toString()).toList(),
          ),
        );
      }
    },
    (error, stack) async {
      var logger = ArcheBus.bus.provideof(instance: ArcheLogger());
      logger.error(error);
      logger.error(stack);

      catchError(logger);
    },
  );
}

final _defaultLightColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);

final _defaultDarkColorScheme =
    ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark);

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

  @override
  Widget build(BuildContext context) {
    final customColor = configs.enableCustomPrimaryColor.getOr(false)
        ? configs.customPrimaryColor.tryGet()
        : null;
    final customDarkColorScheme = customColor != null
        ? ColorScheme.fromSeed(
            seedColor: customColor,
            brightness: Brightness.dark,
            dynamicSchemeVariant: DynamicSchemeVariant.content,
          )
        : null;
    final customLightColorScheme = customColor != null
        ? ColorScheme.fromSeed(
            seedColor: customColor,
            brightness: Brightness.light,
            dynamicSchemeVariant: DynamicSchemeVariant.content,
          )
        : null;
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp(
        scaffoldMessengerKey: messagerKey,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale.fromSubtags(languageCode: 'zh'), // generic Chinese 'zh'
        ],
        darkTheme: ThemeData(
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
          ),
          brightness: Brightness.dark,
          fontFamily: configs.sysfont.tryGet(),
          useMaterial3: true,
          colorScheme:
              customDarkColorScheme ?? darkDynamic ?? _defaultDarkColorScheme,
          typography: Typography.material2021(),
        ),
        theme: ThemeData(
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
          ),
          brightness: Brightness.light,
          fontFamily: configs.sysfont.tryGet(),
          useMaterial3: true,
          colorScheme: customLightColorScheme ??
              lightDynamic ??
              _defaultLightColorScheme,
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
    const NavigationItem(
      icon: Icon(Icons.calendar_month),
      page: CurriculumPage(), // SafeArea inside
      label: "课表",
    ),
    const NavigationItem(
      icon: Icon(Icons.school),
      page: SafeArea(
        bottom: false,
        key: ValueKey(1),
        child: ServicePage(),
      ),
      label: "服务",
    ),
    NavigationItem(
      icon: const Icon(Icons.settings),
      page: SafeArea(
        bottom: false,
        key: const ValueKey(2),
        child: SettingsPage(
          key: settingKey,
        ),
      ),
      label: "设置",
    ),
  ];
  late ApplicationConfigs configs;
  @override
  void initState() {
    super.initState();
    configs = ArcheBus().of();

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
                    SharePlus.instance.share(ShareParams(files: [
                      XFile.fromData(
                        utf8.encode(data),
                        mimeType: "text/plain",
                        name: "error.log",
                      )
                    ]));
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
    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
          statusBarColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ),
      );
    }
    var themeMode = configs.themeMode.getOr(ThemeMode.system);
    bool isDark = themeMode == ThemeMode.system
        ? MediaQuery.of(context).platformBrightness == Brightness.dark
        : themeMode == ThemeMode.dark;

    if (configs.firstUse.getOr(true)) {
      return const TutorialPage();
    }
    var theme = Theme.of(context);
    var navStyle = configs.navStyle.getOr(NavigationStyle.both);
    var showTop =
        navStyle == NavigationStyle.top || navStyle == NavigationStyle.both;
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: showTop
          ? AppBar(
              title: Text(viewItems[currentIndex].label),
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
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          final current = currentIndex;

          if (current != 0) {
            navKey.currentState?.popIndex();
          } else {
            void exitApp() {
              if (Platform.isAndroid || Platform.isIOS) {
                SystemNavigator.pop();
              } else {
                exit(0);
              }
            }

            if (configs.skipServiceExitConfirm.getOr(false)) {
              exitApp();
              return;
            }

            ComplexDialog.instance
                .confirm(context: context, content: const Text("确认退出应用?"))
                .then((result) {
              if (result) {
                exitApp();
              }
            });
          }
        },
        child: NavigationView(
          key: navKey,
          builder: (context, vertical, horizontal, state) {
            return NavigationViewState.defaultBuilder(
                context,
                () => MediaQuery.removePadding(
                      removeTop: true,
                      context: context,
                      child: vertical(),
                    ),
                horizontal,
                state);
          },
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

class FallbackLogApp extends StatelessWidget {
  final Object error;
  final StackTrace stackTrace;
  final List<String> logs;

  const FallbackLogApp({
    super.key,
    required this.error,
    required this.stackTrace,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("致命错误！应用启动失败😭"),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "错误: ${error.toString()}",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.redAccent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        ([error.toString(), stackTrace.toString(), ...logs])
                            .join("\n"),
                        style: const TextStyle(fontFamily: "monospace"),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "请将上述日志反馈给开发者以便排查。",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
