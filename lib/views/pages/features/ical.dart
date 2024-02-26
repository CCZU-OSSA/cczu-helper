import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:arche/extensions/functions.dart';
import 'package:arche/extensions/io.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/platform.dart';
import 'package:cczu_helper/messages/ical.pb.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ICalendarFeature extends StatefulWidget {
  const ICalendarFeature({super.key});

  @override
  State<StatefulWidget> createState() => ICalendarFeatureState();
}

class ICalendarFeatureState extends State<ICalendarFeature> {
  bool _busy = false;
  late String firstweekdate;
  String reminder = "15";

  @override
  void initState() {
    super.initState();
    var now = DateTime.now();
    firstweekdate =
        "${now.year}${now.month.toString().padLeft(2, "0")}${now.day.toString().padLeft(2, "0")}";
    ICalJsonCallback.rustSignalStream.listen((event) {
      setState(() {
        _busy = false;
      });
      var data = event.message;
      if (data.ok) {
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
                          saveFile(data.data, fileName: "class.ics");
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
                        platDirectory.getValue().then((value) => value
                            .subFile("_curriculum.ics")
                            .writeAsString(data.data)
                            .then((value) => Navigator.of(context).pop()));
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
                          XFile.fromData(utf8.encode(data.data),
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
    });
  }

  void generateICalendar(FutureOr<AccountData> account) async {
    var data = await account;
    UserDataSyncInput(
      username: data.studentID,
      password: data.edusysPassword,
      firstweekdate: firstweekdate,
      reminder: reminder,
    ).sendSignalToRust(null);
  }

  @override
  Widget build(BuildContext context) {
    var pageItems = [
      const Expanded(
        flex: 3,
        child: Card(
          child: Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox.expand(
                child: Text("什么是 ICalendar 课表?"),
              )),
        ),
      ),
      Expanded(
        flex: 2,
        child: Column(
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
                        title: const Text("输入整数"),
                        decoration: const InputDecoration(
                          labelText: "课前提醒",
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
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("\"$value\" 不是一个整数")));
                        }
                      }),
                    );
              },
            ),
          ],
        ),
      )
    ];

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          var account =
              ArcheBus().of<ApplicationConfigs>().currentAccount.tryGet();
          var messager = ScaffoldMessenger.of(context);
          if (account == null) {
            messager
                .showSnackBar(const SnackBar(content: Text("请先在设置中添加并选择账户")));
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
        child: _busy
            ? const CircularProgressIndicator()
            : const Icon(Icons.public),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: isWideScreen(context)
            ? Row(children: pageItems)
            : Column(children: pageItems),
      ),
    );
  }
}
