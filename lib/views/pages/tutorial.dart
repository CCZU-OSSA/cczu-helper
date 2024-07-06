import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/views/pages/account.dart';
import 'package:cczu_helper/views/widgets/adaptive.dart';
import 'package:cczu_helper/views/widgets/markdown.dart';
import 'package:cczu_helper/views/widgets/progressive.dart';
import 'package:flutter/material.dart';

class TutorialPage extends StatelessWidget {
  final Function() onSubmit;

  const TutorialPage({super.key, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return ProgressiveView(showAppBar: false, onSubmit: onSubmit, children: [
      AdaptiveView(
          cardMargin: const EdgeInsets.only(bottom: 40, top: 40),
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
          ))
    ]);
  }
}
