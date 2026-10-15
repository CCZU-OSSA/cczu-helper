import 'package:material_ui/material_ui.dart';

/// 弹出滚轮时间选择器。取消返回 null。
/// [minuteStep] 决定分钟列的粒度（例如 30 → 只有 00/30；5 → 00/05/…/55）。
Future<TimeOfDay?> showTimeWheelPicker({
  required BuildContext context,
  required TimeOfDay initial,
  required int minuteStep,
}) {
  // 先把初始分钟按 minuteStep 对齐，保证弹窗里显示的就是当前生效的值。
  // 取最近的 minuteStep 倍数，再对 60 取模，处理 58 这类四舍五入到 60 的情况。
  final snapped = TimeOfDay(
    hour: initial.hour,
    minute: ((initial.minute / minuteStep).round() * minuteStep) % 60,
  );
  var picked = snapped;
  return showDialog<TimeOfDay>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text("选择时间"),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      content: TimeWheelPicker(
        initial: snapped,
        minuteStep: minuteStep,
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

/// 自建的时间滚轮选择器（小时列 + 分钟列）。
///
/// 这里刻意不再使用 CupertinoDatePicker：它内部把 CupertinoPicker 的
/// looping 写死为 true（见 cupertino_ui/lib/src/date_picker.dart:1043），
/// 没有任何参数可以关闭。滚轮一旦循环就无头无尾，观感很差，因此改为自建：
/// 小时列与分钟列都用有界的 `ListWheelScrollView` 滚轮（默认不循环），
/// 小时取 00~23；分钟按 [minuteStep] 步进
///（例如 30 → 只有 00/30；5 → 00/05/…/55）。
class TimeWheelPicker extends StatefulWidget {
  const TimeWheelPicker({
    super.key,
    required this.initial,
    required this.minuteStep,
    required this.onChanged,
  });

  /// 已按 [minuteStep] 对齐的初始时间。
  final TimeOfDay initial;

  /// 分钟列的步进，必须是 60 的约数。
  final int minuteStep;

  /// 选中值变化时回调，供 dialog 的「确定」按钮取最终结果。
  final ValueChanged<TimeOfDay> onChanged;

  @override
  State<TimeWheelPicker> createState() => _TimeWheelPickerState();
}

class _TimeWheelPickerState extends State<TimeWheelPicker> {
  /// 两列滚轮的行高。两边必须一致，选中带才能与它们等高对齐。
  static const double _itemExtent = 40;

  /// 内容区高度，正好 4 行，既容得下滚轮上下两行透视，又不会留下大片空白。
  static const double _contentHeight = 160;

  late int _hour;
  late int _minute;
  late final FixedExtentScrollController _hourController;

  /// 分钟滚轮控制器。与小时列一样在这里创建 / 释放，
  /// 避免 dialog 关闭动画期间被提前销毁。
  late final FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _hour = widget.initial.hour;
    // 取最近的 minuteStep 倍数；对 60 取模，避免 58 → 60 这类越界。
    _minute = ((widget.initial.minute / widget.minuteStep).round() *
            widget.minuteStep) %
        60;
    _hourController = FixedExtentScrollController(initialItem: _hour);
    _minuteController =
        FixedExtentScrollController(initialItem: _minute ~/ widget.minuteStep);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  /// 把当前选中的时间回传给外层 dialog。
  void _notify() {
    widget.onChanged(TimeOfDay(hour: _hour, minute: _minute));
  }

  /// 选中带样式：圆角 + 半透明主色。这里用于外层那条贯穿两列的横条，
  /// 颜色跟随主题、自动适配深浅色。
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

    // 选中带：一条贯穿左右两列的居中横条，模拟 iOS 的选中效果。
    final selectionBand = IgnorePointer(
      child: Container(
        height: _itemExtent,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: _bandDecoration(primary, 0.12),
      ),
    );

    return SizedBox(
      width: 240,
      height: _contentHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          selectionBand,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 小时列：整点滚轮，选中行停在正中间。
              SizedBox(
                width: 88,
                child: ListWheelScrollView.useDelegate(
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
              ),
              const SizedBox(width: 16),
              // 分钟列：与小时列同款的不循环滚轮。
              _buildMinuteWheel(theme, primary, textColor),
            ],
          ),
        ],
      ),
    );
  }

  /// 分钟列：与小时列同款的不循环滚轮，按 [TimeWheelPicker.minuteStep] 步进，
  /// 共 `60 ~/ minuteStep` 项（30 → 00/30 两项；5 → 00/05/…/55 十二项）。
  ///
  /// 列宽取 88 与小时列一致，保证两列左右对称；列内不画高亮带，
  /// 选中效果由外层那条贯穿横条负责。
  Widget _buildMinuteWheel(
    ThemeData theme,
    Color primary,
    Color? textColor,
  ) {
    final step = widget.minuteStep;
    return SizedBox(
      width: 88,
      child: ListWheelScrollView.useDelegate(
        controller: _minuteController,
        itemExtent: _itemExtent,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          setState(() => _minute = index * step);
          _notify();
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: 60 ~/ step,
          builder: (context, index) {
            final selected = index * step == _minute;
            return Center(
              child: Text(
                (index * step).toString().padLeft(2, "0"),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: selected ? primary : textColor,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
