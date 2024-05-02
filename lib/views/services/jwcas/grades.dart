import "dart:async";

import "package:arche/arche.dart";
import "package:arche/extensions/dialogs.dart";
import "package:cczu_helper/controllers/account.dart";
import "package:cczu_helper/messages/grades.pb.dart";
import "package:flutter/material.dart";
import "package:rinf/rinf.dart";

class GradeQueryServicePage extends StatefulWidget {
  const GradeQueryServicePage({super.key});

  @override
  State<StatefulWidget> createState() => GradeQueryServicePageState();
}

class GradeQueryServicePageState extends State<GradeQueryServicePage> {
  late StreamSubscription<RustSignal<GradesOutput>> _streamGradesOutput;
  List<GradeData>? data;
  @override
  void initState() {
    super.initState();
    _streamGradesOutput = GradesOutput.rustSignalStream.listen((event) {
      var message = event.message;
      if (message.ok) {
        setState(() {
          data = message.data;
        });
      } else {
        ComplexDialog.instance.text(
          context: context,
          content: Text(message.error),
        );
      }
    });

    readAccount().then((value) {
      if (value.user == nullUser) {
        ComplexDialog.instance.text(
          context: context,
          content: const Text("账户为空!"),
        );
      } else {
        GradesInput(account: value).sendSignalToRust(null);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _streamGradesOutput.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: ProgressIndicatorWidget(),
        ),
      );
    }

    return Scaffold(
        appBar: AppBar(),
        floatingActionButton: SearchAnchor(
          builder: (context, controller) => FloatingActionButton(
            onPressed: () {
              controller.openView();
            },
            child: const Icon(Icons.search),
          ),
          suggestionsBuilder:
              (BuildContext context, SearchController controller) {
            return data!
                .where((element) => controller.text.isEmpty
                    ? true
                    : element.name
                        .toLowerCase()
                        .contains(controller.text.toLowerCase()))
                .map((e) => ListTile(
                      title: Text(e.name),
                      subtitle: Text(e.point),
                      trailing: Text(e.grade.trim().isEmpty ? "暂无" : e.grade),
                    ));
          },
        ),
        body: ListView(
          children: data!
              .map((e) => ListTile(
                    title: Text(e.name),
                    subtitle: Text(e.point),
                    trailing: Text(e.grade.trim().isEmpty ? "暂无" : e.grade),
                  ))
              .toList(),
        ));
  }
}
