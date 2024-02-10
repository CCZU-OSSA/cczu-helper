import 'package:arche/arche.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/views/pages/features/query.dart';
import 'package:cczu_helper/views/widgets/scrollable.dart';
import 'package:flutter/material.dart';

@immutable
class FeatureItem {
  final Widget child;
  final String name;
  const FeatureItem({required this.name, required this.child});

  FeatureItem copy({
    String? name,
    Widget? child,
  }) {
    return FeatureItem(
      name: name ?? this.name,
      child: child ?? this.child,
    );
  }

  Function() onTap() => () => pushMaterialRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(name),
          ),
          body: child,
        ),
      );
}

class FeaturesPage extends StatefulWidget {
  const FeaturesPage({super.key});

  @override
  State<StatefulWidget> createState() => FeaturesPageState();
}

class FeaturesPageState extends State<FeaturesPage>
    with TickerProviderStateMixin {
  late AnimationController controller;

  bool useListView = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this)..duration = Durations.medium4;
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  static final List<FeatureItem> features = [
    const FeatureItem(
      name: "打卡查询",
      child: QueryPage(),
    )
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (useListView) {
            controller.forward();
          } else {
            controller.reverse();
          }
          setState(() {
            useListView = !useListView;
          });
        },
        child:
            AnimatedIcon(icon: AnimatedIcons.list_view, progress: controller),
      ),
      body: PaddingScrollView(
          child: AnimatedSwitcher(
        duration: Durations.medium4,
        child: useListView
            ? Column(
                children: features
                    .map(
                      (e) => CardButton(
                        onTap: e.onTap,
                        child: ListTile(
                          title: Text(e.name),
                        ),
                      ),
                    )
                    .toList(),
              )
            : Wrap(
                alignment: WrapAlignment.center,
                children: features
                    .map(
                      (e) => CardButton(
                        size: const Size.square(127),
                        onTap: e.onTap,
                        child: Text(e.name),
                      ),
                    )
                    .toList()),
      )),
    );
  }
}
