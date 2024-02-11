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
  @override
  Widget build(BuildContext context) {
    var cpxd = ComplexDialog(context: context);

    return PaddingScrollView(
        child: Column(
      children: [
        const Card(
          child: Padding(
              padding: EdgeInsets.all(8), child: Text("什么是 ICalendar 课表?")),
        ),
        ElevatedButton.icon(
          onPressed: () {
            UserDataSyncInput(
                    username: "2300000002",
                    password: "000000",
                    firstweekdate: "",
                    reminder: "15")
                .sendSignalToRust(null);
            ICalJsonCallback.rustSignalStream.listen((event) {
              cpxd.confirm(context: context, content: Text(event.message.data));
            });
          },
          label: const Text("生成"),
          icon: const Icon(Icons.public),
        )
      ],
    ));
  }
}
