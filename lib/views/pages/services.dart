import 'dart:io';

import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:arche/extensions/functions.dart';
import 'package:cczu_helper/controllers/accounts.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/views/pages/account.dart';
import 'package:cczu_helper/views/services/edu/wechat/ranks.dart';
import 'package:cczu_helper/views/services/sso/grades.dart';
import 'package:cczu_helper/views/services/common/icalendar.dart';
import 'package:cczu_helper/views/services/misc/cmcc_account.dart';
import 'package:cczu_helper/views/services/edu/wechat/grades.dart';
import 'package:cczu_helper/views/services/sso/lab.dart';
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
    _tabController.dispose();

    super.dispose();
  }

  static void accountCheckOnTap(Predicate<MultiAccoutData> predicate,
      BuildContext context, ServiceItem item) {
    if (predicate.test(ArcheBus().of())) {
      var service = item.service;
      if (service != null) {
        pushMaterialRoute(
          builder: (context) => service,
        );
      }
    } else {
      ComplexDialog.instance
          .confirm(
              context: context,
              title: const Text("账户未填写!"),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("还未填写或选中账户，确认使用此功能？"),
                  const SizedBox(
                    height: 4,
                  ),
                  FilledButton(
                      onPressed: () => pushMaterialRoute(
                            builder: (context) => const AccountManagePage(),
                          ),
                      child: const Text("打开账户设置"))
                ],
              ))
          .then((confirmed) {
        if (confirmed) {
          var service = item.service;
          if (service != null) {
            pushMaterialRoute(
              builder: (context) => service,
            );
          }
        }
      });
    }
  }

  static void eduCheckOnTap(BuildContext context, ServiceItem item) async =>
      accountCheckOnTap(
          (account) => account.hasCurrentEduAccount(), context, item);

  static void ssoCheckOnTap(BuildContext context, ServiceItem item) async =>
      accountCheckOnTap(
          (account) => account.hasCurrentSSOAccount(), context, item);

  final _services = {
    "教务系统": [
      const ServiceItem(
        text: "生成课程表(企微)",
        service: ICalendarServicePage(
          api: ICalendarAPIType.wechat,
        ),
        image: AssetImage("assets/icalendar.png"),
        onTap: eduCheckOnTap,
      ),
      const ServiceItem(
        text: "查询成绩(企微)",
        service: WeChatGradeQueryServicePage(),
        image: AssetImage("assets/grade.png"),
        onTap: eduCheckOnTap,
      ),
      const ServiceItem(
        text: "排名绩点(企微)",
        service: WeChatRankServicePage(),
        image: AssetImage("assets/rank.png"),
        onTap: eduCheckOnTap,
      )
    ],
    "一网通办": [
      const ServiceItem(
        text: "生成课程表",
        service: ICalendarServicePage(
          api: ICalendarAPIType.jwcas,
        ),
        image: AssetImage("assets/icalendar.png"),
        onTap: ssoCheckOnTap,
      ),
      const ServiceItem(
        text: "查询成绩",
        service: GradeQueryServicePage(),
        image: AssetImage("assets/grade.png"),
        onTap: ssoCheckOnTap,
      ),
      const ServiceItem(
        text: "实验室时长",
        service: LabServicePage(),
        image: AssetImage("assets/lab.png"),
        onTap: ssoCheckOnTap,
      )
    ],
    if (Platform.isWindows)
      "杂项": [
        Visibility(
          visible: Platform.isWindows,
          child: const ServiceItem(
            text: "生成CMCC宽带拨号账户",
            service: CMCCAccoutService(),
            image: AssetImage("assets/cmcc_account.png"),
          ),
        ),
      ]
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
              .toList(),
        ),
        body: TabBarView(
          children: _services.values
              .map(
                (items) => SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Wrap(
                      children: items,
                    ),
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
  final Function(BuildContext context, ServiceItem item)? onTap;
  const ServiceItem({
    super.key,
    this.text = "",
    this.image = const AssetImage("assets/cczu_helper_icon.png"),
    this.service,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    var mediaWidth = MediaQuery.of(context).size.width;
    double dimesion = 200;
    if (mediaWidth ~/ 200 <= 2) {
      dimesion = (mediaWidth - 16) / 2;
    }

    return SizedBox.square(
      dimension: dimesion,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (onTap != null) {
              onTap!(context, this);
              return;
            }
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
