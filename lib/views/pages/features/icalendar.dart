import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:arche/extensions/functions.dart';
import 'package:arche/extensions/io.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/platform.dart';
import 'package:cczu_helper/controllers/scheduler.dart';
import 'package:cczu_helper/controllers/snackbar.dart';
import 'package:cczu_helper/messages/common.pb.dart';
import 'package:cczu_helper/models/channel.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:cczu_helper/views/widgets/featureview.dart';
import 'package:cczu_helper/views/widgets/markdown.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ICalendarFeature extends StatefulWidget {
  const ICalendarFeature({super.key});

  @override
  State<StatefulWidget> createState() => ICalendarFeatureState();
}

class ICalendarFeatureState extends State<ICalendarFeature>
    with NativeChannelSubscriber {
  bool _busy = false;
  late String firstweekdate;
  String reminder = "15";

  @override
  void initState() {
    super.initState();
    var now = DateTime.now();
    firstweekdate =
        "${now.year}${now.month.toString().padLeft(2, "0")}${now.day.toString().padLeft(2, "0")}";
    subscriber = DartReceiveChannel.rustSignalStream.listen(
      (event) {
        setState(() {
          _busy = false;
        });
        var data = event.message;
        if (data.ok) {
          var text = data.data;
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const ListTile(
                        title: Text("完成！请保存你的课表！"),
                      ),
                      Visibility(
                        visible: !Platform.isAndroid,
                        child: FilledButton.icon(
                          onPressed: () {
                            var time = DateTime.now();
                            saveFile(text,
                                fileName:
                                    "${time.year}${time.month.toString().padLeft(2, "0")}${time.day.toString().padLeft(2, "0")}${time.hour.toString().padLeft(2, "0")}${time.minute.toString().padLeft(2, "0")}.ics");
                          },
                          icon: const Icon(Icons.save),
                          label: const SizedBox(
                              width: double.infinity,
                              child: Center(child: Text("保存到本地"))),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      FilledButton.icon(
                        onPressed: () async {
                          platDirectory.getValue().then(
                                (value) => value
                                    .subFile("_curriculum.ics")
                                    .writeAsString(text)
                                    .then(
                                      (value) => ComplexDialog.instance.text(
                                        context: context,
                                        title: const Text("导入成功"),
                                        content: const Text("请返回课程表页面查看"),
                                      ),
                                    )
                                    .then((value) {
                                  curriculmKey.currentState?.refresh();

                                  if (Platform.isAndroid) {
                                    Scheduler.reScheduleAll(context);
                                  }
                                }),
                              );
                        },
                        icon: const Icon(Icons.calendar_month),
                        label: const SizedBox(
                          width: double.infinity,
                          child: Center(
                            child: Text("导入课程表"),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      FilledButton.icon(
                        onPressed: () {
                          Share.shareXFiles([
                            XFile.fromData(utf8.encode(text),
                                mimeType: "text/calendar", name: "class.ics"),
                          ]);
                        },
                        icon: const Icon(Icons.share),
                        label: const SizedBox(
                            width: double.infinity,
                            child: Center(child: Text("分享"))),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          ComplexDialog.instance
              .text(context: context, content: Text(event.message.data));
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    subscriber.cancel();
  }

  void generateICalendar(FutureOr<AccountData> account) async {
    var data = await account;
    RustCallChannel(
            id: channelGenerateICalendar,
            data: ICalendarGenerateData(data, firstweekdate, reminder).encode())
        .sendSignalToRust(null);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Durations.medium4,
      child: _busy
          ? const Center(
              child: ProgressIndicatorWidget(
                data: ProgressIndicatorWidgetData(text: "正在生成课表..."),
              ),
            )
          : Scaffold(
              floatingActionButton: FloatingActionButton(
                child: const Icon(Icons.public),
                onPressed: () {
                  var account = ArcheBus()
                      .of<ApplicationConfigs>()
                      .currentAccount
                      .tryGet();

                  if (account == null) {
                    showSnackBar(
                      context: context,
                      content: const Text("请先在设置中添加并选择账户"),
                    );
                    return;
                  }

                  setState(
                    () {
                      if (!_busy) {
                        generateICalendar(account);
                        _busy = true;
                      }
                    },
                  );
                },
              ),
              body: FeatureView(
                primary: const Card(
                  child: SizedBox(
                    height: double.infinity,
                    child: SizedBox(
                      width: double.infinity,
                      child:
                          READMEWidget(resource: "assets/README_ICALENDAR.md"),
                    ),
                  ),
                ),
                secondary: Column(
                  children: [
                    ListTile(
                      title: const Text("日期"),
                      trailing: Text(firstweekdate.toString()),
                      onTap: () {
                        var now = DateTime.now();
                        showDatePicker(
                          helpText: "课表第一周周一",
                          context: context,
                          initialDate: now,
                          firstDate: now.add(const Duration(days: -365)),
                          lastDate: now.add(const Duration(days: 365)),
                        ).then(
                          (value) => whenNotNull(
                            value,
                            (value) => setState(() {
                              firstweekdate =
                                  "${value.year}${value.month.toString().padLeft(2, "0")}${value.day.toString().padLeft(2, "0")}";
                            }),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      title: const Text("课前提醒"),
                      trailing: Text("$reminder 分钟"),
                      onTap: () {
                        ComplexDialog.instance
                            .input(
                                context: context,
                                autofocus: true,
                                title: const Text("输入整数"),
                                decoration: const InputDecoration(
                                  labelText: "课前提醒(分钟)",
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number)
                            .then(
                              (value) => whenNotNull(value, (text) {
                                if (int.tryParse(text) != null) {
                                  setState(() {
                                    reminder = text;
                                  });
                                } else {
                                  showSnackBar(
                                    context: context,
                                    content: Text("\"$value\" 不是一个整数"),
                                  );
                                }
                              }),
                            );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
