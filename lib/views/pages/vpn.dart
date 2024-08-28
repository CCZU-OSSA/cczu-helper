import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:cczu_helper/controllers/accounts.dart';
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
    MultiAccoutData account = ArcheBus().of();
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
                SwitchListTile(
                  title: const Text("启用"),
                  subtitle: const Text("Enable"),
                  secondary: const Icon(Icons.public),
                  value: enableVPN,
                  onChanged: (value) {
                    if (value && !account.hasCurrentSSOAccount()) {
                      ComplexDialog.instance
                          .withContext(context: context)
                          .text(content: const Text("请先填写选中 SSO 账户"));
                      return;
                    }

                    setState(() {
                      enableVPN = value;
                    });
                  },
                )
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
