import 'package:arche/arche.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/views/widgets/featureview.dart';
import 'package:cczu_helper/views/widgets/termview.dart';
import 'package:flutter/material.dart';

class CheckInFeature extends StatefulWidget {
  const CheckInFeature({super.key});

  @override
  State<StatefulWidget> createState() => CheckInFeatureState();
}

class CheckInFeatureState extends State<CheckInFeature>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(vsync: this)
      ..duration = Durations.medium4;
  }

  @override
  void dispose() {
    super.dispose();
    _fabAnimationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var configs = ArcheBus().of<ApplicationConfigs>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _fabAnimationController.reset();
            _fabAnimationController.forward();
          });
        },
        child: RotationTransition(
          turns: _fabAnimationController,
          child: const Icon(Icons.refresh),
        ),
      ),
      body: FeatureView(
        primary: const Card(
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Padding(
                padding: EdgeInsets.all(36),
                child: Column(children: [
                  Text(
                    "114/514",
                    style: TextStyle(fontSize: 24),
                  ),
                  Text(
                    "最后更新日期 2077/7/21",
                    style: TextStyle(fontSize: 8),
                  ),
                ]),
              ),
            ),
          ),
        ),
        secondary: ListView(
          children: [
            const ListTile(
              leading: Icon(Icons.book),
              title: Text("说明"),
              subtitle: Text("README"),
            ),
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text("由于教务系统可能会进行更新，所以本功能暂时搁置以等待适配新的打卡系统，请持续关注"),
            ),
            ListTile(
              title: const Text("学期"),
              trailing: Text(configs.termname.tryGet().toString()),
              onTap: () => pushMaterialRoute(
                builder: (context) => TermView(
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
