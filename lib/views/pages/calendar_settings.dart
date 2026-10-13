import 'dart:io';
import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:arche/extensions/io.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/controllers/snackbar.dart';
import 'package:cczu_helper/views/pages/settings.dart';
import 'package:cczu_helper/views/widgets/scrollable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoDatePicker, CupertinoDatePickerMode;
import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' show basenameWithoutExtension, extension;

class CalendarSettings extends StatefulWidget {
  const CalendarSettings({super.key});

  @override
  State<StatefulWidget> createState() => _CalendarSettingsState();
}

class _CalendarSettingsState extends State<CalendarSettings> {
  Future<int?> inputOpacity([String text = ""]) async {
    var input = await ComplexDialog.instance.input(
      context: context,
      title: const Text("透明度 (0~100)%"),
      controller: TextEditingController(text: text),
      decoration: const InputDecoration(border: OutlineInputBorder()),
      keyboardType: const TextInputType.numberWithOptions(),
    );
    if (input == null) {
      return null;
    }

    var result = int.tryParse(input);

    if (result == null || result < 0 || result > 100) {
      if (mounted) {
        showSnackBar(context: context, content: const Text("输入 0-100 的数字"));
      }
    } else {
      return result;
    }

    return null;
  }

  /// 弹出「整点/半点」时间选择器。取消返回 null。
  ///
  /// 用 CupertinoDatePicker 是因为 Material 的 showTimePicker 无法限制分钟步进。
  /// 初始值必须先吸附到 :00/:30 —— CupertinoDatePicker 有断言
  /// `initialDateTime.minute % minuteInterval == 0`，否则 debug 下直接崩溃。
  Future<TimeOfDay?> _showHourHalfPicker(TimeOfDay initial) {
    final snapped = snapToHalfHour(initial);
    final now = DateTime.now();
    var picked =
        DateTime(now.year, now.month, now.day, snapped.hour, snapped.minute);
    return showDialog<TimeOfDay>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("选择时间"),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        content: SizedBox(
          height: 220,
          width: 300,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            minuteInterval: 30,
            use24hFormat: true,
            initialDateTime: picked,
            onDateTimeChanged: (value) {
              picked = value;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("取消"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext,
                TimeOfDay(hour: picked.hour, minute: picked.minute)),
            child: const Text("确定"),
          ),
        ],
      ),
    );
  }

  /// 检查所选时间范围是否切掉了某些课程时刻，若有则弹窗告知。
  ///
  /// 统计单位是「时间点」：每个非全天事件的 start 和 end 各算一个点。
  void _checkOutOfRange(TimeOfDay start, TimeOfDay end) {
    // 该方法在 picker 的 .then() 里被调用，跨过了 async gap，
    // 所以进来先确认 State 还在，避免在已卸载的 State 上取 context 弹窗。
    if (!mounted) {
      return;
    }
    final parsers = icalendarParsersData.value;
    if (parsers == null) {
      return;
    }
    final lower = start.hour * 60 + start.minute;
    final upper = end.hour * 60 + end.minute;
    var count = 0;
    for (final parser in parsers) {
      for (final e in parser.data) {
        if (e.isAllday) {
          continue;
        }
        for (final t in [e.start.toDateTime(), e.end.toDateTime()]) {
          if (t == null) {
            continue;
          }
          final minutes = t.hour * 60 + t.minute;
          if (minutes < lower || minutes > upper) {
            count++;
          }
        }
      }
    }
    if (count > 0) {
      ComplexDialog.instance.text(
        context: context,
        content: Text("有 $count 个课程时间点超出当前时间范围，将不会完整显示"),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ApplicationConfigs configs = ArcheBus().of();

    return Scaffold(
      appBar: AppBar(
        title: const Text("课程表设置"),
      ),
      body: PaddingScrollView(
        child: Column(
          children: [
            SettingGroup(name: "通用", children: [
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text("管理日历文件"),
                subtitle: const Text("Calendar Manager"),
                trailing: const Icon(Icons.arrow_right_rounded),
                onTap: () => pushMaterialRoute(
                  builder: (BuildContext context) =>
                      const CalendarsManagerPage(),
                ),
              )
            ]),
            SettingGroup(name: "外观", children: [
              ListTile(
                leading: const Icon(Icons.sunny),
                title: const Text("日历开始时间"),
                subtitle: const Text("Calendar Start"),
                trailing: Text(snapToHalfHour(configs.calendarTimeStart
                        .getOr(const TimeOfDay(hour: 8, minute: 0)))
                    .format(context)),
                onTap: () {
                  _showHourHalfPicker(configs.calendarTimeStart
                          .getOr(const TimeOfDay(hour: 8, minute: 0)))
                      .then((time) {
                    if (time == null) {
                      return;
                    }
                    final end = configs.calendarTimeEnd
                        .getOr(const TimeOfDay(hour: 21, minute: 0));
                    if (time.hour * 60 + time.minute >=
                        end.hour * 60 + end.minute) {
                      if (mounted) {
                        ComplexDialog.instance.text(
                          context: this.context,
                          content: const Text("开始时间必须早于结束时间"),
                        );
                      }
                      return;
                    }
                    setState(() {
                      configs.calendarTimeStart.write(time);
                    });
                    _checkOutOfRange(time, end);
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.nightlife),
                title: const Text("日历结束时间"),
                subtitle: const Text("Calendar End"),
                trailing: Text(snapToHalfHour(configs.calendarTimeEnd
                        .getOr(const TimeOfDay(hour: 21, minute: 0)))
                    .format(context)),
                onTap: () {
                  _showHourHalfPicker(configs.calendarTimeEnd
                          .getOr(const TimeOfDay(hour: 21, minute: 0)))
                      .then((time) {
                    if (time == null) {
                      return;
                    }
                    final start = configs.calendarTimeStart
                        .getOr(const TimeOfDay(hour: 8, minute: 0));
                    if (time.hour * 60 + time.minute <=
                        start.hour * 60 + start.minute) {
                      if (mounted) {
                        ComplexDialog.instance.text(
                          context: this.context,
                          content: const Text("结束时间必须晚于开始时间"),
                        );
                      }
                      return;
                    }
                    setState(() {
                      configs.calendarTimeEnd.write(time);
                    });
                    _checkOutOfRange(start, time);
                  });
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.color_lens),
                title: const Text("彩色日历"),
                subtitle: const Text("Colorful"),
                value: configs.calendarColorful.getOr(false),
                onChanged: (value) {
                  setState(() {
                    configs.calendarColorful.write(value);
                  });
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.visibility),
                title: const Text("显示分割线"),
                subtitle: const Text("Interval Line"),
                value: configs.calendarIntervalLine.getOr(true),
                onChanged: (value) {
                  setState(() {
                    configs.calendarIntervalLine.write(value);
                  });
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.visibility),
                title: const Text("显示时间标尺"),
                subtitle: const Text("Time Ruler"),
                value: configs.calendarShowTimeRule.getOr(true),
                onChanged: (value) {
                  setState(() {
                    configs.calendarShowTimeRule.write(value);
                  });
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.visibility),
                title: const Text("显示控制栏"),
                subtitle: const Text("Controller"),
                value: configs.calendarShowController.getOr(true),
                onChanged: (value) {
                  setState(() {
                    configs.calendarShowController.write(value);
                  });
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.visibility),
                title: const Text("显示视图标题"),
                subtitle: const Text("View Header"),
                value: configs.calendarShowViewHeader.getOr(true),
                onChanged: (value) {
                  setState(() {
                    configs.calendarShowViewHeader.write(value);
                  });
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.visibility),
                title: const Text("显示全天日程"),
                subtitle: const Text("View Header"),
                value: configs.calendarShowAlldayAppionments.getOr(true),
                onChanged: (value) {
                  setState(() {
                    configs.calendarShowAlldayAppionments.write(value);
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.opacity),
                title: const Text("日程透明度"),
                subtitle: const Text("Appionment Opacity"),
                trailing: Text(
                    "${(configs.calendarCellOpacity.getOr(1) * 100).ceil()}%"),
                onTap: () {
                  inputOpacity((configs.calendarCellOpacity.getOr(1) * 100)
                          .ceil()
                          .toString())
                      .then((opacity) {
                    if (opacity != null) {
                      setState(() {
                        configs.calendarCellOpacity.write(opacity / 100);
                      });
                    }
                  });
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.image),
                title: const Text("背景图片"),
                subtitle: const Text("Background Image"),
                value: configs.calendarBackgroundImage.has(),
                onChanged: (value) async {
                  if (value) {
                    var picker = ImagePicker();
                    final image =
                        await picker.pickImage(source: ImageSource.gallery);

                    if (image != null) {
                      var calendarDir =
                          await platCalendarDataDirectory.getValue();

                      var origin = configs.calendarBackgroundImage.tryGet();

                      if (origin != null) {
                        var from = calendarDir.subFile(origin);
                        if (await from.exists()) {
                          from.delete();
                        }
                      }
                      setState(() {
                        configs.calendarBackgroundImage.write(image.name);
                      });

                      await calendarDir
                          .subFile(image.name)
                          .writeAsBytes(await image.readAsBytes());
                    }
                  } else {
                    var calendarDir =
                        await platCalendarDataDirectory.getValue();

                    var origin = configs.calendarBackgroundImage.tryGet();

                    if (origin != null) {
                      var from = calendarDir.subFile(origin);
                      if (await from.exists()) {
                        from.delete();
                      }
                    }
                    setState(() {
                      configs.calendarBackgroundImage.delete();
                    });
                  }

                  await calendarBackgroundData.update();
                },
              ),
              Visibility(
                visible: configs.calendarBackgroundImage.has(),
                child: SwitchListTile(
                  value: configs.calendarBackgroundImageIndependentColor
                      .getOr(false),
                  onChanged: (value) {
                    setState(() {
                      configs.calendarBackgroundImageIndependentColor
                          .write(value);
                    });
                  },
                  title: const Text("独立背景取色"),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.opacity),
                title: const Text("背景图片透明度"),
                subtitle: const Text("Background Opacity"),
                trailing: Text(
                    "${(configs.calendarBackgroundImageOpacity.getOr(0.30) * 100).ceil()}%"),
                onTap: () {
                  inputOpacity(
                          (configs.calendarBackgroundImageOpacity.getOr(0.30) *
                                  100)
                              .ceil()
                              .toString())
                      .then((opacity) {
                    if (opacity != null) {
                      setState(() {
                        configs.calendarBackgroundImageOpacity
                            .write(opacity / 100);
                      });
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.blur_linear),
                title: const Text("背景模糊"),
                subtitle: const Text("Background Blur"),
                trailing: Text(
                    "Sigma ${(configs.calendarBackgroundImageBlur.getOr(0))}"),
                onTap: () {
                  ComplexDialog.instance
                      .input(
                    context: context,
                    title: const Text("Sigma"),
                    controller: TextEditingController(
                        text: (configs.calendarBackgroundImageBlur.getOr(0))
                            .toString()),
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(),
                  )
                      .then((text) {
                    if (text != null && mounted) {
                      var value = double.tryParse(text);

                      if (value != null) {
                        setState(() {
                          configs.calendarBackgroundImageBlur.write((value));
                        });
                      } else {
                        showSnackBar(
                          context: this.context,
                          content: const Text("请输入数字"),
                        );
                      }
                    }
                  });
                },
              )
            ]),
          ],
        ),
      ),
    );
  }
}

class CalendarsManagerPage extends StatefulWidget {
  const CalendarsManagerPage({super.key});

  @override
  State<StatefulWidget> createState() => _CalendarsManagerPageState();
}

class _CalendarsManagerPageState extends State<CalendarsManagerPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("管理日历"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ["ics"],
          ).then((files) {
            if (files.isNotEmpty) {
              platCalendarDataDirectory.getValue().then((platdir) async {
                for (var single in files) {
                  var bytes = await single.readAsBytes();
                  platdir.subFile(single.name).writeAsBytesSync(bytes);
                  setState(() {});
                }
                await icalendarParsersData.update();
              });
            }
          });
        },
        child: const Icon(Icons.add),
      ),
      body: PaddingScrollView(
        child: FutureBuilder(
          future: Future(() async {
            var calendarDir = await platCalendarDataDirectory.getValue();
            return calendarDir.listSync();
          }),
          builder: (context, snapshot) {
            var data = snapshot.data;

            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }

            data.sort((a, b) => a.path.compareTo(b.path));

            return Column(
              children: data
                  .where((item) => extension(item.path) == ".ics")
                  .map(
                    (item) => Card.filled(
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        leading: const Icon(Icons.calendar_month),
                        title: Text(basenameWithoutExtension(item.path)),
                        onLongPress: () {
                          ComplexDialog.instance
                              .withContext(context: context)
                              .confirm(content: const Text("确认删除?"))
                              .then((result) {
                            if (result) {
                              File(item.absolute.path).delete().then((_) {
                                setState(() {});
                                icalendarParsersData.update();
                              });
                            }
                          });
                        },
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}
