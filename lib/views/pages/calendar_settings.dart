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
  /// 这里刻意不再使用 CupertinoDatePicker：它内部把 CupertinoPicker 的
  /// looping 写死为 true（见 cupertino_ui/lib/src/date_picker.dart:1043），
  /// 没有任何参数可以关闭。既然分钟只能取 00/30 两个值，分钟列就会一直
  /// 30/00/30/00 地无限循环滚动，观感很差，因此改为自建选择器：
  /// 小时列用有界的 ListWheelScrollView 滚轮（默认不循环），分钟列改成
  /// 00/30 两个竖向排列、点击即切换的格子，天然不循环、不重复。
  ///
  /// 初始值仍先吸附到 :00/:30，保证弹窗里显示的就是当前生效的值。
  Future<TimeOfDay?> _showHourHalfPicker(TimeOfDay initial) {
    final snapped = snapToHalfHour(initial);
    var picked = snapped;
    return showDialog<TimeOfDay>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("选择时间"),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        content: _HourHalfPicker(
          initial: snapped,
          onChanged: (value) => picked = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("取消"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, picked),
            child: const Text("确定"),
          ),
        ],
      ),
    );
  }

  /// 检查所选时间范围是否切掉了某些课程时刻，若有则弹窗告知。
  ///
  /// 采取「发现即提示」：只要有一个非全天事件的起止时刻落在范围外，
  /// 就立刻弹窗并返回，不再统计具体数量。
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
            ComplexDialog.instance.text(
              context: context,
              content: const Text("有课程时间点超出当前时间范围，将不会完整显示"),
            );
            return;
          }
        }
      }
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

/// 自建的「整点/半点」选择器。
///
/// 小时列是 24 项的有界滚轮（ListWheelScrollView 默认不循环），
/// 分钟列是 00 / 30 两个直接点选的格子。滚动控制器在这里创建与释放，
/// 而不是在 `_showHourHalfPicker` 里用 whenComplete 释放 —— dialog 的
/// 关闭动画期间控制器若被提前销毁会抛异常。
class _HourHalfPicker extends StatefulWidget {
  const _HourHalfPicker({required this.initial, required this.onChanged});

  /// 已吸附到整点/半点的初始时间。
  final TimeOfDay initial;

  /// 选中值变化时回调，供 dialog 的「确定」按钮取最终结果。
  final ValueChanged<TimeOfDay> onChanged;

  @override
  State<_HourHalfPicker> createState() => _HourHalfPickerState();
}

class _HourHalfPickerState extends State<_HourHalfPicker> {
  /// 小时滚轮与分钟格子的行高，两边一致才能水平对齐、选中带等高。
  static const double _itemExtent = 40;

  /// 内容区高度，正好 4 行，既容得下滚轮上下两行透视，又不会留下大片空白。
  static const double _contentHeight = 160;

  late int _hour;
  late int _minute;
  late final FixedExtentScrollController _hourController;

  @override
  void initState() {
    super.initState();
    _hour = widget.initial.hour;
    _minute = widget.initial.minute == 30 ? 30 : 0;
    _hourController = FixedExtentScrollController(initialItem: _hour);
  }

  @override
  void dispose() {
    _hourController.dispose();
    super.dispose();
  }

  /// 把当前选中的整点/半点回传给外层 dialog。
  void _notify() {
    widget.onChanged(TimeOfDay(hour: _hour, minute: _minute));
  }

  /// 选中带样式：圆角 + 半透明主色。小时滚轮与分钟格子共用同一套，
  /// 保证两者的「选中带」观感统一，且颜色跟随主题、自动适配深浅色。
  static BoxDecoration _bandDecoration(Color primary, double alpha) {
    return BoxDecoration(
      color: primary.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final textColor = theme.textTheme.bodyLarge?.color;

    return SizedBox(
      width: 240,
      height: _contentHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 小时列：整点滚轮，选中行停在正中间。
          SizedBox(
            width: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 居中的选中带，用 IgnorePointer 包住以免挡住滚轮滑动。
                IgnorePointer(
                  child: Container(
                    height: _itemExtent,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: _bandDecoration(primary, 0.12),
                  ),
                ),
                ListWheelScrollView.useDelegate(
                  controller: _hourController,
                  itemExtent: _itemExtent,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() => _hour = index);
                    _notify();
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 24,
                    builder: (context, index) {
                      final selected = index == _hour;
                      return Center(
                        child: Text(
                          index.toString().padLeft(2, "0"),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: selected ? primary : textColor,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // 分钟列：只有 00 / 30 两个选项，竖向居中，点一下即切换。
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMinuteOption(theme, primary, textColor, 0),
              _buildMinuteOption(theme, primary, textColor, 30),
            ],
          ),
        ],
      ),
    );
  }

  /// 单个分钟格子：选中时加圆角半透明主色背景块 + 主色粗体文字。
  Widget _buildMinuteOption(
    ThemeData theme,
    Color primary,
    Color? textColor,
    int minute,
  ) {
    final selected = _minute == minute;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() => _minute = minute);
        _notify();
      },
      child: Container(
        width: 72,
        height: _itemExtent,
        alignment: Alignment.center,
        decoration: selected ? _bandDecoration(primary, 0.18) : null,
        child: Text(
          minute.toString().padLeft(2, "0"),
          style: theme.textTheme.titleMedium?.copyWith(
            color: selected ? primary : textColor,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
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
