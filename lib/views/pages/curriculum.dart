import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:arche/extensions/io.dart';
import 'package:arche/extensions/iter.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/controllers/platform.dart';
import 'package:cczu_helper/views/pages/features/ical.dart';
import 'package:flutter/material.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CurriculumPage extends StatefulWidget {
  const CurriculumPage({super.key});

  @override
  State<StatefulWidget> createState() => CurriculumPageState();
}

class CurriculumPageState extends State<CurriculumPage> {
  void refresh() {
    if (mounted) {
      setState(() {});
    }
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

        return Optional.empty();
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
                  onPressed: () => pushMaterialRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        title: const Text("课表生成"),
                      ),
                      body: const ICalendarFeature(),
                    ),
                  ),
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
        var controller = CalendarController();
        return Scaffold(
          body: SfCalendar(
            allowedViews: const [
              CalendarView.day,
              CalendarView.week,
              CalendarView.schedule,
              CalendarView.timelineDay,
            ],
            controller: controller,
            view: CalendarView.schedule,
            showNavigationArrow: true,
            showTodayButton: true,
            showDatePickerButton: true,
            selectionDecoration: const BoxDecoration(),
            scheduleViewSettings: ScheduleViewSettings(
                hideEmptyScheduleWeek: true,
                monthHeaderSettings: MonthHeaderSettings(
                    backgroundColor: theme.colorScheme.primary)),
            appointmentBuilder: (context, calendarAppointmentDetails) {
              CourseData appointment =
                  calendarAppointmentDetails.appointments.first;
              var time =
                  '${DateFormat('a hh:mm', Localizations.localeOf(context).languageCode).format(appointment.start.toDateTime()!)} ~ ${DateFormat('a hh:mm', Localizations.localeOf(context).languageCode).format(appointment.end.toDateTime()!)}';

              return InkWell(
                onTap: () {
                  ComplexDialog.instance.text(
                      title: Text(appointment.summary),
                      content: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.calendar_month),
                            title: const Text("时间"),
                            subtitle:
                                Visibility(visible: !isWide, child: Text(time)),
                            trailing:
                                Visibility(visible: isWide, child: Text(time)),
                          ),
                          ListTile(
                            leading: const Icon(Icons.location_on),
                            title: const Text("地点"),
                            subtitle: Visibility(
                                visible: !isWide,
                                child: Text(appointment.location)),
                            trailing: Visibility(
                                visible: isWide,
                                child: Text(appointment.location)),
                          )
                        ],
                      ),
                      context: context);
                },
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    border: theme.brightness == Brightness.dark
                        ? null
                        : Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(4),
                    color: theme.colorScheme.onSecondary,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: controller.view != CalendarView.schedule &&
                            controller.view != CalendarView.day
                        ? Center(
                            child: Text(
                              appointment.summary,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  appointment.summary,
                                ),
                              ),
                              Expanded(
                                child: Wrap(
                                  children: [
                                    const Icon(
                                      Icons.calendar_month,
                                    ),
                                    Text(
                                      time,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Icon(
                                      Icons.location_on,
                                    ),
                                    Text(
                                      appointment.location,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                  ),
                ),
              );
            },
            dataSource: CurriculumDataSource(snapshot.data!.value!.data, theme),
          ),
        );
      },
    );
  }
}

class CurriculumDataSource extends CalendarDataSource {
  final ThemeData theme;
  CurriculumDataSource(ICalendarData source, this.theme) {
    appointments = source.courses;
  }
  @override
  String getSubject(int index) {
    CourseData data = appointments![index];
    return "${data.summary}\n${data.location}";
  }

  @override
  String? getNotes(int index) {
    return (appointments![index] as CourseData).summary;
  }

  @override
  String? getLocation(int index) {
    return (appointments![index] as CourseData).location;
  }

  @override
  Color getColor(int index) {
    return theme.colorScheme.onSecondary;
  }

  @override
  DateTime getStartTime(int index) {
    return (appointments![index] as CourseData).start.toDateTime()!;
  }

  @override
  DateTime getEndTime(int index) {
    return (appointments![index] as CourseData).end.toDateTime()!;
  }
}

@immutable
class CourseData {
  final String location;
  final String summary;
  final IcsDateTime start;
  final IcsDateTime end;
  const CourseData({
    required this.location,
    required this.summary,
    required this.start,
    required this.end,
  });

  @override
  String toString() {
    return "CourseData { summary: $summary, location: $location }";
  }
}

@immutable
class ICalendarData {
  final List<CourseData> courses;
  const ICalendarData(this.courses);
}

class ICalendarParser {
  final ICalendar source;
  ICalendarParser(String source) : source = ICalendar.fromString(source);

  ICalendarData get data {
    var courses = <CourseData>[];

    for (var icalItem in source.data) {
      switch (icalItem["type"]) {
        case "VEVENT":
          if (icalItem.containsKey("location")) {
            courses.add(
              CourseData(
                location: icalItem["location"],
                summary: icalItem["summary"],
                start: icalItem["dtstart"],
                end: icalItem["dtend"],
              ),
            );
          }

          break;
        default:
      }
    }
    return ICalendarData(courses);
  }
}
