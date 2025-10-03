import 'dart:ui';

import 'package:arche/arche.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/controllers/platform.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:cczu_helper/models/translators.dart';
import 'package:cczu_helper/views/pages/account.dart';
import 'package:cczu_helper/views/pages/tutorial.dart';
import 'package:cczu_helper/views/services/common/icalendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:intl/intl.dart';
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
    ApplicationConfigs configs = ArcheBus().of();
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
  final DateTime firstCurriculumDate;

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
    final diff = details?.visibleDates.first
        .difference(widget.firstCurriculumDate)
        .inDays;
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
  Widget buildHeader(
    CalendarController controller,
    CalendarViewHeader viewHeader,
    Widget child,
  ) {
    final configs = ArcheBus.bus.of<ApplicationConfigs>();
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
    CalendarData appointment,
    ApplicationConfigs configs,
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
    CalendarData appointment,
    ApplicationConfigs configs,
    bool isWeekView,
  ) {
    final theme = Theme.of(context);
    final time =
        '${DateFormat('HH:mm', Localizations.localeOf(context).languageCode).format(appointment.start.toDateTime()!)} ~ ${DateFormat('HH:mm', Localizations.localeOf(context).languageCode).format(appointment.end.toDateTime()!)}';
    final (appointmentColor, locationColor, secondaryColor) =
        getAppointmentColor(appointment, configs);
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

  @override
  void initState() {
    calendarController = CalendarController();
    super.initState();
  }

  @override
  void dispose() {
    calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configs = ArcheBus().of<ApplicationConfigs>();
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
          refreshCalendar: () => setState(() {}),
        ),
      );
    }
    var view = configs.calendarView.getOr(CalendarView.week);

    if (view == CalendarView.workWeek) {
      view = CalendarView.week;
    }
    final start =
        configs.calendarTimeStart.getOr(const TimeOfDay(hour: 8, minute: 0));
    final end =
        configs.calendarTimeEnd.getOr(const TimeOfDay(hour: 21, minute: 0));
    final GlobalKey<CalendarViewHeaderState> calendarViewHeaderKey =
        GlobalKey();

    var viewHeader = CalendarViewHeader(
      key: calendarViewHeaderKey,
      controller: calendarController,
      firstCurriculumDate: icalendarData
          .firstWhere((e) => e.source == CalendarSource.curriculum)
          .data
          .where((e) => e.isAllday && e.summary.startsWith("学期"))
          .map((e) => e.start.toDateTime()!)
          .reduce((a, b) {
        if (a.isBefore(b)) {
          return a;
        }
        return b;
      }),
    );

    final calendar = SfCalendar(
      key: ValueKey(icalendarData),
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
        timeRulerSize: configs.calendarShowTimeRule.getOr(true) ? -1 : 0,
        timeIntervalHeight: 40,
        startHour: start.hour + start.minute / 60,
        endHour: end.hour + end.minute / 60,
        timeInterval: Duration(
          minutes: configs.calendarTimeIntervalMinutes.getOr(30),
        ),
      ),
      cellBorderColor: configs.calendarIntervalLine.getOr(true)
          ? theme.colorScheme.surfaceContainerHighest
          : Colors.transparent,
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
      appointmentBuilder: (context, calendarAppointmentDetails) {
        final isWeekView = calendarController.view == CalendarView.week;
        return Flex(
          direction: Axis.horizontal,
          children: calendarAppointmentDetails.appointments.map((appointment) {
            return Expanded(
              child: SizedBox(
                height: double.infinity,
                child: buildAppointment(appointment, configs, isWeekView),
              ),
            );
          }).toList(),
        );
      },
      dataSource: CurriculumDataSource(icalendarData.fold([], (data, parser) {
        if (configs.calendarShowAlldayAppionments.getOr(false)) {
          data.addAll(parser.data);
        } else {
          data.addAll(parser.data.where((e) => !e.isAllday));
        }
        return data;
      })),
    );
    var child = buildHeader(
      calendarController,
      viewHeader,
      calendar,
    );

    final blur = configs.calendarBackgroundImageBlur.getOr(0);

    return Stack(
      children: [
        RawImage(
          width: double.infinity,
          height: double.infinity,
          key: ObjectKey(calendarBackgroundData.value),
          image: calendarBackgroundData.value,
          fit: BoxFit.cover,
          opacity: AlwaysStoppedAnimation(
            configs.calendarBackgroundImageOpacity.getOr(0.3),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Padding(
            padding: isWideScreen(context)
                ? const EdgeInsets.only(left: 8)
                : EdgeInsets.zero,
            child: child,
          ),
        ),
      ],
    );
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
  ICalendarParser(String raw, this.source)
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
