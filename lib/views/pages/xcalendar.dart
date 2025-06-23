import 'dart:io';
import 'dart:ui';

import 'package:arche/arche.dart';
import 'package:arche/extensions/io.dart';
import 'package:arche/extensions/iter.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/controllers/platform.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:cczu_helper/views/services/common/icalendar.dart';
import 'package:flutter/material.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:intl/intl.dart';
import 'package:kalender/kalender.dart';
import 'package:path/path.dart' show basename, extension;
import 'package:timezone/timezone.dart' as tz;

class XCurriculumPage extends StatefulWidget {
  const XCurriculumPage({super.key});

  @override
  State<StatefulWidget> createState() => XCurriculumPageState();
}

/// Cache the `displayDate` here
DateTime? _displayDate;

class XCurriculumPageState extends State<XCurriculumPage>
    with RefreshMountedStateMixin {
  late CalendarController<CalendarData> controller;
  final formatter = DateFormat.yMMM(
      Localizations.localeOf(viewKey.currentContext!).languageCode);
  @override
  void initState() {
    controller = CalendarController<CalendarData>(
      initialDate: _displayDate ?? DateTime.now(),
    );
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configs = ArcheBus().of<ApplicationConfigs>();
    final theme = Theme.of(context);
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
        var data = snapshot.data;
        if (!snapshot.hasData || data == null) {
          return const Center(
            child: ProgressIndicatorWidget(),
          );
        }

        if (data.isEmpty) {
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
        final start = configs.calendarTimeStart
            .getOr(const TimeOfDay(hour: 8, minute: 0));
        final end =
            configs.calendarTimeEnd.getOr(const TimeOfDay(hour: 21, minute: 0));

        var child = CalendarView(
          eventsController: DefaultEventsController<CalendarData>()
            ..addEvents(
                data.fold(<CalendarEvent<CalendarData>>[], (data, parser) {
              data.addAll(parser.data.where((e) => !e.isAllday).map((e) {
                return CalendarEvent(
                  dateTimeRange: DateTimeRange(
                    start: e.start.toDateTime()!,
                    end: e.end.toDateTime()!,
                  ),
                  data: e,
                  canModify: false,
                );
              }));
              return data;
            }).toList()),
          calendarController: controller,
          viewConfiguration: MultiDayViewConfiguration.week(
            initialHeightPerMinute: 2,
            timeOfDayRange: TimeOfDayRange(start: start, end: end),
          ),
          components: CalendarComponents(
            multiDayComponents: MultiDayComponents(
              headerComponents: MultiDayHeaderComponents<CalendarData>(
                weekNumberBuilder: (visibleDateTimeRange, style) => SizedBox(),
              ),
              bodyComponents: MultiDayBodyComponents(
                daySeparator: configs.calendarIntervalLine.getOr(true)
                    ? DaySeparator.builder
                    : (style) => SizedBox(),
                hourLines: configs.calendarIntervalLine.getOr(true)
                    ? HourLines.builder
                    : (heightPerMinute, timeOfDayRange, style) => SizedBox(),
                prototypeTimeLine: configs.calendarIntervalLine.getOr(true)
                    ? PrototypeTimeline.prototypeBuilder
                    : (heightPerMinute, timeOfDayRange, style) => SizedBox(),
                timeline: configs.calendarIntervalLine.getOr(true)
                    ? TimeLine.builder
                    : (heightPerMinute, timeOfDayRange, style,
                        eventBeingDragged, visibleDateTimeRange) {
                        return SizedBox();
                      },
              ),
            ),
            multiDayComponentStyles: MultiDayComponentStyles(
              headerStyles: MultiDayHeaderComponentStyles(
                dayHeaderStyle: DayHeaderStyle(
                  stringBuilder: (date) => DateFormat(
                          "E", Localizations.localeOf(context).languageCode)
                      .format(date),
                ),
              ),
              bodyStyles: MultiDayBodyComponentStyles(
                timelineStyle: TimelineStyle(
                    textPadding: configs.calendarShowTimeRule.getOr(true)
                        ? null
                        : EdgeInsets.all(0)),
                hourLinesStyle: HourLinesStyle(thickness: 0.5),
                daySeparatorStyle: DaySeparatorStyle(width: 0.5),
              ),
            ),
          ),
          header: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      left: 8, right: 8, top: 4, bottom: 4),
                  child: Row(
                    children: [
                      FilledButton(
                        onPressed: () async {
                          var now = DateTime.now();
                          var date = await showDatePicker(
                              initialDate: controller.initialDate,
                              context: context,
                              firstDate: now.add(const Duration(days: -365)),
                              lastDate: now.add(const Duration(days: 365)));
                          if (date != null) {
                            controller.initialDate = date;
                          }
                        },
                        child: Text(formatter.format(controller.initialDate)),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.surfaceContainerHighest,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: CalendarHeader<CalendarData>(
                    interaction: ValueNotifier(
                      CalendarInteraction(
                        // Allow events to be resized.
                        allowResizing: false,
                        // Allow events to be rescheduled.
                        allowRescheduling: false,
                        // Allow events to be created.
                        allowEventCreation: false,
                      ),
                    ),
                    multiDayHeaderConfiguration: MultiDayHeaderConfiguration(),
                    multiDayTileComponents: TileComponents(tileBuilder:
                        (CalendarEvent<CalendarData> event,
                            DateTimeRange<DateTime> tileRange) {
                      return SizedBox();
                    }),
                  ),
                ),
              ],
            ),
          ),
          body: CalendarBody<CalendarData>(
            multiDayTileComponents: TileComponents(
              tileBuilder: (event, tileRange) {
                final data = event.data;
                if (data == null) {
                  return const SizedBox();
                }

                final (tile, text) = data.getColor(configs, context);

                return Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4), color: tile),
                  child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Text.rich(
                        TextSpan(
                          text: "${data.summary}\n",
                          style: const TextStyle(fontSize: 12),
                          children: [
                            TextSpan(
                              text: data.location.toString(),
                              style: TextStyle(
                                fontSize: 10,
                                color: text,
                              ),
                            )
                          ],
                        ),
                        overflow: TextOverflow.fade,
                      )),
                );
              },
            ),
            callbacks: CalendarCallbacks(
              onEventTapped: (event, renderBox) {
                final data = event.data;
                if (data == null) {
                  return;
                }
                final time =
                    '${DateFormat('HH:mm', Localizations.localeOf(context).languageCode).format(data.start.toDateTime()!)} ~ ${DateFormat('HH:mm', Localizations.localeOf(context).languageCode).format(data.end.toDateTime()!)}';

                showModalBottomSheet(
                  context: context,
                  builder: (context) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16, left: 16),
                        child: Text(
                          data.summary,
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
                                data.location.toString(),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            Visibility(
                              visible: data.description != null,
                              child: ListTile(
                                leading:
                                    data.source == CalendarSource.curriculum
                                        ? const Icon(Icons.person)
                                        : const Icon(Icons.description),
                                title: data.source == CalendarSource.curriculum
                                    ? const Text("教师")
                                    : const Text("简述"),
                                subtitle: SelectableText(
                                  data.source == CalendarSource.curriculum
                                      ? data.description
                                          .toString()
                                          .replaceAll("\\;", ",")
                                          .split(",")
                                          .where((test) => test.isNotEmpty)
                                          .join(",")
                                      : data.description.toString(),
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: data.week != null,
                              child: ListTile(
                                leading: const Icon(Icons.calendar_month),
                                title: const Text("工作周"),
                                subtitle: SelectableText(
                                  data.week.toString(),
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
            ),
            interaction: ValueNotifier(
              CalendarInteraction(
                // Allow events to be resized.
                allowResizing: false,
                // Allow events to be rescheduled.
                allowRescheduling: false,
                // Allow events to be created.
                allowEventCreation: false,
              ),
            ),
          ),
        );
        var background = configs.calendarBackgroundImage.tryGet();

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

              return const CircularProgressIndicator();
            },
          );
        }
        return child;
      },
    );
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

  (Color tile, Color? location) getColor(
    ApplicationConfigs configs,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    if (isAllday) {
      return (
        theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: configs.calendarCellOpacity.getOr(1)),
        theme.colorScheme.primary,
      );
    }

    if (configs.calendarColorful.getOr(false)) {
      final hue = (summary.hashCode % 360).toDouble();
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
