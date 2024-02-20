import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:arche/extensions/functions.dart';
import 'package:cczu_helper/controllers/platform.dart';
import 'package:cczu_helper/messages/ical.pb.dart';
import 'package:flutter/material.dart';

class ICalendarFeature extends StatefulWidget {
  const ICalendarFeature({super.key});

  @override
  State<StatefulWidget> createState() => ICalendarFeatureState();
}

class ICalendarFeatureState extends State<ICalendarFeature> {
  void generateICalendar() {
    UserDataSyncInput(
            username: "2300000002",
            password: "000000",
            firstweekdate: "",
            reminder: "15")
        .sendSignalToRust(null);
    ICalJsonCallback.rustSignalStream.listen((event) {
      ComplexDialog.instance
          .text(context: context, content: Text(event.message.data));
    });
  }

  String? firstweekdate;
  String? reminder;
  @override
  Widget build(BuildContext context) {
    var pageItems = [
      const Expanded(
        flex: 3,
        child: Card(
          child: Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox.expand(
                child: Text("什么是 ICalendar 课表?"),
              )),
        ),
      ),
      Expanded(
        flex: 2,
        child: Column(
          children: [
            ListTile(
              title: const Text("日期"),
              trailing: Text(firstweekdate.toString()),
              onTap: () {
                var now = DateTime.now();
                showDatePicker(
                  context: context,
                  initialDate: now,
                  firstDate: now.add(const Duration(days: -365)),
                  lastDate: now.add(const Duration(days: 365)),
                ).then(
                  (value) => whenNotNull(
                    value,
                    (value) => setState(() {
                      firstweekdate =
                          "${value.year}${value.month.toString().padLeft(2, "0")}${value.day.toString().padLeft(2, "0")}";
                    }),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text("课前提醒"),
              trailing: Text("$reminder 分钟"),
              onTap: () {
                ComplexDialog.instance
                    .input(
                        context: context,
                        title: const Text("输入整数"),
                        decoration: const InputDecoration(
                          labelText: "课前提醒",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number)
                    .then(
                      (value) => whenNotNull(value, (text) {
                        if (int.tryParse(text) != null) {
                          setState(() {
                            reminder = text;
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("\"$value\" 不是一个整数")));
                        }
                      }),
                    );
              },
            ),
          ],
        ),
      )
    ];

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.public),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: isWideScreen(context)
            ? Row(children: pageItems)
            : Column(children: pageItems),
      ),
    );
  }
}
