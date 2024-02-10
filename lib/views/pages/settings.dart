import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:arche/extensions/functions.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:cczu_helper/models/translators.dart';
import 'package:cczu_helper/views/pages/log.dart';
import 'package:cczu_helper/views/pages/termview.dart';
import 'package:cczu_helper/views/widgets/scrollable.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final GlobalKey<PopupMenuButtonState> _themeModeMenuKey = GlobalKey();

  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ApplicationConfigs configs = ArcheBus.bus.of();
    var username = configs.username.getOr("1145141919810");
    var termid = configs.termid.getOr("0d00");
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
                    title: const Text("学号"),
                    subtitle: const Text("Student ID"),
                    trailing: Text(username),
                    onTap: () => const ComplexDialog()
                        .input(
                            context: context,
                            title: const Text("学号"),
                            decoration: InputDecoration(
                                hintText: username,
                                border: const OutlineInputBorder()))
                        .then((value) => whenNotNull(
                            value,
                            (value) =>
                                setState(() => configs.username.write(value)))),
                  ),
                  ListTile(
                    leading: const Icon(Icons.school),
                    title: const Text("学期"),
                    subtitle: const Text("Term"),
                    trailing: Text(termid),
                    onTap: () => pushMaterialRoute(
                      builder: (context) => const TermView(),
                    ),
                  ),
                ],
              ),
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
                    onTap: () =>
                        _themeModeMenuKey.currentState?.showButtonMenu(),
                    trailing: PopupMenuButton(
                      key: _themeModeMenuKey,
                      child: Text(thememodeTr
                          .translation(
                              configs.themeMode.getOr(ThemeMode.system))
                          .toString()),
                      itemBuilder: (context) => ThemeMode.values
                          .map(
                            (e) => PopupMenuItem(
                              child:
                                  Text(thememodeTr.translation(e).toString()),
                              onTap: () {
                                setState(() {
                                  configs.themeMode.write(e);
                                });
                                rootKey.currentState?.refresh();
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  SwitchListTile(
                      title: const Text("使用系统字体"),
                      subtitle: const Text("System Font"),
                      secondary: const Icon(Icons.font_download),
                      value: configs.useSystemFont.getOr(true),
                      onChanged: (value) {
                        setState(() {
                          configs.useSystemFont.write(value);
                        });

                        rootKey.currentState?.refresh();
                      }),
                  SwitchListTile(
                    title: const Text("显示导航栏"),
                    subtitle: const Text("Navigation Bar"),
                    secondary: const Icon(Icons.visibility),
                    value: configs.showBar.getOr(true),
                    onChanged: (value) {
                      setState(() {
                        configs.showBar.write(value);
                      });

                      viewKey.currentState?.refresh();
                    },
                  ),
                  SwitchListTile(
                      title: const Text("使用侧边导航(适用于宽屏设备)"),
                      subtitle: const Text("Side Navigation"),
                      secondary: const Icon(Icons.computer),
                      value: configs.sideBar.getOr(false),
                      onChanged: (value) {
                        setState(() {
                          configs.sideBar.write(value);
                        });

                        viewKey.currentState?.refresh();
                      }),
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
                    leading: const Icon(Icons.link),
                    title: const Text("开源地址"),
                    subtitle:
                        const Text("https://github.com/CCZU-OSSA/cczu-helper"),
                    onTap: () => launchUrlString(
                        "https://github.com/CCZU-OSSA/cczu-helper"),
                  ),
                  ListTile(
                    leading: const Icon(Icons.chat),
                    title: const Text("QQ群"),
                    subtitle: const Text("947560153"),
                    onTap: () => launchUrlString(
                        "http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=6wgGLJ_NmKQl7f9Ws6JAprbTwmG9Ouei&authKey=g7bXX%2Bn2dHlbecf%2B8QfGJ15IFVOmEdGTJuoLYfviLg7TZIsZCu45sngzZfL3KktN&noverify=0&group_code=947560153"),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text("关于"),
                    subtitle: const Text("About"),
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) => const AboutDialog(
                        applicationVersion: "1.0.2",
                        applicationName: "吊大助手",
                        applicationLegalese: "copyright © 2023 常州大学开源软件协会",
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.book),
                    title: const Text("日志"),
                    subtitle: const Text("Log"),
                    onTap: () => pushMaterialRoute(
                      builder: (context) => const LogPage(),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
