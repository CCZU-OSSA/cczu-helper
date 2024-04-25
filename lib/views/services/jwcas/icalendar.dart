import 'dart:async';
import 'dart:convert';

import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:arche/extensions/io.dart';
import 'package:cczu_helper/controllers/account.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/messages/icalendar.pb.dart';
import 'package:cczu_helper/views/widgets/adaptive.dart';
import 'package:cczu_helper/views/widgets/markdown.dart';
import 'package:cczu_helper/views/widgets/progressive.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rinf/rinf.dart';
import 'package:share_plus/share_plus.dart';

class ICalendarServicePage extends StatefulWidget {
  const ICalendarServicePage({super.key});

  @override
  State<StatefulWidget> createState() => ICalendarServicePageState();
}

class ICalendarServicePageState extends State<ICalendarServicePage> {
  final GlobalKey<ProgressiveViewState> _progressiveKey = GlobalKey();

  late StreamSubscription<RustSignal<ICalendarOutput>> _streamICalendarOutput;
  late DateTime firstweekdate;
  int? reminder;
  bool _underGenerating = false;

  @override
  void initState() {
    super.initState();
    firstweekdate = DateTime.now();
    _streamICalendarOutput = ICalendarOutput.rustSignalStream.listen(
      (event) {
        setState(() {
          _underGenerating = false;
        });
        var message = event.message;

        if (!message.ok) {
          ComplexDialog.instance
              .text(context: context, content: Text(message.data));
        } else {
          var data = message.data;
          showModalBottomSheet(
            context: context,
            builder: (context) => SizedBox.expand(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          "完成!",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const Divider(),
                      FilledButton.icon(
                        onPressed: () {
                          Share.shareXFiles([
                            XFile.fromData(utf8.encode(data),
                                mimeType: "text/calendar",
                                name: "Curriculum.ics")
                          ]);
                        },
                        icon: const Icon(Icons.share),
                        label: const SizedBox(
                          width: double.infinity,
                          child: Center(child: Text("分享")),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      FilledButton.icon(
                        onPressed: () async {
                          var dir = await platDirectory.getValue();
                          await dir
                              .subFile("_curriculum.ics")
                              .writeAsString(data)
                              .then((value) => ComplexDialog.instance.text(
                                  context: context,
                                  content: const Text("导入成功")));
                        },
                        icon: const Icon(FontAwesomeIcons.fileImport),
                        label: const SizedBox(
                          width: double.infinity,
                          child: Center(child: Text("导入应用日历")),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _streamICalendarOutput.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (_underGenerating) {
      return const Scaffold(
        body: Center(
          child: ProgressIndicatorWidget(),
        ),
      );
    }

    var displayDate =
        "${firstweekdate.year} 年 ${firstweekdate.month} 月 ${firstweekdate.day} 日";
    var displayReminder =
        reminder == null ? "不进行提醒" : "${reminder! ~/ 60} 时 ${reminder! % 60} 分";
    return ProgressiveView(
      key: _progressiveKey,
      children: [
        const AdaptiveView(
            cardMargin: EdgeInsets.only(bottom: 48),
            child: AssetMarkdown(resource: "assets/README_ICALENDAR_START.md")),
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
                  child: AssetMarkdown(
                      resource: "assets/README_ICALENDAR_DATE.md"),
                ),
                Card.outlined(
                  child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(displayDate))),
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
        AdaptiveView(
          cardMargin: const EdgeInsets.only(bottom: 48),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "设置提醒",
                style: TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            const Card.outlined(
              child: AssetMarkdown(
                  resource: "assets/README_ICALENDAR_REMINDER.md"),
            ),
            Card.outlined(
              child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(displayReminder))),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: FilledButton(
                  onPressed: () {
                    showTimePicker(
                      context: context,
                      initialTime: reminder == null
                          ? const TimeOfDay(hour: 0, minute: 0)
                          : TimeOfDay(
                              hour: reminder! ~/ 60, minute: reminder! % 60),
                      initialEntryMode: TimePickerEntryMode.input,
                    ).then((value) {
                      if (value != null) {
                        int totalMinutes = value.hour * 60 + value.minute;

                        setState(() {
                          reminder = totalMinutes;
                          if (totalMinutes == 0) {
                            reminder = null;
                          }
                        });
                      }
                    });
                  },
                  child: const Text("更改提醒"),
                ),
              ),
            )
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
              ActionChip(
                onPressed: () => _progressiveKey.currentState!.animateToPage(0),
                avatar: const Icon(Icons.book),
                label: const Text("说明"),
              ),
              ActionChip(
                onPressed: () => _progressiveKey.currentState!.animateToPage(1),
                avatar: const Icon(Icons.date_range),
                label: Text(displayDate),
              ),
              ActionChip(
                  onPressed: () =>
                      _progressiveKey.currentState!.animateToPage(2),
                  avatar: const Icon(Icons.alarm),
                  label: Text(displayReminder)),
            ]),
          ]),
        ),
      ],
      onSubmit: () {
        readAccount().then((value) {
          if (value != null) {
            var date =
                "${firstweekdate.year}${firstweekdate.month.toString().padLeft(2, "0")}${firstweekdate.day.toString().padLeft(2, "0")}";

            ICalendarInput(
              firstweekdate: date,
              reminder: reminder,
              account: value,
            ).sendSignalToRust(null);
            setState(() {
              _underGenerating = true;
            });
          } else {
            ComplexDialog.instance
                .text(context: context, title: const Text("账户读取错误"));
          }
        });
      },
    );
  }
}
