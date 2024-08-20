import 'package:arche/arche.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:cczu_helper/views/pages/account.dart';
import 'package:cczu_helper/views/widgets/adaptive.dart';
import 'package:cczu_helper/views/widgets/markdown.dart';
import 'package:flutter/material.dart';

class TutorialPage extends StatelessWidget {
  final bool showFAB;

  const TutorialPage({super.key, this.showFAB = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Visibility(
        visible: showFAB,
        child: FloatingActionButton(
            child: const Icon(Icons.check),
            onPressed: () {
              ArcheBus().of<ApplicationConfigs>().firstUse.write(false);
              viewKey.currentState?.refreshMounted();
            }),
      ),
      body: SafeArea(
        top: true,
        child: AdaptiveView(
          cardMargin: const EdgeInsets.only(top: 48, bottom: 48),
          child: Column(
            children: [
              const AssetMarkdown(resource: "assets/README_TUTORIAL.md"),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                    onPressed: () {
                      pushMaterialRoute(
                        builder: (context) => const AccountManagePage(),
                      );
                    },
                    child: const Text("打开账户管理")),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
