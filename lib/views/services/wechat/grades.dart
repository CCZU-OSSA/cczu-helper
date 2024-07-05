import 'package:arche/arche.dart';
import 'package:cczu_helper/controllers/accounts.dart';
import 'package:cczu_helper/messages/grades.pb.dart';
import 'package:flutter/material.dart';

class WeChatGradeQueryServicePage extends StatefulWidget {
  const WeChatGradeQueryServicePage({super.key});

  @override
  State<StatefulWidget> createState() => WeChatGradeQueryServicePageState();
}

class WeChatGradeQueryServicePageState
    extends State<WeChatGradeQueryServicePage> {
  @override
  void initState() {
    super.initState();
    WeChatGradesInput(
            account: ArcheBus.bus.of<MultiAccoutData>().getCurrentEduAccount())
        .sendSignalToRust();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: WeChatGradesOutput.rustSignalStream,
      builder: (context, snapshot) {
        var signal = snapshot.data;
        if (signal == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        var message = signal.message;

        return Scaffold(
            appBar: AppBar(),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.search),
            ),
            body: RefreshIndicator(
              child: !message.ok
                  ? Center(
                      child: Text(message.error.toString()),
                    )
                  : ListView(
                      children: message.data
                          .map(
                            (course) => Card(
                                child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onLongPress: () {},
                              child: Column(
                                children: [
                                  ListTile(
                                    title: Text(course.courseName),
                                  ),
                                  const Divider(),
                                  ListTile(
                                    title: const Text("平时成绩"),
                                    trailing: Text(
                                        course.usualGrade.toStringAsFixed(1)),
                                  ),
                                  ListTile(
                                    title: const Text("期中成绩"),
                                    trailing: Text(
                                        course.midGrade.toStringAsFixed(1)),
                                  ),
                                  ListTile(
                                    title: const Text("期末成绩"),
                                    trailing: Text(
                                        course.endGrade.toStringAsFixed(1)),
                                  ),
                                  ListTile(
                                    title: const Text("总评"),
                                    trailing: Text(course.examGrade),
                                  ),
                                ],
                              ),
                            )),
                          )
                          .toList(),
                    ),
              onRefresh: () async {
                WeChatGradesInput(
                        account: ArcheBus.bus
                            .of<MultiAccoutData>()
                            .getCurrentEduAccount())
                    .sendSignalToRust();
              },
            ));
      },
    );
  }
}
