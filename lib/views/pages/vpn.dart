import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:cczu_helper/controllers/accounts.dart';
import 'package:cczu_helper/messages/vpn.pb.dart';
import 'package:flutter/material.dart';

class VPNServicePage extends StatefulWidget {
  const VPNServicePage({super.key});

  @override
  State<StatefulWidget> createState() => VPNServicePageState();
}

class VPNServicePageState extends State<VPNServicePage> {
  static bool enableVPN = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Card(
            child: Padding(
              padding: EdgeInsets.only(
                top: 12,
                bottom: 12,
              ),
              child: Wrap(children: [
                ListTile(
                  title: Text("启用"),
                  subtitle: Text("Enable"),
                  leading: Icon(Icons.public),
                  trailing: VPNSwitcher(),
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
  const VPNSwitcher({super.key});

  @override
  State<StatefulWidget> createState() => VPNSwitcherState();
}

class VPNSwitcherState extends State<VPNSwitcher> {
  static bool enableVPN = false;

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
        var message = snapshot.data;
        if (message == null) {
          return const CircularProgressIndicator();
        }

        //TODO Connect VPN

        return Switch(
            value: true,
            onChanged: (value) {
              //TODO Shutdown VPN session
              setState(() {
                enableVPN = false;
              });
            });
      },
    );
  }
}
