import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:arche/extensions/io.dart';
import 'package:arche/extensions/iter.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/controllers/platform.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:cczu_helper/models/translators.dart';
import 'package:cczu_helper/views/services/sso/icalendar.dart';
import 'package:flutter/material.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CurriculumPage extends StatefulWidget {
  const CurriculumPage({super.key});

  @override
  State<StatefulWidget> createState() => CurriculumPageState();
}

class CalendarHeader extends StatefulWidget {
  final CalendarController controller;

  const CalendarHeader({super.key, required this.controller});

  @override
  State<StatefulWidget> createState() => CalendarHeaderState();
}

class CalendarHeaderState extends State<CalendarHeader> {
  CalendarController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    var formatter = DateFormat.yMMM(
        Localizations.localeOf(viewKey.currentContext!).languageCode);
    var date = controller.displayDate ?? DateTime.now();
    ApplicationConfigs configs = ArcheBus().of();
    var isWide = isWideScreen(context);
    var arrow = Row(
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              controller.backward!();
            });
          },
          icon: const Icon(Icons.arrow_left_rounded),
        ),
        IconButton(
          onPressed: () {
            controller.forward!();
            setState(() {});
          },
          icon: const Icon(Icons.arrow_right_rounded),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Visibility(visible: isWide, child: arrow),
              FilledButton(
                onPressed: () async {
                  var now = DateTime.now();
                  var date = await showDatePicker(
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
                initialValue: configs.calendarView.getOr(CalendarView.week),
                icon: Icon(
                  Icons.view_comfortable,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) {
                  setState(() {
                    configs.calendarView.write(value);
                    controller.view = value;
                  });
                },
                itemBuilder: (context) => [
                  CalendarView.day,
                  CalendarView.week,
                  CalendarView.schedule
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
                  child: arrow),
            ],
          ),
        ],
      ),
    );
  }
}

class CurriculumPageState extends State<CurriculumPage>
    with RefreshMountedStateMixin {
  Widget buildHeader(
    CalendarController controller,
    Widget child,
  ) {
    return Column(
      children: [
        CalendarHeader(controller: controller),
        Expanded(child: child)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var isWide = isWideScreen(context);
    return FutureBuilder(
      future: Future<Optional<ICalendarParser>>(() async {
        var datafile =
            (await platDirectory.getValue()).subFile("_curriculum.ics");

        if (await datafile.exists()) {
          return Optional(
              value: ICalendarParser(await datafile.readAsString()));
        }

        return const Optional.none();
      }),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: ProgressIndicatorWidget(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(snapshot.error.toString()),
          );
        }

        if (snapshot.data!.isNull()) {
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
        var theme = Theme.of(context);
        var configs = ArcheBus().of<ApplicationConfigs>();
        var controller = CalendarController();
        var calendar = SfCalendar(
          controller: controller,
          view: configs.calendarView.getOr(CalendarView.week),
          firstDayOfWeek: 1,
          headerHeight: 0,
          timeSlotViewSettings: TimeSlotViewSettings(
            startHour: 8,
            endHour: 21,
            timeIntervalHeight: isWide ? 60 : 120,
          ),
          scheduleViewSettings: ScheduleViewSettings(
              hideEmptyScheduleWeek: true,
              monthHeaderSettings: MonthHeaderSettings(
                  backgroundColor: theme.colorScheme.primary)),
          appointmentBuilder: (context, calendarAppointmentDetails) {
            CalendarData appointment =
                calendarAppointmentDetails.appointments.first;
            var time =
                '${DateFormat('a hh:mm', Localizations.localeOf(context).languageCode).format(appointment.start.toDateTime()!)} ~ ${DateFormat('a hh:mm', Localizations.localeOf(context).languageCode).format(appointment.end.toDateTime()!)}';

            return GestureDetector(
              onTap: appointment.isAllday
                  ? null
                  : () {
                      ComplexDialog.instance.text(
                          title: Text(appointment.summary),
                          content: Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.calendar_month),
                                title: const Text("时间"),
                                subtitle: Visibility(
                                    visible: !isWide, child: Text(time)),
                                trailing: Visibility(
                                    visible: isWide, child: Text(time)),
                              ),
                              ListTile(
                                leading: const Icon(Icons.location_on),
                                title: const Text("地点"),
                                subtitle: Visibility(
                                    visible: !isWide,
                                    child:
                                        Text(appointment.location.toString())),
                                trailing: Visibility(
                                    visible: isWide,
                                    child:
                                        Text(appointment.location.toString())),
                              )
                            ],
                          ),
                          context: context);
                    },
              child: Container(
                decoration: BoxDecoration(
                  border: theme.brightness == Brightness.dark
                      ? null
                      : Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(4),
                  color: appointment.isAllday
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.onSecondary,
                ),
                child: appointment.isAllday
                    ? Center(
                        child: Text(
                          appointment.summary,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(4),
                        child: Visibility(
                          visible: controller.view != CalendarView.week,
                          replacement: Text(
                            "${appointment.summary} | ${appointment.location}",
                            overflow: TextOverflow.fade,
                            style: const TextStyle(fontSize: 12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  appointment.summary,
                                  overflow: TextOverflow.fade,
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Wrap(
                                    children: [
                                      const Icon(
                                        Icons.calendar_month,
                                      ),
                                      Text(
                                        time,
                                      ),
                                      const Icon(
                                        Icons.location_on,
                                      ),
                                      Text(
                                        appointment.location.toString(),
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            );
          },
          dataSource: CurriculumDataSource(snapshot.data!.get().data),
        );

        return buildHeader(controller, calendar);
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

@immutable
class CalendarData {
  final String? location;
  final String summary;
  final IcsDateTime start;
  final IcsDateTime end;
  final bool isAllday;
  const CalendarData({
    required this.location,
    required this.summary,
    required this.start,
    required this.end,
    this.isAllday = false,
  });

  @override
  String toString() {
    return "CourseData { summary: $summary, location: $location, dtstart: $start }";
  }
}

class ICalendarParser {
  final ICalendar source;
  ICalendarParser(String source) : source = ICalendar.fromString(source);

  List<CalendarData> get data {
    return source.data.where((element) => element["type"] == "VEVENT").map((e) {
      return CalendarData(
          location: e["location"].toString(),
          summary: e["summary"].toString(),
          start: e["dtstart"],
          end: e["dtend"],
          isAllday: e["location"] == null);
    }).toList();
  }
}
