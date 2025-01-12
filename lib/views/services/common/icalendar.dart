import 'dart:async';
import 'dart:convert';

import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:arche/extensions/io.dart';
import 'package:arche/extensions/iter.dart';
import 'package:cczu_helper/controllers/accounts.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/messages/all.dart';
import 'package:cczu_helper/views/pages/account.dart';
import 'package:cczu_helper/views/widgets/adaptive.dart';
import 'package:cczu_helper/views/widgets/markdown.dart';
import 'package:cczu_helper/views/widgets/progressive.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rinf/rinf.dart';
import 'package:share_plus/share_plus.dart';

enum ICalendarAPIType { wechat, jwcas }

class ICalendarServicePage extends StatefulWidget {
  final ICalendarAPIType? api;

  const ICalendarServicePage({super.key, this.api});

  @override
  State<StatefulWidget> createState() => ICalendarServicePageState();
}

class ICalendarServicePageState extends State<ICalendarServicePage> {
  final GlobalKey<ProgressiveViewState> _progressiveKey = GlobalKey();
  ICalendarAPIType? api;
  late StreamSubscription<RustSignal<ICalendarOutput>> _streamICalendarOutput;
  late DateTime firstweekdate;
  int? reminder;
  bool _underGenerating = false;
  String? term;
  List<String>? terms;

  @override
  void initState() {
    super.initState();
    api = widget.api;
    firstweekdate = DateTime.now();
    _streamICalendarOutput = ICalendarOutput.rustSignalStream.listen(
      (event) {
        if (!mounted) {
          return;
        }

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
                          child: Center(child: Text("分享至...")),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      FilledButton.icon(
                        onPressed: () async {
                          var dir = await platCalendarDataDirectory.getValue();
                          await dir
                              .subFile("calendar_curriculum.ics")
                              .writeAsString(data)
                              .then((value) {
                            if (mounted) {
                              ComplexDialog.instance.text(
                                  context: this.context,
                                  content: const Text("导入成功"));
                            }
                          });
                        },
                        icon: const Icon(FontAwesomeIcons.fileImport),
                        label: const SizedBox(
                          width: double.infinity,
                          child: Center(child: Text("导入常大助手")),
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
    _streamICalendarOutput.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    GlobalKey<PopupMenuButtonState> termPopMenuKey = GlobalKey();
    if (_underGenerating) {
      return const Scaffold(
        body: Center(
          child: ProgressIndicatorWidget(),
        ),
      );
    }

    if (api == null) {
      return Scaffold(
        appBar: AppBar(),
        body: AdaptiveView(
          cardMargin: const EdgeInsets.only(bottom: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  "选择数据源 (将会使用不同账户)",
                  style: TextStyle(fontSize: 24),
                ),
              ),
              FilledButton(
                  onPressed: () {
                    pushMaterialRoute(
                      builder: (context) => const AccountManagePage(),
                    );
                  },
                  child: const Text("打开账户管理")),
              FilledButton(
                  onPressed: () {
                    setState(() {
                      api = ICalendarAPIType.jwcas;
                    });
                  },
                  child: const Text("使用一网通办数据源")),
              FilledButton(
                  onPressed: () {
                    setState(() {
                      api = ICalendarAPIType.wechat;
                    });
                  },
                  child: const Text("使用企业微信数据源 (推荐) (使用教务系统账户)"))
            ].joinElement(const SizedBox(
              height: 8,
            )),
          ),
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
          child: AssetMarkdown(resource: "assets/README_ICALENDAR_START.md"),
        ),
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
        if (api == ICalendarAPIType.wechat)
          AdaptiveView(
            cardMargin: const EdgeInsets.only(bottom: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    "选择学期",
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                const Card.outlined(
                  child: AssetMarkdown(
                      resource: "assets/README_ICALENDAR_TERM.md"),
                ),
                Card.outlined(
                  child: ListTile(
                    title: Text(term ?? "默认"),
                    trailing: PopupMenuButton(
                      key: termPopMenuKey,
                      onSelected: (value) => setState(() {
                        term = value;
                      }),
                      itemBuilder: (context) {
                        if (terms == null || terms!.isEmpty) {
                          WeChatTermsOutput.rustSignalStream.listen((data) {
                            terms = (data.message.terms);
                            termPopMenuKey.currentState?.showButtonMenu();
                          });

                          WeChatTermsInput().sendSignalToRust();
                          terms = [];
                        }

                        return terms!
                            .map((term) =>
                                PopupMenuItem(value: term, child: Text(term)))
                            .toList();
                      },
                      icon: Icon(Icons.adaptive.more),
                    ),
                  ),
                )
              ],
            ),
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
                onPressed: () => _progressiveKey.currentState!.animateToPage(2),
                avatar: const Icon(Icons.alarm),
                label: Text(displayReminder),
              ),
              if (api == ICalendarAPIType.wechat)
                ActionChip(
                  onPressed: () =>
                      _progressiveKey.currentState!.animateToPage(3),
                  avatar: const Icon(Icons.school),
                  label: Text(term ?? "默认"),
                ),
            ]),
          ]),
        ),
      ],
      onSubmit: () {
        var date =
            "${firstweekdate.year}${firstweekdate.month.toString().padLeft(2, "0")}${firstweekdate.day.toString().padLeft(2, "0")}";
        if (api == ICalendarAPIType.wechat) {
          ICalendarWxInput(
            firstweekdate: date,
            reminder: reminder,
            account: ArcheBus.bus.of<MultiAccoutData>().getCurrentEduAccount(),
            term: term,
          ).sendSignalToRust();
        } else {
          ICalendarInput(
            firstweekdate: date,
            reminder: reminder,
            account: ArcheBus.bus.of<MultiAccoutData>().getCurrentSSOAccount(),
          ).sendSignalToRust();
        }

        setState(() {
          _underGenerating = true;
        });
      },
    );
  }
}
