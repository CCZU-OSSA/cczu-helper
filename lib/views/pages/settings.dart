import 'dart:io';

import 'package:arche/arche.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/models/navstyle.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:cczu_helper/models/translators.dart';
import 'package:cczu_helper/models/version.dart';
import 'package:cczu_helper/views/pages/update.dart';
import 'package:cczu_helper/views/pages/log.dart';
import 'package:cczu_helper/views/pages/account.dart';
import 'package:cczu_helper/views/pages/notifications.dart';
import 'package:cczu_helper/views/pages/tutorial.dart';
import 'package:cczu_helper/views/pages/vpn.dart';
import 'package:cczu_helper/views/widgets/scrollable.dart';
import 'package:cczu_helper/views/widgets/seletor.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:system_fonts/system_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    ApplicationConfigs configs = ArcheBus.bus.of();
    return PaddingScrollView(
      child: Column(
        children: [
          const ListTile(
            title: Text("通用"),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: Column(
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
                  Visibility(
                    visible: Platform.isAndroid,
                    child: ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text("课程表通知"),
                      subtitle: const Text("Notifications"),
                      trailing: const Icon(Icons.arrow_right),
                      onTap: () => pushMaterialRoute(
                        builder: (context) => const NotificationsPage(),
                      ),
                    ),
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
                    title: const Text("跳过多步确认"),
                    subtitle: const Text("Skip Confirm"),
                    value: configs.skipServiceExitConfirm.getOr(false),
                    onChanged: (value) {
                      setState(() {
                        configs.skipServiceExitConfirm.write(value);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          // Only avilable in `Android`
          Visibility(
            visible: Platform.isAndroid,
            child: Column(
              children: [
                const ListTile(
                  title: Text("网络"),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.network_wifi),
                          title: const Text("校园VPN服务"),
                          subtitle: const Text("VPN Service"),
                          trailing: const Icon(Icons.arrow_right),
                          onTap: () {
                            pushMaterialRoute(
                              builder: (context) => const VPNServicePage(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const ListTile(
            title: Text("外观"),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: Column(
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
                    visible: Platform.isWindows ||
                        Platform.isLinux ||
                        Platform.isMacOS,
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
                    value: configs.forceTransparent.getOr(true),
                    secondary: const Icon(Icons.invert_colors_off),
                    title: const Text("顶栏透明"),
                    subtitle: const Text("Transparent"),
                    onChanged: (value) {
                      setState(() {
                        configs.forceTransparent.write(value);
                      });
                      viewKey.currentState?.refreshMounted();
                    },
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
            ),
          ),
          const ListTile(
            title: Text("调试"),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: Column(
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
            ),
          ),
          const ListTile(
            title: Text("关于"),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(FontAwesomeIcons.github),
                    title: const Text("开源地址"),
                    subtitle:
                        const Text("https://github.com/CCZU-OSSA/cczu-helper"),
                    onTap: () => launchUrlString(
                        "https://github.com/CCZU-OSSA/cczu-helper"),
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
                    subtitle: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue,
                                Colors.green,
                                Colors.yellow,
                                Colors.pink,
                              ]).createShader(bounds),
                          child: const Text(
                            "源神.常州大学.com",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
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
            ),
          ),
        ],
      ),
    );
  }
}
