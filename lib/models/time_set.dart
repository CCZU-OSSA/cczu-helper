/// 自定义时间标尺的数据载体。
///
/// [TimeSet] 收集一份日历（`.ics`）中所有事件的「起止时刻」，供后续阶段
/// 用一条由自定义列表驱动的横线标尺替换 syncfusion 库自带的标尺。
///
/// 单位约定：[ticks] 中每个元素都是**从 0:00 起算的分钟数**，
/// 例如 8:45 记为 525，13:30 记为 810。
///
/// 为什么不做范围过滤：这里只负责「数据层」，把一份日历里出现过的所有时刻
/// 如实、完整地提取出来即可。像「只保留 08:00–21:00」这类裁剪属于**绘制层**
/// 的职责（用户可见的时间窗口由配置决定，见后续阶段），若在数据层提前裁剪，
/// 会让数据与视图耦合、难以复用，也会在配置变化时丢失原始信息。
class TimeSet {
  final List<int> ticks;

  const TimeSet(this.ticks);

  /// 由一组「从 0:00 起算的分钟数」构造 [TimeSet]，排序并去重后存入 [ticks]。
  ///
  /// 不做任何范围过滤。
  factory TimeSet.fromMinutes(Iterable<int> raw) {
    final ticks = raw.toSet().toList()..sort();
    return TimeSet(ticks);
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
