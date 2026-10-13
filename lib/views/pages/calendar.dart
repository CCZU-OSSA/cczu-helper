import 'dart:collection';
import 'dart:ui';

import 'package:arche/arche.dart';
import 'package:arche/extensions/io.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/controllers/platform.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:cczu_helper/models/time_set.dart';
import 'package:cczu_helper/models/translators.dart';
import 'package:cczu_helper/views/pages/account.dart';
import 'package:cczu_helper/views/pages/tutorial.dart';
import 'package:cczu_helper/views/services/common/icalendar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/scheduler.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
// intl 也导出了一个同名的 TextDirection（只有 LTR/RTL），会遮蔽 dart:ui 的
// TextDirection.ltr，导致 TextPainter 拿不到正确枚举，这里显式隐藏掉。
import 'package:intl/intl.dart' hide TextDirection;
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:timezone/timezone.dart' as tz;

class CurriculumPage extends StatefulWidget {
  const CurriculumPage({super.key});

  @override
  State<StatefulWidget> createState() => CurriculumPageState();
}

class CalendarControllerHeader extends StatefulWidget {
  final CalendarController controller;
  final Function refresh;

  const CalendarControllerHeader(
      {super.key, required this.controller, required this.refresh});

  @override
  State<StatefulWidget> createState() => CalendarControllerHeaderState();
}

/// Cache the `displayDate` here
DateTime? _displayDate;

