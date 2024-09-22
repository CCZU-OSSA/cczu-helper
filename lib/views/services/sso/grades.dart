import "package:arche/arche.dart";
import "package:cczu_helper/controllers/accounts.dart";
import "package:cczu_helper/messages/all.dart";
import "package:flutter/material.dart";

class GradeQueryServicePage extends StatefulWidget {
  const GradeQueryServicePage({super.key});

  @override
  State<StatefulWidget> createState() => GradeQueryServicePageState();
}

class GradeQueryServicePageState extends State<GradeQueryServicePage> {
  List<GradeData>? data;
  @override
  void initState() {
    super.initState();

    GradesInput(
            account: ArcheBus.bus.of<MultiAccoutData>().getCurrentSSOAccount())
        .sendSignalToRust();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: GradesOutput.rustSignalStream,
      builder: (context, snapshot) {
        var signal = snapshot.data;
        if (signal == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: ProgressIndicatorWidget(),
            ),
          );
        }

        var message = signal.message;
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
              return message.data
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
            children: message.data
                .map((e) => ListTile(
                      title: Text(e.name),
                      subtitle: Text(e.point),
                      trailing: Text(e.grade.trim().isEmpty ? "暂无" : e.grade),
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}
