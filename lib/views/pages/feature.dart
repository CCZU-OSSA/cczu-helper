import 'package:arche/arche.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/views/pages/features/cczuwifi.dart';
import 'package:cczu_helper/views/pages/features/grades.dart';
import 'package:cczu_helper/views/pages/features/icalendar.dart';
import 'package:cczu_helper/views/pages/features/checkin.dart';
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

  void onTap() => pushMaterialRoute(
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
    cardSize = ArcheBus.bus.of<ApplicationConfigs>().cardsize.getOr(166);
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  static final List<FeatureItem> features = [
    const FeatureItem(
      name: "打卡查询",
      child: CheckInFeature(),
    ),
    const FeatureItem(
      name: "课表生成",
      child: ICalendarFeature(),
    ),
    const FeatureItem(
      name: "成绩查询",
      child: GradesFeature(),
    ),
    const FeatureItem(
      name: "WIFI认证",
      child: CCZUWifiFeature(),
    ),
  ];

  late double cardSize;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: GestureDetector(
        onLongPress: () {
          if (!useListView) {
            ComplexDialog.instance
                .withChild(
                  ValueStateBuilder(
                    builder: (context, state) {
                      return AlertDialog(
                        title: Row(
                          children: [
                            const Text("卡片大小"),
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    cardSize = 166;
                                  });
                                  state.update(166);
                                },
                                icon: const Icon(Icons.restore))
                          ],
                        ),
                        content: SizedBox(
                          width: 300,
                          height: 80,
                          child: Slider(
                            value: state.value,
                            min: 100,
                            max: 400,
                            onChanged: (value) {
                              setState(() {
                                cardSize = value;
                              });
                              state.update(value);
                            },
                          ),
                        ),
                      );
                    },
                    init: cardSize,
                  ),
                )
                .prompt(context: context);
          }
        },
        child: FloatingActionButton(
          onPressed: () {
            if (useListView) {
              controller.reverse();
            } else {
              controller.forward();
            }
            setState(() {
              useListView = !useListView;
            });
          },
          child:
              AnimatedIcon(icon: AnimatedIcons.list_view, progress: controller),
        ),
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
                          child: IgnorePointer(
                            child: ListTile(
                              title: Text(e.name),
                            ),
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
                          size: Size.square(cardSize),
                          onTap: e.onTap,
                          child: Padding(
                            padding: EdgeInsets.all(cardSize / 8),
                            child: FittedBox(child: Text(e.name)),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ),
    );
  }
}