class CalendarControllerHeaderState extends State<CalendarControllerHeader> {
  CalendarController get controller => widget.controller;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      controller.addPropertyChangedListener(_listener);
    });
  }

  void _listener(String data) {
    // Store the cache
    if (data == "displayDate") {
      _displayDate = controller.displayDate;
    }

    setState(() {});
  }

  @override
  void dispose() {
    controller.removePropertyChangedListener(_listener);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var formatter = DateFormat.yMMM(
        Localizations.localeOf(viewKey.currentContext!).languageCode);
    var date = _displayDate ?? controller.displayDate ?? DateTime.now();
    final ApplicationConfigs configs = ArcheBus().of();
    var isWide = isWideScreen(context);
    var colorScheme = Theme.of(context).colorScheme;
    var arrow = Row(
      children: [
        IconButton(
          onPressed: () {
            controller.backward!();
          },
          icon: const Icon(Icons.arrow_left_rounded),
        ),
        IconButton(
          onPressed: () {
            controller.forward!();
          },
          icon: const Icon(Icons.arrow_right_rounded),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Visibility(
                  visible: isWide &&
                      (configs.calendarView.getOr(CalendarView.week) !=
                          CalendarView.schedule),
                  child: arrow),
              OutlinedButton(
                onPressed: () async {
                  var now = DateTime.now();
                  var date = await showDatePicker(
                      initialDate: controller.displayDate ?? now,
                      context: context,
                      firstDate: now.add(const Duration(days: -365)),
                      lastDate: now.add(const Duration(days: 365)));
                  if (date != null) {
                    controller.displayDate = date;
                  }
                },
                child: Text(
                  formatter.format(date),
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.today),
                onPressed: () {
                  controller.displayDate = DateTime.now();
                },
              ),
              PopupMenuButton(
                position: PopupMenuPosition.under,
                initialValue: configs.calendarView.getOr(CalendarView.week),
                icon: Icon(
                  Icons.view_comfortable,
                  color: colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) {
                  configs.calendarView.write(value);
                  controller.view = value;
                  widget.refresh();
                },
                itemBuilder: (context) => [
                  CalendarView.day,
                  CalendarView.week,
                  CalendarView.schedule,
                ]
                    .map((view) => PopupMenuItem(
                        value: view,
                        child:
                            Text(calendarViewTr.translation(view).toString())))
                    .toList(),
              ),
              Visibility(
                visible: !isWide &&
                    configs.calendarView.getOr(CalendarView.week) !=
                        CalendarView.schedule,
                child: arrow,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CalendarViewHeader extends StatefulWidget {
  final DateTime? firstCurriculumDate;

  final CalendarController controller;
  const CalendarViewHeader({
    super.key,
    required this.controller,
    required this.firstCurriculumDate,
  });

  @override
  State<StatefulWidget> createState() => CalendarViewHeaderState();
}

ViewChangedDetails? _details;

class CalendarViewHeaderState extends State<CalendarViewHeader> {
  ViewChangedDetails? get details => _details;
  set details(ViewChangedDetails? rhs) => _details = rhs;

  void updateWithViewChangedDetails(ViewChangedDetails details) {
    if (details.visibleDates.isEmpty) {
      return;
    }
    this.details = details;

    try {
      setState(() {});
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    }
  }

  bool compareDateTime(DateTime a, DateTime b) {
    return a.day == b.day && a.month == b.month && a.year == b.year;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final formatter =
        DateFormat('EEE', Localizations.localeOf(context).languageCode);
    final theme = Theme.of(context);
    final configs = ArcheBus.bus.of<ApplicationConfigs>();
    int? diff;
    if (widget.firstCurriculumDate != null) {
      diff = details?.visibleDates.first
          .difference(widget.firstCurriculumDate!)
          .inDays;
    }

    return Visibility(
      visible: widget.controller.view == CalendarView.week,
      child: SizedBox(
        height: 45,
        child: Row(
          key: ValueKey(details?.visibleDates),
          children: [
            Visibility(
              visible: configs.calendarShowTimeRule.getOr(true),
              child: SizedBox(
                width: 50,
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: ShapeDecoration(
                    shape: CircleBorder(),
                    color: theme.colorScheme.primary,
                  ),
                  child: Center(
                    child: diff == null || diff < 0 || diff ~/ 7 >= 19
                        ? Text(
                            "N/A",
                            style:
                                TextStyle(color: theme.colorScheme.onPrimary),
                          )
                        : Text(
                            ((diff ~/ 7) + 1).toString(),
                            style:
                                TextStyle(color: theme.colorScheme.onPrimary),
                          ),
                  ),
                ),
              ),
            ),
            if (details != null)
              ...details!.visibleDates.map((date) {
                final isSame = compareDateTime(date, today);
                return Expanded(
                  child: Center(
                      child: Column(
                    children: [
                      Text(
                        formatter.format(date),
                        style: isSame
                            ? TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              )
                            : TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface),
                      ),
                      Text(
                        date.day.toString(),
                        style: isSame
                            ? TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                                fontStyle: FontStyle.italic)
                            : TextStyle(color: theme.colorScheme.onSurface),
                      )
                    ],
                  )),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class CurriculumPageState extends State<CurriculumPage>
    with RefreshMountedStateMixin {
  late CalendarController calendarController;
  late final ApplicationConfigs configs;
  late final Widget Function(BuildContext, CalendarAppointmentDetails)
      _appointmentBuilderFn;

  Widget buildHeader(
    CalendarController controller,
    CalendarViewHeader viewHeader,
    Widget child,
  ) {
    final showController = configs.calendarShowController.getOr(true);
    final showViewHeader = configs.calendarShowViewHeader.getOr(true);

    if (!showViewHeader && !showController) {
      return SafeArea(bottom: false, child: child);
    } else if (showViewHeader && !showController) {
      return Column(
        children: [
          SafeArea(bottom: false, child: viewHeader),
          Expanded(child: child)
        ],
      );
    } else if (!showViewHeader && showController) {
      return Column(
        children: [
          SafeArea(
            bottom: false,
            child: CalendarControllerHeader(
              controller: controller,
              refresh: refreshMounted,
            ),
          ),
          Expanded(child: child)
        ],
      );
    } else {
      return Column(
        children: [
          SafeArea(
            bottom: false,
            child: CalendarControllerHeader(
              controller: controller,
              refresh: refreshMounted,
            ),
          ),
          viewHeader,
          Expanded(child: child)
        ],
      );
    }
  }

  (Color appointment, Color? location, Color? secoundary) getAppointmentColor(
    BuildContext context,
    CalendarData appointment,
  ) {
    final theme = Theme.of(context);
    if (appointment.isAllday) {
      return (
        theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: configs.calendarCellOpacity.getOr(1)),
        theme.colorScheme.primary,
        theme.colorScheme.secondary,
      );
    }

    if (configs.calendarColorful.getOr(false)) {
      final hue = (appointment.summary.hashCode % 360).toDouble();
      final isDark = theme.brightness == Brightness.dark;
      return (
        HSVColor.fromAHSV(
          configs.calendarCellOpacity.getOr(1),
          hue,
          isDark ? 0.6 : 0.2,
          isDark ? 0.7 : 1,
        ).toColor(),
        HSVColor.fromAHSV(
          1,
          hue,
          isDark ? 0.5 : 0.8,
          isDark ? 1 : 0.6,
        ).toColor(),
        HSVColor.fromAHSV(
          1,
          hue,
          isDark ? 0.2 : 0.4,
          isDark ? 1 : 0.6,
        ).toColor(),
      );
    }

    return (
      theme.colorScheme.primaryContainer
          .withValues(alpha: configs.calendarCellOpacity.getOr(1)),
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
    );
  }

  Widget buildAppointment(
    BuildContext context,
    CalendarData appointment,
    bool isWeekView,
  ) {
    final theme = Theme.of(context);
    final time =
        '${DateFormat('HH:mm', Localizations.localeOf(context).languageCode).format(appointment.start.toDateTime()!)} ~ ${DateFormat('HH:mm', Localizations.localeOf(context).languageCode).format(appointment.end.toDateTime()!)}';
    final (appointmentColor, locationColor, secondaryColor) =
        getAppointmentColor(context, appointment);
    return GestureDetector(
      onTap: appointment.isAllday
          ? null
          : () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 16, left: 16, right: 16),
                      child: Text(
                        appointment.summary,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.access_time_filled),
                            title: const Text("时间"),
                            subtitle: SelectableText(
                              time,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.location_on),
                            title: const Text("地点"),
                            subtitle: SelectableText(
                              appointment.location.toString(),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          Visibility(
                            visible: appointment.description != null,
                            child: ListTile(
                              leading: appointment.source ==
                                      CalendarSource.curriculum
                                  ? const Icon(Icons.person)
                                  : const Icon(Icons.description),
                              title: appointment.source ==
                                      CalendarSource.curriculum
                                  ? const Text("教师")
                                  : const Text("简述"),
                              subtitle: SelectableText(
                                appointment.source == CalendarSource.curriculum
                                    ? appointment.description
                                        .toString()
                                        .replaceAll("\\;", ",")
                                        .split(",")
                                        .where((test) => test.isNotEmpty)
                                        .join(",")
                                    : appointment.description.toString(),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: appointment.week != null,
                            child: ListTile(
                              leading: const Icon(Icons.calendar_month),
                              title: const Text("工作周"),
                              subtitle: SelectableText(
                                appointment.week.toString(),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: appointmentColor,
        ),
        child: appointment.isAllday
            ? Center(
                child: Text(
                  appointment.summary,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(2),
                child: isWeekView
                    ? Text.rich(
                        TextSpan(
                          text: "${appointment.summary}\n",
                          style: const TextStyle(fontSize: 12),
                          children: [
                            TextSpan(
                              text: appointment.location,
                              style: TextStyle(
                                fontSize: 10,
                                color: locationColor,
                              ),
                            )
                          ],
                        ),
                        overflow: TextOverflow.fade,
                      )
                    : Padding(
                        padding: const EdgeInsets.all(2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    appointment.summary,
                                    overflow: TextOverflow.fade,
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    time,
                                    overflow: TextOverflow.fade,
                                    style: TextStyle(
                                      color: secondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              appointment.location.toString(),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: locationColor,
                              ),
                            )
                          ],
                        ),
                      ),
              ),
      ),
    );
  }

  CurriculumDataSource? _datasource;
  DateTime? _firstCurriculumDate;
  Map<String, TimeSet> _timeSets = {};
  @override
  void initState() {
    configs = ArcheBus().of<ApplicationConfigs>();
    calendarController = CalendarController();
    _appointmentBuilderFn =
        (BuildContext context, CalendarAppointmentDetails details) {
      final isWeekView = calendarController.view == CalendarView.week;
      return Flex(
        direction: Axis.horizontal,
        children: details.appointments.map((appointment) {
          return Expanded(
            child: SizedBox(
              height: double.infinity,
              child: buildAppointment(context, appointment, isWeekView),
            ),
          );
        }).toList(),
      );
    };

    computeDatasource();
    super.initState();
  }

  void computeDatasource() {
    refreshMounted(() {
      final icalendarData = icalendarParsersData.value;
      _datasource = icalendarData == null
          ? null
          : CurriculumDataSource(icalendarData.fold([], (data, parser) {
              if (configs.calendarShowAlldayAppionments.getOr(false)) {
                data.addAll(parser.data);
              } else {
                data.addAll(parser.data.where((e) => !e.isAllday));
              }
              return data;
            }));
      _firstCurriculumDate = icalendarData
          ?.where((e) => e.source == CalendarSource.curriculum)
          .firstOrNull
          ?.data
          .where((e) => e.isAllday && e.summary.startsWith("学期"))
          .map((e) => e.start.toDateTime()!)
          .reduce((a, b) {
        if (a.isBefore(b)) {
          return a;
        }
        return b;
      });
      _timeSets = {};
      if (icalendarData != null) {
        for (final parser in icalendarData) {
          final spans = _extractTicks(parser.data);
          _timeSets[parser.fileName] =
              TimeSet.fromStartsAndEnds(spans.starts, spans.ends);
        }
      }
    });
  }

  @override
  void dispose() {
    calendarController.dispose();
    super.dispose();
  }

  Widget wrapWithBackdropFilter(Widget child) {
    final blur = configs.calendarBackgroundImageBlur.getOr(0);

    if (blur == 0) {
      return child;
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: child,
    );
  }

  Widget buildCalendar(BuildContext context) {
    final theme = Theme.of(context);
    final icalendarData = icalendarParsersData.value;

    if (icalendarData == null) {
      return Center(
        child: Text("日历数据加载失败"),
      );
    }

    if (icalendarData.isEmpty) {
      return Align(
        alignment: Alignment.topCenter,
        child: GenerateCalendarGuide(
          refreshCalendar: () => computeDatasource(),
        ),
      );
    }
    var view = configs.calendarView.getOr(CalendarView.week);

    if (view == CalendarView.workWeek) {
      view = CalendarView.week;
    }
    final start = snapToHalfHour(
        configs.calendarTimeStart.getOr(const TimeOfDay(hour: 8, minute: 0)));
    final end = snapToHalfHour(
        configs.calendarTimeEnd.getOr(const TimeOfDay(hour: 21, minute: 0)));
    final GlobalKey<CalendarViewHeaderState> calendarViewHeaderKey =
        GlobalKey();

    var viewHeader = CalendarViewHeader(
      key: calendarViewHeaderKey,
      controller: calendarController,
      firstCurriculumDate: _firstCurriculumDate,
    );

    final calendar = SfCalendar(
      showWeekNumber: configs.calendarShowTimeRule.getOr(true),
      weekNumberStyle: WeekNumberStyle(
        backgroundColor: Colors.transparent,
      ),
      viewHeaderHeight: 0,
      backgroundColor: Colors.transparent,
      controller: calendarController,
      initialDisplayDate: _displayDate,
      view: view,
      todayTextStyle: TextStyle(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
      ),
      firstDayOfWeek: 1,
      headerHeight: 0,
      timeSlotViewSettings: TimeSlotViewSettings(
        timeFormat: "H:mm",
        // 隐藏库自带的标尺文字，但保留 50px 的标尺列（自绘层要用这个宽度）。
        // 不能用 timeRulerSize: 0 代替 —— 那会让整列消失、日列左移，
        // 自绘的标尺会压住周一那一列。
        timeTextStyle: const TextStyle(color: Colors.transparent),
        timeRulerSize: configs.calendarShowTimeRule.getOr(true) ? 50 : 0,
        timeIntervalHeight: 40,
        startHour: start.hour + start.minute / 60,
        endHour: end.hour + end.minute / 60,
        timeInterval: const Duration(minutes: 30),
      ),
      // 去掉库自带的 30 分钟密线；横线改由 TimeSet 驱动（第 6 阶段自绘）。
      // 注意：天分隔竖线共用这个颜色，会一并消失，第 6 阶段由自绘层补回。
      cellBorderColor: Colors.transparent,
      cellEndPadding: 0,
      selectionDecoration: BoxDecoration(),
      scheduleViewSettings: ScheduleViewSettings(
        hideEmptyScheduleWeek: true,
        monthHeaderSettings:
            MonthHeaderSettings(backgroundColor: theme.colorScheme.primary),
      ),
      onViewChanged: (viewChangedDetails) {
        if (calendarController.view == CalendarView.week) {
          calendarViewHeaderKey.currentState
              ?.updateWithViewChangedDetails(viewChangedDetails);
        }
      },
      appointmentBuilder: _appointmentBuilderFn,
      dataSource: _datasource,
    );
    // 在 SfCalendar 之上叠一层自绘标尺。
    // 用 StackFit.passthrough：让 calendar 拿到的约束与之前完全一样，
    // 不改变它原有的尺寸行为。
    // 只有时间槽类视图（周 / 日）才有时间网格，日程（schedule）是列表视图，
    // 叠上去只会把横线画到列表上。workWeek 在上面已经被映射成 week 了。
    final showsTimeGrid =
        view == CalendarView.week || view == CalendarView.day;

    final calendarWithRuler = Stack(
      fit: StackFit.passthrough,
      children: [
        calendar,
        if (showsTimeGrid)
          Positioned.fill(
            // IgnorePointer 不能省：自绘层铺满整个课表，
            // 否则会把点击和滚动手势全部吃掉。
            child: IgnorePointer(
              child: CustomPaint(
                painter: _TimeSetRulerPainter(
                  timeSets: _timeSets.values.toList(),
                  startMinutes: start.hour * 60 + start.minute,
                  endMinutes: end.hour * 60 + end.minute,
                  rulerWidth:
                      configs.calendarShowTimeRule.getOr(true) ? 50 : 0,
                  lineColor: theme.colorScheme.outlineVariant,
                  // 全天日程面板展开时会把下面的时间槽整体下推，线要跟着下移。
                  headerOffset:
                      configs.calendarShowAlldayAppionments.getOr(false)
                          ? _kAllDayPanelHeight
                          : 0,
                  dayCount: view == CalendarView.week ? 7 : 1,
                  textStyle: theme.textTheme.bodySmall!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    var child = buildHeader(
      calendarController,
      viewHeader,
      calendarWithRuler,
    );
    final isGif =
        configs.calendarBackgroundImage.tryGet()?.endsWith(".gif") ?? false;

    if (isGif) {
      return wrapWithBackdropFilter(
        Padding(
          padding: isWideScreen(context)
              ? const EdgeInsets.only(left: 8)
              : EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: FileImage(platCalendarDataDirectory.value!
                    .subFile(configs.calendarBackgroundImage.get())),
                fit: BoxFit.cover,
                opacity: configs.calendarBackgroundImageOpacity.getOr(0.3),
              ),
            ),
            child: child,
          ),
        ),
      );
    }

    return Stack(
      children: [
        RepaintBoundary(
          child: RawImage(
            width: double.infinity,
            height: double.infinity,
            key: ObjectKey(calendarBackgroundData.value),
            image: calendarBackgroundData.value,
            fit: BoxFit.cover,
            opacity: AlwaysStoppedAnimation(
              configs.calendarBackgroundImageOpacity.getOr(0.3),
            ),
          ),
        ),
        wrapWithBackdropFilter(
          Padding(
            padding: isWideScreen(context)
                ? const EdgeInsets.only(left: 8)
                : EdgeInsets.zero,
            child: child,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final useIndenpendentColor =
        configs.calendarBackgroundImageIndependentColor.getOr(false) &&
            configs.calendarBackgroundImage.has();

    if (useIndenpendentColor) {
      final computedColorScheme = ColorScheme.fromImageProvider(
          brightness: Theme.of(context).brightness,
          provider: FileImage(platCalendarDataDirectory.value!
              .subFile(configs.calendarBackgroundImage.get())));
      return FutureBuilder(
        future: computedColorScheme,
        builder: (context, snapshot) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: snapshot.data ?? Theme.of(context).colorScheme,
            ),
            child: Builder(builder: (context) => buildCalendar(context)),
          );
        },
      );
    }
    return buildCalendar(context);
  }
}

class GenerateCalendarGuide extends StatefulWidget {
  final Function() refreshCalendar;
  const GenerateCalendarGuide({super.key, required this.refreshCalendar});

  @override
  State<StatefulWidget> createState() => GenerateCalendarGuideState();
}

class GenerateCalendarGuideState extends State<GenerateCalendarGuide> {
  late int currentStep;
  @override
  void initState() {
    currentStep = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      Step(
          title: Text("填写账户"),
          isActive: currentStep >= 0,
          content: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                    onPressed: () {
                      pushMaterialRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(),
                          body: const TutorialPage(
                            showFAB: false,
                          ),
                        ),
                      );
                    },
                    child: const Text("查看账户指南")),
              ),
              SizedBox(
                height: 8,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: () {
                    pushMaterialRoute(
                      builder: (context) => const AccountManagePage(),
                    );
                  },
                  child: const Text("打开账户管理"),
                ),
              )
            ],
          )),
      Step(
        title: Text("生成课表"),
        isActive: currentStep >= 1,
        content: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                  onPressed: () {
                    pushMaterialRoute(
                      builder: (context) => const ICalendarServicePage(),
                    ).then((_) => widget.refreshCalendar());
                  },
                  child: const Text("打开课表生成")),
            )
          ],
        ),
      ),
    ];
    return Stepper(
      currentStep: currentStep,
      steps: steps,
      onStepTapped: (value) => setState(() {
        currentStep = value;
      }),
      onStepContinue: currentStep < steps.length - 1
          ? () {
              setState(() {
                currentStep += 1;
              });
            }
          : null,
      onStepCancel: currentStep > 0
          ? () {
              setState(() {
                currentStep -= 1;
              });
            }
          : null,
    );
  }
}

class CurriculumDataSource extends CalendarDataSource {
  CurriculumDataSource(List<CalendarData> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return (appointments![index] as CalendarData).start.toDateTime()!;
  }

  @override
  DateTime getEndTime(int index) {
    if (isAllDay(index)) {
      return (appointments![index] as CalendarData)
          .end
          .toDateTime()!
          .add(const Duration(days: -1));
    }

    return (appointments![index] as CalendarData).end.toDateTime()!;
  }

  @override
  bool isAllDay(int index) {
    return (appointments![index] as CalendarData).isAllday;
  }
}

enum CalendarSource { curriculum, other }

@immutable
class CalendarData {
  final CalendarSource source;
  final String? location;
  final String summary;
  final String? description;
  final String? week;
  final IcsDateTime start;
  final IcsDateTime end;
  final bool isAllday;
  const CalendarData({
    required this.location,
    required this.summary,
    required this.start,
    required this.end,
    this.description,
    this.week,
    this.isAllday = false,
    this.source = CalendarSource.other,
  });

  @override
  String toString() {
    return "CalendarData { summary: $summary, location: $location, dtstart: $start}";
  }
}

class ICalendarParser {
  final ICalendar calendar;
  final CalendarSource source;
  final String fileName;
  ICalendarParser(String raw, this.source, this.fileName)
      : calendar = ICalendarParser.parse(raw);

  static ICalendar parse(String source) {
    return ICalendar.fromString(source);
  }

  static IcsDateTime localize(IcsDateTime icstime) {
    if (!icstime.dt.endsWith("Z")) {
      return icstime;
    }

    var convert =
        (tz.TZDateTime.parse(tz.getLocation("Asia/Shanghai"), icstime.dt));
    return IcsDateTime(
        dt: "${convert.year}${convert.month.toString().padLeft(2, "0")}${convert.day.toString().padLeft(2, "0")}T${convert.hour.toString().padLeft(2, "0")}${convert.minute.toString().padLeft(2, "0")}");
  }

  List<CalendarData> get data {
    return calendar.data
        .where((element) => element["type"] == "VEVENT")
        .map((e) {
      return CalendarData(
        location: e["location"].toString(),
        summary: e["summary"].toString(),
        start: localize(e["dtstart"]),
        description: e["description"],
        end: localize(e["dtend"]),
        week: e["week"],
        isAllday: e["location"] == null,
        source: source,
      );
    }).toList();
  }
}

/// 提取一组事件的起止时刻（从 0:00 起算的分钟数），分「开始」「结束」两组返回。
///
/// 之所以不合并成一组：调用方需要知道某个时刻是纯结束还是同时是开始，
/// 纯结束的线要做像素级微调（见 [TimeSet.endOnlyTicks]）。
///
/// 全天事件没有具体时刻，直接跳过；不受 `calendarShowAlldayAppionments` 影响。
({List<int> starts, List<int> ends}) _extractTicks(List<CalendarData> events) {
  final starts = <int>[];
  final ends = <int>[];
  for (final e in events) {
    if (e.isAllday) {
      continue;
    }
    final start = e.start.toDateTime();
    final end = e.end.toDateTime();
    if (start != null) {
      starts.add(start.hour * 60 + start.minute);
    }
    if (end != null) {
      ends.add(end.hour * 60 + end.minute);
    }
  }
  return (starts: starts, ends: ends);
}

/// 全天日程面板展开时占掉的高度（像素）。
///
/// 来源：SfCalendar 内部 `_allDayPanelHeight = maxPosition * kAllDayAppointmentHeight`
/// （见 sfcalendar.dart），其中 kAllDayAppointmentHeight 固定为 20。
/// 当前数据下并排层数为 1，故为 20。
/// 若以后同一天有多条**并排**的全天日程，这里要相应调成 40 / 60（库的上限是 60）。
const double _kAllDayPanelHeight = 20;

/// 由 TimeSet 驱动的标尺横线绘制层。
///
/// 坐标换算必须与 SfCalendar 内部保持一致：
///   minuteHeight = timeIntervalHeight / intervalMinutes = 40 / 30
///   y = (分钟数 − startMinutes) × minuteHeight
/// 只要这个比例和库一致，画出来的线就会精确落在课块的上下边界上。
class _TimeSetRulerPainter extends CustomPainter {
  const _TimeSetRulerPainter({
    required this.timeSets,
    required this.startMinutes,
    required this.endMinutes,
    required this.rulerWidth,
    required this.lineColor,
    required this.headerOffset,
    required this.dayCount,
    required this.textStyle,
  });

  /// 每份日历一份刻度（列表间不去重，重合的线会叠着画）。
  final List<TimeSet> timeSets;

  /// 可见时间窗口，单位是「从 0:00 起算的分钟数」。
  final int startMinutes;
  final int endMinutes;

  /// 标尺列宽度：线从这里开始向右画到屏幕最右。
  final double rulerWidth;

  final Color lineColor;

  /// 每像素对应多少分钟高度。40 / 30，与 SfCalendar 的换算完全一致。
  static const double _minuteHeight = 40 / 30;

  /// 自绘层的纵向偏移（像素），由调用方按「全天日程面板是否展开」决定。
  /// 正数 = 所有线整体往下移。取值见 [_kAllDayPanelHeight]。
  final double headerOffset;

  /// 时间网格要切成几列（周 = 7，日 = 1），用于画天与天之间的竖线。
  final int dayCount;

  /// 标尺时间文字的样式，由调用方从 Theme 取。
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final timeSet in timeSets) {
      for (final tick in timeSet.ticks) {
        // 窗口外的时刻不画
        if (tick < startMinutes || tick > endMinutes) {
          continue;
        }
        // 纯结束时刻的线往上移 1px：SfCalendar 会把课块高度减 1 像素
        // （appointment_layout.dart 里 `height > 1 ? height - 1 : 0`），
        // 所以课块下沿比真实时间位置高 1px，线跟着上移才能贴齐下沿。
        // 开始时刻不能移 —— 它要贴的是下一个课块的上沿。
        final y = (tick - startMinutes) * _minuteHeight +
            headerOffset -
            (timeSet.endOnlyTicks.contains(tick) ? 1 : 0);
        canvas.drawLine(
          Offset(rulerWidth, y),
          Offset(size.width, y),
          paint,
        );
      }
    }

    // 天与天之间的竖线。日视图 dayCount = 1，循环不执行，自然没有竖线。
    final double cellWidth = (size.width - rulerWidth) / dayCount;
    for (int i = 1; i < dayCount; i++) {
      final double x = rulerWidth + cellWidth * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // 标尺时间文字：右对齐到标尺列，与对应时刻的横线垂直居中。
    // rulerWidth 为 0（总开关关掉）时不画，避免文字跑到画面外。
    if (rulerWidth > 0) {
      // 多个日历可能有相同时刻，文字只画一遍即可（横线那边仍按"重合着画"处理）
      final List<int> labels = <int>{
        for (final timeSet in timeSets) ...timeSet.ticks,
      }.toList()
        ..sort();

      final TextPainter textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      );

      for (final int tick in labels) {
        // 窗口外的时刻不画
        if (tick < startMinutes || tick > endMinutes) {
          continue;
        }
        // 文字标的是「时间点」，所以用不加那 1px 修正的纯位置
        final double lineY =
            (tick - startMinutes) * _minuteHeight + headerOffset;
        textPainter.text = TextSpan(
          text: "${tick ~/ 60}:${(tick % 60).toString().padLeft(2, "0")}",
          style: textStyle,
        );
        textPainter.layout();
        // 顶部/底部那条线的文字若严格居中会被裁掉一半，这里夹住让它完整显示
        final double dy = (lineY - textPainter.height / 2)
            .clamp(0.0, size.height - textPainter.height);
        textPainter.paint(
          canvas,
          Offset(rulerWidth - 4 - textPainter.width, dy),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TimeSetRulerPainter oldDelegate) {
    return oldDelegate.timeSets != timeSets ||
        oldDelegate.startMinutes != startMinutes ||
        oldDelegate.endMinutes != endMinutes ||
        oldDelegate.rulerWidth != rulerWidth ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.headerOffset != headerOffset ||
        oldDelegate.dayCount != dayCount ||
        oldDelegate.textStyle != textStyle;
  }
}
