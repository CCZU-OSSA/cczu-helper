import 'dart:io';
import 'dart:ui';

import 'package:arche/arche.dart';
import 'package:arche/extensions/io.dart';
import 'package:arche/extensions/iter.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/controllers/platform.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:cczu_helper/models/translators.dart';
import 'package:cczu_helper/views/services/common/icalendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' show basename, extension;
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:timezone/timezone.dart' as tz;

class CurriculumPage extends StatefulWidget {
  const CurriculumPage({super.key});

  @override
  State<StatefulWidget> createState() => CurriculumPageState();
}

class CalendarHeader extends StatefulWidget {
  final CalendarController controller;
  final Function refresh;

  const CalendarHeader(
      {super.key, required this.controller, required this.refresh});

  @override
  State<StatefulWidget> createState() => CalendarHeaderState();
}

/// Cache the `displayDate` here
DateTime? _displayDate;

class CalendarHeaderState extends State<CalendarHeader> {
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
              FilledButton(
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
                child: Text(formatter.format(date)),
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

class CurriculumPageState extends State<CurriculumPage>
    with RefreshMountedStateMixin {
  late CalendarController calendarController;

  Widget buildHeader(
    CalendarController controller,
    Widget child,
  ) {
    if (!ArcheBus.bus
        .of<ApplicationConfigs>()
        .calendarShowController
        .getOr(true)) {
      return SafeArea(bottom: false, child: child);
    }

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: CalendarHeader(
            controller: controller,
            refresh: refreshMounted,
          ),
        ),
        Expanded(child: child)
      ],
    );
  }

  (Color appointment, Color? location) getAppointmentColor(
    CalendarData appointment,
    ApplicationConfigs configs,
  ) {
    final theme = Theme.of(context);
    if (appointment.isAllday) {
      return (
        theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: configs.calendarCellOpacity.getOr(1)),
        theme.colorScheme.primary,
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
      );
    }

    return (
      theme.colorScheme.primaryContainer
          .withValues(alpha: configs.calendarCellOpacity.getOr(1)),
      theme.colorScheme.primary,
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
    final (appointmentColor, locationColor) =
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
                      padding: const EdgeInsets.only(top: 16, left: 16),
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
                                      color: theme.colorScheme.secondary,
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
    var theme = Theme.of(context);
    var configs = ArcheBus().of<ApplicationConfigs>();

    return FutureBuilder(
      future: Future<List<ICalendarParser>>(() async {
        var platdir = (await platCalendarDataDirectory.getValue());
        // .subFile("calendar_curriculum.ics");
        return platdir
            .listSync()
            .where((item) => extension(item.path) == ".ics")
            .map((item) {
          final calendar = File(item.path);
          return ICalendarParser(
              calendar.readAsStringSync(),
              basename(item.path) == "calendar_curriculum.ics"
                  ? CalendarSource.curriculum
                  : CalendarSource.other);
        }).toList();
      }),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(snapshot.error.toString()),
          );
        }
        var data = snapshot.data ?? [];

        if (data.isEmpty && (snapshot.data?.isNotEmpty ?? false)) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("尚未生成课表"),
                FilledButton(
                  onPressed: () => setState(() {}),
                  child: const Text("刷新"),
                ),
                FilledButton(
                  onPressed: () =>
                      pushMaterialRoute(builder: (BuildContext context) {
                    return const ICalendarServicePage();
                  }),
                  child: const Text("生成"),
                ),
              ].joinElement(
                const SizedBox(
                  height: 8,
                ),
              ),
            ),
          );
        }
        var view = configs.calendarView.getOr(CalendarView.week);

        if (view == CalendarView.workWeek) {
          view = CalendarView.week;
        }
        final start = configs.calendarTimeStart
            .getOr(const TimeOfDay(hour: 8, minute: 0));
        final end =
            configs.calendarTimeEnd.getOr(const TimeOfDay(hour: 21, minute: 0));

        var calendar = SfCalendar(
          viewHeaderHeight: configs.calendarShowViewHeader.getOr(true) ? -1 : 0,
          backgroundColor: Colors.transparent,
          controller: calendarController,
          initialDisplayDate: _displayDate,
          view: view,
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
          scheduleViewSettings: ScheduleViewSettings(
            hideEmptyScheduleWeek: true,
            monthHeaderSettings:
                MonthHeaderSettings(backgroundColor: theme.colorScheme.primary),
          ),
          appointmentBuilder: (context, calendarAppointmentDetails) {
            final isWeekView = calendarController.view == CalendarView.week;
            return Flex(
              direction: Axis.horizontal,
              children: calendarAppointmentDetails.appointments
                  .map(
                    (appointment) => Expanded(
                      child: SizedBox(
                        height: double.infinity,
                        child:
                            buildAppointment(appointment, configs, isWeekView),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
          dataSource: CurriculumDataSource(data.fold([], (data, parser) {
            data.addAll(parser.data);
            return data;
          })),
        );
        var background = configs.calendarBackgroundImage.tryGet();
        var child = buildHeader(
          calendarController,
          calendar,
        );

        if (background != null) {
          return FutureBuilder(
            future: Future(() async {
              final imagefile = (await platCalendarDataDirectory.getValue())
                  .subFile(background);
              if (context.mounted) {
                await precacheImage(FileImage(imagefile), context);
              }
              return imagefile;
            }),
            builder: (context, snapshot) {
              var data = snapshot.data;
              if (data != null) {
                var blur = configs.calendarBackgroundImageBlur.getOr(0);
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: FileImage(
                            data,
                          ),
                          fit: BoxFit.cover,
                          opacity:
                              configs.calendarBackgroundImageOpacity.getOr(0.3),
                        ),
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

              return child;
            },
          );
        }
        return child;
      },
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
    return "CourseData { summary: $summary, location: $location, dtstart: $start}";
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
    final filter = ArcheBus()
            .of<ApplicationConfigs>()
            .calendarShowAlldayAppionments
            .getOr(true)
        ? (element) => element["type"] == "VEVENT"
        : (element) =>
            element["type"] == "VEVENT" && element["location"] != null;

    return calendar.data.where(filter).map((e) {
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
