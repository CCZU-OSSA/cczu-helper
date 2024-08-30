import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:cczu_helper/controllers/accounts.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/messages/vpn.pb.dart';
import 'package:cczu_helper/plugins/enlink_vpn.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class VPNServicePage extends StatefulWidget {
  const VPNServicePage({super.key});

  @override
  State<StatefulWidget> createState() => VPNServicePageState();
}

class VPNServicePageState extends State<VPNServicePage> {
  static List<String> apps = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 12,
                bottom: 12,
              ),
              child: Wrap(children: [
                ListTile(
                  title: const Text("启用"),
                  subtitle: const Text("Enable"),
                  leading: const Icon(Icons.public),
                  trailing: VPNSwitcher(
                    apps: apps,
                  ),
                ),
                ListTile(
                  title: const Text("应用"),
                  subtitle: const Text("Applications"),
                  leading: const Icon(Icons.apps),
                  onTap: () {
                    pushMaterialRoute<List<String>>(
                      builder: (context) {
                        return InstallAppSelector(
                          apps: apps,
                        );
                      },
                    ).then(
                      (selected) {
                        if (selected != null) {
                          setState(() {
                            apps = selected;
                          });
                        }
                      },
                    );
                  },
                  trailing: Text(apps.length.toString()),
                )
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class VPNSwitcher extends StatefulWidget {
  final List<String> apps;
  const VPNSwitcher({super.key, required this.apps});

  @override
  State<StatefulWidget> createState() => VPNSwitcherState();
}

class VPNSwitcherState extends State<VPNSwitcher> {
  static bool enableVPN = false;
  static MethodChannelFlutterVpn channel = MethodChannelFlutterVpn();

  @override
  Widget build(BuildContext context) {
    var account = ArcheBus().of<MultiAccoutData>();

    if (!enableVPN) {
      return Switch(
        value: false,
        onChanged: (value) {
          if (!account.hasCurrentSSOAccount()) {
            ComplexDialog.instance
                .withContext(context: context)
                .text(content: const Text("请先填写选中 SSO 账户"));
            return;
          }

          VPNServiceUserInput(account: account.getCurrentSSOAccount())
              .sendSignalToRust();

          setState(() {
            enableVPN = true;
          });
        },
      );
    }
    return StreamBuilder(
      stream: VPNServiceUserOutput.rustSignalStream,
      builder: (context, snapshot) {
        var data = snapshot.data;
        if (data == null) {
          return const CircularProgressIndicator();
        }
        var message = data.message;

        if (!message.ok) {
          setState(() {
            enableVPN = false;
          });

          ComplexDialog.instance
              .withContext(context: context)
              .text(content: Text(message.err));
          return const CircularProgressIndicator();
        }

        channel.start(
          user: account.getCurrentSSOAccount().user,
          token: message.token,
          dns: message.dns,
          apps: widget.apps.join(","),
        );

        return Switch(
          value: true,
          onChanged: (value) {
            channel.stop();
            setState(() {
              enableVPN = false;
            });
          },
        );
      },
    );
  }
}

class InstallAppSelector extends StatefulWidget {
  final List<String> apps;

  const InstallAppSelector({super.key, required this.apps});

  @override
  State<StatefulWidget> createState() => InstallAppSelectorState();
}

class InstallAppSelectorState extends State<InstallAppSelector> {
  late List<String> selected;
  @override
  void initState() {
    super.initState();
    selected = widget.apps;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pop(selected),
        child: const Icon(Icons.check),
      ),
      body: FutureBuilder(
        future: InstalledApps.getInstalledApps(true, true),
        builder: (context, snapshot) {
          var data = snapshot.data;

          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return AppInfoListView(apps: data, selected: selected);
        },
      ),
    );
  }
}

class AppInfoListView extends StatefulWidget {
  final List<AppInfo> apps;
  final List<String> selected;
  const AppInfoListView(
      {super.key, required this.apps, required this.selected});

  @override
  State<StatefulWidget> createState() => AppInfoListViewState();
}

class AppInfoListViewState extends State<AppInfoListView> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: widget.apps
          .map((app) => ListTile(
                title: Text(app.name),
                subtitle: Text(app.packageName),
                trailing: Checkbox(
                  value: widget.selected.contains(app.packageName),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      if (value) {
                        widget.selected.add(app.packageName);
                      } else {
                        widget.selected.remove(app.packageName);
                      }
                    });
                  },
                ),
              ))
          .toList(),
    );
  }
}
