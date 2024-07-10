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
  List<bool> showTerm = List.filled(8, false);
  bool onlyResit = false;
  bool onlyRebuild = false;
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
        int curTerm = message.data.fold(
            0, (term, element) => term < element.term ? element.term : term);

        showTerm[curTerm - 1] = true;

        List<Widget> items = message.data.map((course) {
          var examGrade = double.tryParse(course.examGrade) ?? 100;
          var resit = examGrade < 60;
          var rebuild = examGrade < 45;
          bool visible = showTerm[course.term - 1];
          curTerm = curTerm < course.term ? course.term : curTerm;
          Color? examColor;
          if (rebuild) {
            examColor = Colors.red;
          } else if (resit) {
            examColor = Colors.amber;
          }

          if (visible && onlyRebuild && onlyResit) {
            visible = visible && (resit || rebuild);
          } else if (visible && onlyResit) {
            visible = visible && resit;
          } else if (visible && onlyRebuild) {
            visible = visible && rebuild;
          }
          return Visibility(
            visible: visible,
            child: Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text(course.courseName),
                    trailing: Chip(label: Text(course.term.toString())),
                  ),
                  const Divider(),
                  Visibility(
                    visible: course.usualGrade != 0,
                    child: ListTile(
                      title: const Text("平时成绩"),
                      trailing: Text(course.usualGrade.toStringAsFixed(1)),
                    ),
                  ),
                  Visibility(
                    visible: course.midGrade != 0,
                    child: ListTile(
                      title: const Text("期中成绩"),
                      trailing: Text(course.midGrade.toStringAsFixed(1)),
                    ),
                  ),
                  Visibility(
                    visible: course.endGrade != 0,
                    child: ListTile(
                      title: const Text("期末成绩"),
                      trailing: Text(
                        course.endGrade.toStringAsFixed(1),
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text("总评"),
                    trailing: Text(
                      course.examGrade,
                      style: TextStyle(color: examColor),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList();
        List<Widget> children = [];
        if (items.isNotEmpty) {
          children.add(
            Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  FilterChip(
                    label: const Text("大一上"),
                    selected: showTerm[0],
                    onSelected: (bool value) {
                      setState(() {
                        showTerm[0] = value;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text("大一下"),
                    selected: showTerm[1],
                    onSelected: (bool value) {
                      setState(() {
                        showTerm[1] = value;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text("大二上"),
                    selected: showTerm[2],
                    onSelected: (bool value) {
                      setState(() {
                        showTerm[2] = value;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text("大二下"),
                    selected: showTerm[3],
                    onSelected: (bool value) {
                      setState(() {
                        showTerm[3] = value;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text("大三上"),
                    selected: showTerm[4],
                    onSelected: (bool value) {
                      setState(() {
                        showTerm[4] = value;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text("大三下"),
                    selected: showTerm[5],
                    onSelected: (bool value) {
                      setState(() {
                        showTerm[5] = value;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text("大四上"),
                    selected: showTerm[6],
                    onSelected: (bool value) {
                      setState(() {
                        showTerm[6] = value;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text("大四下"),
                    selected: showTerm[7],
                    onSelected: (bool value) {
                      setState(() {
                        showTerm[7] = value;
                      });
                    },
                  ),
                  FilterChip.elevated(
                    label: const Text("仅补考"),
                    selected: onlyResit,
                    onSelected: (bool value) {
                      setState(() {
                        onlyResit = value;
                      });
                    },
                  ),
                  FilterChip.elevated(
                    label: const Text("仅重修"),
                    selected: onlyRebuild,
                    onSelected: (bool value) {
                      setState(() {
                        onlyRebuild = value;
                      });
                    },
                  )
                ],
              ),
            ),
          );
        }

        children.addAll(items);
        return Scaffold(
          appBar: AppBar(
            actions: [
              SearchAnchor(
                builder: (context, controller) => IconButton(
                  onPressed: () {
                    controller.openView();
                  },
                  icon: const Icon(Icons.search),
                ),
                suggestionsBuilder:
                    (BuildContext context, SearchController controller) {
                  return message.data
                      .where((element) => element.courseName
                          .toLowerCase()
                          .contains(controller.text.toLowerCase()))
                      .map(
                        (e) => ListTile(
                          title: Text(e.courseName),
                          subtitle: Text(e.credits.toStringAsFixed(1)),
                          trailing: Text(e.examGrade),
                        ),
                      );
                },
              ),
            ],
          ),
          body: !message.ok
              ? Center(
                  child: Text(message.error.toString()),
                )
              : ListView(
                  children: children,
                ),
        );
      },
    );
  }
}
