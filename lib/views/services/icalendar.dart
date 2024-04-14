import 'package:cczu_helper/views/widgets/adaptive.dart';
import 'package:cczu_helper/views/widgets/progressive.dart';
import 'package:flutter/material.dart';

class ICalendarServicePage extends StatefulWidget {
  const ICalendarServicePage({super.key});

  @override
  State<StatefulWidget> createState() => ICalendarServicePageState();
}

class ICalendarServicePageState extends State<ICalendarServicePage> {
  late DateTime firstweekdate;
  int? reminder = null;
  final GlobalKey<ProgressiveViewState> _progressiveKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    firstweekdate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    var displayDate =
        "${firstweekdate.year} 年 ${firstweekdate.month} 月 ${firstweekdate.day} 日";
    return ProgressiveView(
      key: _progressiveKey,
      children: [
        AdaptiveView(
            cardMargin: const EdgeInsets.only(bottom: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    "设置日期",
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                const Card.outlined(
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Padding(
                        padding: EdgeInsets.all(8), child: Text("说明....")),
                  ),
                ),
                Card.outlined(
                  child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(displayDate))),
                ),
                const SizedBox(
                  height: 8,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: FilledButton(
                      onPressed: () {
                        showDatePicker(
                                context: context,
                                initialDate: firstweekdate,
                                firstDate: DateTime.now()
                                    .add(const Duration(days: -365)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)))
                            .then((value) {
                          if (value != null) {
                            setState(() {
                              firstweekdate = value;
                            });
                          }
                        });
                      },
                      child: const Text("更改日期"),
                    ),
                  ),
                )
              ],
            )),
        const AdaptiveView(
          cardMargin: EdgeInsets.only(bottom: 48),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "设置提醒",
                style: TextStyle(fontSize: 24),
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Card.outlined(
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child:
                    Padding(padding: EdgeInsets.all(8), child: Text("说明....")),
              ),
            ),
          ]),
        ),
        AdaptiveView(
          cardMargin: const EdgeInsets.only(bottom: 48),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "生成课程表",
                style: TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Wrap(spacing: 8, runSpacing: 8, children: [
              InkWell(
                onTap: () => _progressiveKey.currentState!.animateToPage(0),
                child: Chip(label: Text(displayDate)),
              ),
              InkWell(
                onTap: () => _progressiveKey.currentState!.animateToPage(1),
                child: const Chip(label: Text("15 分钟")),
              )
            ]),
          ]),
        ),
      ],
      onSubmit: () {},
    );
  }
}
