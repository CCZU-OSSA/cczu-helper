import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:cczu_helper/messages/ical.pb.dart';
import 'package:cczu_helper/views/widgets/scrollable.dart';
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

  @override
  Widget build(BuildContext context) {
    return PaddingScrollView(
        child: Column(
      children: [
        const Card(
          child: Padding(
              padding: EdgeInsets.all(8), child: Text("什么是 ICalendar 课表?")),
        ),
        ElevatedButton.icon(
          onPressed: () {
            showDatePicker(
              barrierDismissible: false,
              helpText: "选择学期第一周星期一的日期",
              context: context,
              firstDate: DateTime.now().add(const Duration(days: -365)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            ).then((value) {
              ComplexDialog.instance.input(
                context: context,
              );
            });
          },
          label: const Text("生成"),
          icon: const Icon(Icons.public),
        )
      ],
    ));
  }
}
