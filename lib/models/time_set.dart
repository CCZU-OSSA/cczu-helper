/// 自定义时间标尺的数据载体。
///
/// [TimeSet] 收集一份日历（`.ics`）中所有事件的「起止时刻」，供后续阶段
/// 用一条由自定义列表驱动的横线标尺替换 syncfusion 库自带的标尺。
///
/// 单位约定：两个字段里的每个元素都是**从 0:00 起算的分钟数**，
/// 例如 8:45 记为 525，13:30 记为 810。
///
/// [ticks] 是所有「开始时刻」与「结束时刻」的**并集**（排序去重），绘制层画的
/// 就是这份并集；[endOnlyTicks] 则是其中**「纯粹的结束时刻」**（只作为某个事件的
/// 结束出现、且不作为任何事件的开始），供绘制层单独做像素级微调。
///
/// 为什么不做范围过滤：这里只负责「数据层」，把一份日历里出现过的所有时刻
/// 如实、完整地提取出来即可。像「只保留 08:00–21:00」这类裁剪属于**绘制层**
/// 的职责（用户可见的时间窗口由配置决定，见后续阶段），若在数据层提前裁剪，
/// 会让数据与视图耦合、难以复用，也会在配置变化时丢失原始信息。
class TimeSet {
  /// 所有起止时刻的并集（排序去重），绘制层画的就是这份。
  final List<int> ticks;

  /// 「纯粹的结束时刻」：只作为某个事件的结束出现、且不作为任何事件的开始。
  ///
  /// 之所以要单独分出来：SfCalendar 会把课块高度减 1 像素
  /// （见 appointment_layout.dart 里 `height > 1 ? height - 1 : 0`），
  /// 所以课块下沿比真实时间位置高 1px，绘制层需要把这部分线往上挪 1px 才能贴齐。
  /// 若某时刻同时是「开始」，它还得贴下一个课块的上沿，不能挪 —— 故只对纯结束时刻做位移。
  final List<int> endOnlyTicks;

  const TimeSet(this.ticks, this.endOnlyTicks);

  /// 由「开始时刻」和「结束时刻」两组分钟数构造。
  ///
  /// [ticks] 取两者的并集（排序去重），绘制层画的是这个并集；
  /// [endOnlyTicks] 只保留「结束里、且不在开始里」的那些。
  /// 不做任何范围过滤。
  factory TimeSet.fromStartsAndEnds(
    Iterable<int> starts,
    Iterable<int> ends,
  ) {
    final startSet = starts.toSet();
    final endSet = ends.toSet();
    return TimeSet(
      <int>{...startSet, ...endSet}.toList()..sort(),
      endSet.difference(startSet).toList()..sort(),
    );
  }

  /// 是否不含任何时刻。
  bool get isEmpty => ticks.isEmpty;

  @override
  String toString() {
    return ticks.map((tick) {
      final hour = tick ~/ 60;
      final minute = (tick % 60).toString().padLeft(2, "0");
      return "$hour:$minute";
    }).join(" ");
  }
}
