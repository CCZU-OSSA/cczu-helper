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
import 'package:flutter/scheduler.dart';
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
  final Function refresh;

  const CalendarHeader(
      {super.key, required this.controller, required this.refresh});

  @override
  State<StatefulWidget> createState() => CalendarHeaderState();
}

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
    var date = controller.displayDate ?? DateTime.now();
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
                initialValue: configs.calendarView.getOr(CalendarView.week),
                icon: Icon(
                  Icons.view_comfortable,
                  color: colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) {
                  configs.calendarView.write(value);

                  if (value == CalendarView.workWeek) {
                    configs.calendarSimple.write(true);
                    controller.view = CalendarView.week;
                  } else {
                    configs.calendarSimple.write(false);
                    controller.view = value;
                  }

                  if (controller.view == CalendarView.week) {
                    widget.refresh();
                  }
                },
                itemBuilder: (context) => [
                  CalendarView.day,
                  CalendarView.week,
                  CalendarView.workWeek, // Week Simple ...
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
    return Column(
      children: [
        CalendarHeader(
          controller: controller,
          refresh: refreshMounted,
        ),
        Expanded(child: child)
      ],
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
    var isWide = isWideScreen(context);
    var theme = Theme.of(context);
    var configs = ArcheBus().of<ApplicationConfigs>();

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

        var calendar = SfCalendar(
          controller: calendarController,
          view: configs.calendarView.getOr(CalendarView.week),
          firstDayOfWeek: 1,
          headerHeight: 0,
          timeSlotViewSettings: TimeSlotViewSettings(
              startHour: 8,
              endHour: 21,
              timeFormat: configs.calendarSimple.getOr(false) ? "" : "H:mm",
              timeRulerSize: configs.calendarSimple.getOr(false) ? 0 : -1,
              timeIntervalHeight: 50,
              timeInterval: Duration(
                  minutes: configs.calendarSimple.getOr(false) ? 60 : 30)),
          cellBorderColor: theme.colorScheme.surfaceContainerHighest,
          cellEndPadding: 0,
          scheduleViewSettings: ScheduleViewSettings(
            hideEmptyScheduleWeek: true,
            monthHeaderSettings:
                MonthHeaderSettings(backgroundColor: theme.colorScheme.primary),
          ),
          appointmentBuilder: (context, calendarAppointmentDetails) {
            CalendarData appointment =
                calendarAppointmentDetails.appointments.first;
            var time =
                '${DateFormat('a hh:mm', Localizations.localeOf(context).languageCode).format(appointment.start.toDateTime()!)} ~ ${DateFormat('a hh:mm', Localizations.localeOf(context).languageCode).format(appointment.end.toDateTime()!)}';
            var dialog = Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_month),
                  title: const Text("时间"),
                  subtitle: Visibility(
                      visible: !isWide,
                      child: Text(
                        time,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                        ),
                      )),
                  trailing: Visibility(
                      visible: isWide,
                      child: Text(
                        time,
                      )),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text("地点"),
                  subtitle: Visibility(
                    visible: !isWide,
                    child: Text(
                      appointment.location.toString(),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  trailing: Visibility(
                    visible: isWide,
                    child: Text(
                      appointment.location.toString(),
                    ),
                  ),
                )
              ],
            );
            return GestureDetector(
              onTap: appointment.isAllday
                  ? null
                  : () {
                      ComplexDialog.instance.text(
                        title: Text(appointment.summary),
                        content: dialog,
                        context: context,
                      );
                    },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: appointment.isAllday
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.primaryContainer,
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
                        child: calendarController.view == CalendarView.week
                            ? Text.rich(
                                TextSpan(
                                  text: "${appointment.summary}\n",
                                  style: const TextStyle(fontSize: 12),
                                  children: [
                                    TextSpan(
                                      text: appointment.location,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: theme.colorScheme.primary,
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
                                              color:
                                                  theme.colorScheme.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      appointment.location.toString(),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                      ),
              ),
            );
          },
          dataSource: CurriculumDataSource(snapshot.data!.get().data),
        );

        return buildHeader(calendarController, calendar);
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
