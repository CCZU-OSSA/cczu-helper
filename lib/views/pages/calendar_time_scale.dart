import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/snackbar.dart';
import 'package:cczu_helper/views/widgets/time_wheel_picker.dart';
import 'package:material_ui/material_ui.dart';

/// 「时间刻度设置」页：管理用户手动添加的时间刻度。
///
/// 每条刻度按 HHMM 整数存在配置里（如 845 表示 8:45），与导入的 ics 无关，
/// 会一并参与课表标尺的绘制（见 calendar.dart 里构建 `_TimeSetRulerPainter` 处）。
class CalendarTimeScalePage extends StatefulWidget {
  const CalendarTimeScalePage({super.key});

  @override
  State<CalendarTimeScalePage> createState() => _CalendarTimeScalePageState();
}

class _CalendarTimeScalePageState extends State<CalendarTimeScalePage> {
  ApplicationConfigs get _configs => ArcheBus().of<ApplicationConfigs>();

  /// HHMM → 从 0:00 起算的分钟数（如 845 → 525）。
  static int _toMinutes(int hhmm) => (hhmm ~/ 100) * 60 + (hhmm % 100);

  /// 把 HHMM 整数格式化成 `H:mm`（小时不补零、分钟补两位）。
  static String _format(int hhmm) =>
      "${hhmm ~/ 100}:${(hhmm % 100).toString().padLeft(2, "0")}";

  /// 读取所有刻度（HHMM 整数），按时间升序返回。
  List<int> _readTicks() {
    return _configs.calendarTimeSetUser
        .getOr(<dynamic>[])
        .map((e) => (e as int))
        .toList()
      ..sort((a, b) => _toMinutes(a).compareTo(_toMinutes(b)));
  }

  /// 写回整个列表，并刷新界面。
  void _write(List<int> ticks) {
    _configs.calendarTimeSetUser.write(ticks);
    setState(() {});
  }

  /// 新增一条刻度。已存在的时刻不重复添加，只给一句提示。
  Future<void> _add() async {
    final time = await showTimeWheelPicker(
      context: context,
      initial: const TimeOfDay(hour: 8, minute: 0),
      minuteStep: 5,
    );
    if (time == null) {
      return;
    }
    // 跨过了 async gap：先确认 State 还在，否则下面的 showSnackBar 与
    // _write() 里的 setState 会在已卸载的页面执行。
    if (!mounted) {
      return;
    }
    final value = time.hour * 100 + time.minute;
    final ticks = _readTicks();
    if (ticks.contains(value)) {
      // 静默跳过会让用户以为程序卡了，所以给一句提示
      showSnackBar(context: context, content: const Text("该刻度已存在"));
      return;
    }
    ticks.add(value);
    _write(ticks);
  }

  /// 修改某条刻度（点击触发）。
  Future<void> _edit(int origin) async {
    final minutes = _toMinutes(origin);
    final time = await showTimeWheelPicker(
      context: context,
      initial: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      minuteStep: 5,
    );
    if (time == null) {
      return;
    }
    final ticks = _readTicks();
    final index = ticks.indexOf(origin);
    if (index < 0) {
      return;
    }
    ticks[index] = time.hour * 100 + time.minute;
    _write(ticks);
  }

  /// 删除某条刻度（长按触发）。
  Future<void> _delete(int value) async {
    final result = await ComplexDialog.instance
        .withContext(context: context)
        .confirm(content: const Text("确认删除?"));
    if (!result) {
      return;
    }
    final ticks = _readTicks()..remove(value);
    _write(ticks);
  }

  @override
  Widget build(BuildContext context) {
    final ticks = _readTicks();
    return Scaffold(
      appBar: AppBar(
        title: const Text("时间刻度设置"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: ticks.isEmpty
          ? const Center(child: Text("还没有自定义刻度，点右下角 + 添加"))
          : ListView(
              children: ticks
                  .map(
                    (value) => Card.filled(
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        leading: const Icon(Icons.timeline),
                        title: Text(_format(value)),
                        onTap: () => _edit(value),
                        onLongPress: () => _delete(value),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
