import 'dart:io';

import 'package:arche/arche.dart';
import 'package:arche/extensions/io.dart';
import 'package:cczu_helper/animation/rainbow.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/controllers/snackbar.dart';
import 'package:cczu_helper/models/navstyle.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:cczu_helper/models/translators.dart';
import 'package:cczu_helper/models/version.dart';
import 'package:cczu_helper/views/pages/calendar_settings.dart';
import 'package:cczu_helper/views/pages/update.dart';
import 'package:cczu_helper/views/pages/log.dart';
import 'package:cczu_helper/views/pages/account.dart';
import 'package:cczu_helper/views/pages/tutorial.dart';
import 'package:cczu_helper/views/widgets/scrollable.dart';
import 'package:cczu_helper/views/widgets/seletor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:system_fonts/system_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => SettingsPageState();
}


class SettingsPageState extends State<SettingsPage>
    with RefreshMountedStateMixin {
  @override
  Widget build(BuildContext context) {
    ApplicationConfigs configs = ArcheBus.bus.of();
    return PaddingScrollView(
      child: Column(
        children: [
          SettingGroup(
            name: "通用",
            children: [
              ListTile(
                leading: const Icon(Icons.perm_identity),
                title: const Text("账户"),
                subtitle: const Text("Accounts"),
                trailing: const Icon(Icons.arrow_right),
                onTap: () {
                  pushMaterialRoute(
                    builder: (context) => const AccountManagePage(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text("课程表设置"),
                subtitle: const Text("Calendar"),
                trailing: const Icon(Icons.arrow_right_rounded),
                onTap: () {
                  pushMaterialRoute(
                    builder: (context) => const CalendarSettings(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.update),
                title: const Text("检查更新"),
                subtitle: const Text("Update"),
                trailing: const Icon(Icons.arrow_right),
                onTap: () => pushMaterialRoute(
                  builder: (context) => const CheckUpdatePage(),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.skip_next),
                title: const Text("跳过确认"),
                subtitle: const Text("Always Skip Confirm"),
                value: configs.skipServiceExitConfirm.getOr(false),
                onChanged: (value) {
                  setState(() {
                    configs.skipServiceExitConfirm.write(value);
                  });
                },
              ),
            ],
          ),
          // Only avilable in `Android`

          SettingGroup(
            name: "网络 (试验)",
            visible: Platform.isAndroid,
            children: [
              ListTile(
                leading: const Icon(Icons.network_wifi),
                title: const Text("校园VPN服务"),
                subtitle: const Text("VPN Service"),
                trailing: const Icon(Icons.arrow_right),
                onTap: () {
                  showSnackBar(
                      context: context, content: const Text("敬请期待..."));
                },
              ),
            ],
          ),

          SettingGroup(
            name: "外观",
            children: [
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: const Text("主题"),
                subtitle: const Text("Theme"),
                trailing: Seletor(
                  itemBuilder: (context) => ThemeMode.values,
                  translator: themeModeTr,
                  value: configs.themeMode.getOr(ThemeMode.system),
                  onSelected: (value) {
                    configs.themeMode.write(value);
                    rootKey.currentState?.refreshMounted();
                  },
                ),
              ),
              Visibility(
                visible:
                    Platform.isWindows || Platform.isLinux || Platform.isMacOS,
                replacement: SwitchListTile(
                  secondary: const Icon(FontAwesomeIcons.font),
                  title: const Text("自定义字体"),
                  subtitle: const Text("需重新启动"),
                  value: platUserDataDirectory.value
                          ?.subFile("customfont")
                          .existsSync() ??
                      false, // Unsafe Getter here, lol
                  onChanged: (value) {
                    if (value) {
                      // External Storage in Android
                      FilePicker.platform
                          .pickFiles(
                        type: FileType.custom,
                        allowedExtensions: [
                          "otf",
                          "ttf"
                        ], // May be more ext should be allowed
                        withData: true,
                      )
                          .then((result) {
                        var files = result?.files;
                        if (files != null && files.isNotEmpty) {
                          final data = files.first.bytes;

                          if (data != null) {
                            platUserDataDirectory.getValue().then((platdir) {
                              final file = platdir.subFile("customfont");
                              file.writeAsBytesSync(data);
                              setState(() {});
                            });
                          }
                        }
                      });
                    } else {
                      platUserDataDirectory.getValue().then((platdir) {
                        final file = platdir.subFile("customfont");
                        if (file.existsSync()) {
                          file.deleteSync();
                          setState(() {});
                        }
                      });
                    }
                  },
                ),
                child: ListTile(
                  leading: const Icon(FontAwesomeIcons.font),
                  title: const Text("字体"),
                  subtitle: const Text("Font"),
                  trailing: Seletor(
                    itemBuilder: (context) {
                      var fonts = SystemFonts().getFontList();
                      fonts.sort();
                      return fonts;
                    },
                    tileBuilder: (context, value) {
                      return FutureBuilder(
                        future: SystemFonts().loadFont(value),
                        builder: (context, snapshot) {
                          var data = snapshot.data;
                          if (data == null) {
                            return Text(value);
                          }

                          return Text(
                            data,
                            style: TextStyle(fontFamily: data),
                          );
                        },
                      );
                    },
                    value: configs.sysfont.getOr("System Default"),
                    onSelected: (value) async {
                      await SystemFonts().loadFont(value);
                      configs.sysfont.write(value);
                      rootKey.currentState?.refreshMounted();
                    },
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text("导航样式"),
                subtitle: const Text("Navigation"),
                trailing: Seletor(
                  itemBuilder: (context) => NavigationStyle.values,
                  translator: navStyleTr,
                  value: configs.navStyle.getOr(NavigationStyle.both),
                  onSelected: (value) {
                    configs.navStyle.write(value);
                    viewKey.currentState?.refreshMounted();
                  },
                ),
              ),
              SwitchListTile(
                value: configs.weakAnimation.getOr(true),
                secondary: const Icon(Icons.animation),
                title: const Text("弱动画"),
                subtitle: const Text("Weak Animation"),
                onChanged: (value) {
                  setState(() {
                    configs.weakAnimation.write(value);
                  });
                },
              ),
            ],
          ),
          SettingGroup(
            name: "调试",
            children: [
              SwitchListTile(
                value: configs.autosavelog.getOr(false),
                secondary: const Icon(Icons.error),
                title: const Text("自动保存错误日志"),
                subtitle: const Text("Auto Save"),
                onChanged: (value) {
                  setState(() {
                    configs.autosavelog.write(value);
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.book),
                title: const Text("日志"),
                subtitle: const Text("Logs"),
                trailing: const Icon(Icons.arrow_right),
                onTap: () => pushMaterialRoute(
                  builder: (context) => const LogPage(),
                ),
              )
            ],
          ),
          SettingGroup(name: "娱乐", children: [
            SwitchListTile(
              value: configs.funDream.getOr(false),
              secondary: const Icon(Icons.bed),
              title: const Text("一键幻想"),
              subtitle: rainbow(const Text("你的所有查询到的成绩都会变成满分"), 900.ms),
              onChanged: (value) {
                setState(() {
                  configs.funDream.write(value);
                });
              },
            ),
          ]),
          SettingGroup(
            name: "关于",
            children: [
              ListTile(
                leading: const Icon(FontAwesomeIcons.github),
                title: const Text("开源地址"),
                subtitle:
                    const Text("https://github.com/CCZU-OSSA/cczu-helper"),
                onTap: () =>
                    launchUrlString("https://github.com/CCZU-OSSA/cczu-helper"),
              ),
              ListTile(
                leading: const Icon(Icons.book),
                title: const Text("账户使用指南"),
                subtitle: const Text("Account Usage"),
                onTap: () => pushMaterialRoute(
                  context: context,
                  builder: (context) => Scaffold(
                    appBar: AppBar(),
                    body: const TutorialPage(
                      showFAB: false,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text("官方网站"),
                subtitle: rainbow(const Text(
                  "源神.常州大学.com",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                )),
                onTap: () => launchUrlString(
                  "https://cczu-ossa.github.io/home",
                  mode: LaunchMode.externalApplication,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.chat),
                title: const Text("QQ群"),
                subtitle: const Text("947560153"),
                onTap: () => launchUrlString(
                    "http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=6wgGLJ_NmKQl7f9Ws6JAprbTwmG9Ouei&authKey=g7bXX%2Bn2dHlbecf%2B8QfGJ15IFVOmEdGTJuoLYfviLg7TZIsZCu45sngzZfL3KktN&noverify=0&group_code=947560153"),
              ),
              ListTile(
                leading: const Icon(Icons.library_books),
                title: const Text("开源许可"),
                subtitle: const Text("License"),
                onTap: () => showDialog(
                  context: context,
                  builder: (context) => AboutDialog(
                    applicationVersion: appVersion.format(),
                    applicationName: "吊大助手",
                    applicationLegalese: "copyright © 2023-2024 常州大学开源软件协会",
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                            "除第三方代码与资源（包括但不限于图片字体）保留原有协议外\n应用本身所有代码以及资源均使用GPLv3开源，请参照协议使用"),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SettingGroup extends StatelessWidget {
  final String? name;
  final List<Widget> children;
  final bool visible;
  const SettingGroup({
    super.key,
    this.name,
    required this.children,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget item = Card(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: Column(
          children: children,
        ),
      ),
    );

    if (name != null) {
      item = Column(
        children: [
          ListTile(
            title: Text(name!),
          ),
          item,
        ],
      );
    }

    return Visibility(
      visible: visible,
      child: item,
    );
  }
}
