import 'dart:collection';

import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:arche/extensions/iter.dart';
import 'package:cczu_helper/animation/rainbow.dart';
import 'package:cczu_helper/controllers/accounts.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/messages/all.dart';
import 'package:cczu_helper/views/widgets/scrollable.dart';
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
  bool onlyTypeResit = false;
  bool onlyTypeEndExam = false;

  bool init = true;

  @override
  void initState() {
    super.initState();
    WeChatGradesInput(
            account: ArcheBus.bus.of<MultiAccoutData>().getCurrentEduAccount())
        .sendSignalToRust();
  }

  @override
  Widget build(BuildContext context) {
    ApplicationConfigs configs = ArcheBus().of();
    bool dream = configs.funDream.getOr(false);
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

        if (!message.ok) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(message.error),
            ),
          );
        }

        int curTerm = message.data.fold(
            0, (term, element) => term < element.term ? element.term : term);
        if (init) {
          showTerm[curTerm - 1] = true;
          init = false;
        }

        List<Widget> items = message.data.map((course) {
          var resit = course.grade < 60;
          var rebuild = course.grade < 45;
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

          var typeEndExam = course.examType == "期末总评";
          var typeResit = course.examType == "补考";

          if (visible && onlyTypeEndExam && onlyTypeResit) {
            visible = visible && (typeResit || typeEndExam);
          } else if (visible && onlyTypeResit) {
            visible = visible && typeResit;
          } else if (visible && onlyTypeEndExam) {
            visible = visible && typeEndExam;
          }

          return Visibility(
            visible: visible,
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  ComplexDialog.instance.withContext(context: context).text(
                      title: Text("信息"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: Text("学期"),
                            trailing: Text(course.term.toString()),
                          ),
                          ListTile(
                            title: Text("学分"),
                            trailing: Text(course.credits.toString()),
                          ),
                          ListTile(
                            title: Text("绩点"),
                            trailing:
                                Text(course.gradePoints.toStringAsFixed(2)),
                          ),
                          ListTile(
                            title: Text("课程类型"),
                            trailing: Text(course.courseTypeName),
                          ),
                        ],
                      ));
                },
                child: Column(
                  children: [
                    ListTile(
                      title: Text(course.courseName),
                      trailing: Text(course.teacherName.trim()),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text("考试类型"),
                      trailing: Text(course.examType),
                    ),
                    Visibility(
                      visible: course.usualGrade != 0,
                      child: ListTile(
                        title: const Text("平时成绩"),
                        trailing: Text(dream
                            ? "100.0"
                            : course.usualGrade.toStringAsFixed(1)),
                      ).rainbowWhen(dream),
                    ),
                    Visibility(
                      visible: course.midGrade != 0,
                      child: ListTile(
                        title: const Text("期中成绩"),
                        trailing: Text(dream
                            ? "100.0"
                            : course.midGrade.toStringAsFixed(1)),
                      ).rainbowWhen(dream),
                    ),
                    Visibility(
                      visible: course.endGrade != 0,
                      child: ListTile(
                        title: const Text("期末成绩"),
                        trailing: Text(
                          dream ? "100.0" : course.endGrade.toStringAsFixed(1),
                        ),
                      ).rainbowWhen(dream),
                    ),
                    ListTile(
                      title: const Text("总评"),
                      trailing: Text(
                        dream ? "100.0" : course.grade.toString(),
                        style: TextStyle(color: examColor),
                      ),
                    ).rainbowWhen(dream),
                  ],
                ),
              ),
            ),
          );
        }).toList();
        List<Widget> children = [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ...["大一上", "大一下", "大二上", "大二下", "大三上", "大三下", "大四上", "大四下"]
                    .enumerate(
                  (index, label) => FilterChip(
                    label: Text(label),
                    selected: showTerm[index],
                    onSelected: (bool value) {
                      setState(
                        () {
                          showTerm[index] = value;
                        },
                      );
                    },
                  ),
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
                ),
                FilterChip.elevated(
                  label: const Text("类型: 期末"),
                  selected: onlyTypeEndExam,
                  onSelected: (bool value) {
                    setState(() {
                      onlyTypeEndExam = value;
                    });
                  },
                ),
                FilterChip.elevated(
                  label: const Text("类型: 补考"),
                  selected: onlyTypeResit,
                  onSelected: (bool value) {
                    setState(() {
                      onlyTypeResit = value;
                    });
                  },
                )
              ],
            ),
          ),
          ...items
        ];

        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                onPressed: () {
                  Map<String, double> data = HashMap();
                  double total = 0;
                  for (var e in message.data) {
                    if (e.grade < 60) {
                      continue;
                    }

                    var name = e.courseTypeName.trim();
                    if (data.containsKey(name)) {
                      data[name] = data[name]! + e.credits;
                    } else {
                      data[name] = e.credits;
                    }
                    total += e.credits;
                  }
                  data["总计"] = total;
                  var sorted = data.entries.toList();
                  sorted.sort((a, b) => a.value.compareTo(b.value));

                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => Scaffold(
                        appBar: AppBar(
                          title: Text("已修学分"),
                        ),
                        body: ListView(
                          children: [
                            ListTile(
                              leading: Icon(Icons.info),
                              title: Text("仅供参考，已扣除不及格科目"),
                            ),
                            ...sorted.map((e) => ListTile(
                                  title: Text(e.key),
                                  trailing: Text(e.value.toString()),
                                ))
                          ],
                        )),
                  ));
                },
                icon: Icon(Icons.pie_chart),
              ),
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
                          trailing: Text(e.grade.toString()),
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
              : PaddingScrollView(
                  child: Column(
                    children: children,
                  ),
                ),
        );
      },
    );
  }
}
