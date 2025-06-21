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
import 'package:flutter/material.dart';
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
                trailing: Text(configs.calendarTimeStart
                    .getOr(const TimeOfDay(hour: 8, minute: 0))
                    .format(context)),
                onTap: () {
                  showTimePicker(
                          context: context,
                          initialTime: configs.calendarTimeStart
                              .getOr(const TimeOfDay(hour: 8, minute: 0)))
                      .then((time) {
                    if (time != null) {
                      setState(() {
                        configs.calendarTimeStart.write(time);
                      });
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.nightlife),
                title: const Text("日历结束时间"),
                subtitle: const Text("Calendar End"),
                trailing: Text(configs.calendarTimeEnd
                    .getOr(const TimeOfDay(hour: 21, minute: 0))
                    .format(context)),
                onTap: () {
                  showTimePicker(
                          context: context,
                          initialTime: configs.calendarTimeEnd
                              .getOr(const TimeOfDay(hour: 21, minute: 0)))
                      .then((time) {
                    if (time != null) {
                      debugPrint(time.toString());
                      setState(() {
                        configs.calendarTimeEnd.write(time);
                      });
                    }
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
                leading: const Icon(Icons.access_time_filled),
                title: const Text("时间间隔"),
                subtitle: const Text("Time Interval"),
                trailing:
                    Text("${configs.calendarTimeIntervalMinutes.getOr(30)}min"),
                onTap: () {
                  showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                              hour: 0,
                              minute: configs.calendarTimeIntervalMinutes
                                  .getOr(30)))
                      .then((data) {
                    if (data != null) {
                      setState(() {
                        configs.calendarTimeIntervalMinutes
                            .write(data.hour * 60 + data.minute);
                      });
                    }
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
                    picker
                        .pickImage(source: ImageSource.gallery)
                        .then((image) async {
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
                    });
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
                },
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
          FilePicker.platform
              .pickFiles(
            type: FileType.custom,
            allowedExtensions: ["ics"],
            withData: true,
          )
              .then((file) {
            if (file != null) {
              platCalendarDataDirectory.getValue().then((platdir) {
                for (var single in file.files) {
                  var bytes = single.bytes;
                  if (bytes != null) {
                    platdir.subFile(single.name).writeAsBytes(bytes).then((_) {
                      setState(() {});
                    });
                  }
                }
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
