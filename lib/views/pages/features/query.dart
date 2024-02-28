import 'package:arche/arche.dart';
import 'package:cczu_helper/controllers/platform.dart';
import 'package:flutter/material.dart';

class QueryFeature extends StatefulWidget {
  const QueryFeature({super.key});

  @override
  State<StatefulWidget> createState() => QueryFeatureState();
}

class QueryFeatureState extends State<QueryFeature>
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
    var pageItems = [
      const Expanded(
        flex: 3,
        child: Card(
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Padding(
                padding: EdgeInsets.all(36),
                child: Column(children: [
                  Text(
                    "0/30",
                    style: TextStyle(fontSize: 24),
                  ),
                  Text(
                    "最后更新日期 2024/2/1",
                    style: TextStyle(fontSize: 8),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
      const Expanded(
        flex: 2,
        child: SizedBox.expand(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text("说明"),
                  subtitle: Text("README"),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text("尚未完成，请持续关注"),
                )
              ],
            ),
          ),
        ),
      ),
    ];

    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _fabAnimationController.reset();
              _fabAnimationController.forward();
            });

            ComplexDialog.instance
                .copy(
                  barrierDismissible: false,
                  child: const Dialog.fullscreen(
                    child: Center(
                      child: ProgressIndicatorWidget(
                        data: ProgressIndicatorWidgetData(text: "请耐心等待..."),
                      ),
                    ),
                  ),
                )
                .prompt(context: context);
          },
          child: RotationTransition(
            turns: _fabAnimationController,
            child: const Icon(Icons.refresh),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: isWideScreen(context)
              ? Row(
                  children: pageItems,
                )
              : Column(children: pageItems),
        ));
  }
}
