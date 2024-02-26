import 'package:arche/arche.dart';
import 'package:arche/extensions/io.dart';
import 'package:arche/extensions/iter.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/views/pages/features/ical.dart';
import 'package:flutter/material.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CurriculumPage extends StatefulWidget {
  const CurriculumPage({super.key});

  @override
  State<StatefulWidget> createState() => CurriculumPageState();
}

class CurriculumPageState extends State<CurriculumPage> {
  @override
  Widget build(BuildContext context) {
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

        return Scaffold(
          body: SfCalendar(
            allowedViews: const [
              CalendarView.day,
              CalendarView.week,
              CalendarView.schedule,
              CalendarView.timelineDay,
            ],
            view: CalendarView.schedule,
            showNavigationArrow: true,
            showTodayButton: true,
            showDatePickerButton: true,
            dataSource: CurriculumDataSource(
                snapshot.data!.value!.data, Theme.of(context)),
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
  String? getLocation(int index) {
    return (appointments![index] as CourseData).location;
  }

  @override
  Color getColor(int index) {
    return theme.colorScheme.primary;
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
                  end: icalItem["dtend"]),
            );
          }

          break;
        default:
      }
    }
    return ICalendarData(courses);
  }
}
