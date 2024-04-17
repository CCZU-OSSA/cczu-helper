import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/views/services/grade.dart';
import 'package:cczu_helper/views/services/icalendar.dart';
import 'package:flutter/material.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  State<StatefulWidget> createState() => ServicePageState();
}

class ServicePageState extends State<ServicePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  final _services = {
    "教务系统": [
      const ServiceItem(
        text: "生成课程表",
        service: ICalendarServicePage(),
      ),
      const ServiceItem(
        text: "查询成绩",
        service: GradeQueryServicePage(),
      )
    ],
  };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _services.length,
      child: Scaffold(
        appBar: TabBar(
            tabAlignment: TabAlignment.start,
            isScrollable: true,
            splashBorderRadius: BorderRadius.circular(8),
            tabs: _services.keys
                .map((e) => Tab(
                      text: e,
                    ))
                .toList()),
        body: TabBarView(
          children: _services.values
              .map(
                (items) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    children: items,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class ServiceItem extends StatelessWidget {
  final String text;
  final Widget? service;
  final ImageProvider image;
  const ServiceItem({
    super.key,
    this.text = "",
    this.image = const AssetImage("assets/cczu_helper_icon.png"),
    this.service,
  });

  @override
  Widget build(BuildContext context) {
    var mediaWidth = MediaQuery.of(context).size.width;
    double dimesion = 200;
    if (mediaWidth ~/ 200 <= 2) {
      dimesion = ((mediaWidth - 16) ~/ 2).toDouble();
    }

    return SizedBox.square(
      dimension: dimesion,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (service != null) {
              pushMaterialRoute(
                builder: (context) => service!,
              );
            }
          },
          child: Column(
            children: [
              Flexible(
                flex: 7,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: image,
                    ),
                    color: Theme.of(context).colorScheme.surfaceTint,
                  ),
                ),
              ),
              Flexible(
                flex: 3,
                child: SizedBox.expand(
                  child: Center(child: Text(text)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
