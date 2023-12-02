import 'package:cczu_helper/controller/bus.dart';
import 'package:cczu_helper/models/check.dart';
import 'package:flutter/material.dart';

class QueryCheckPage extends StatefulWidget {
  const QueryCheckPage({super.key});

  @override
  State<StatefulWidget> createState() => _StateQueryCheckPage();
}

class _StateQueryCheckPage extends State<QueryCheckPage> {
  bool underloading = false;

  @override
  Widget build(BuildContext context) {
    var bus = ApplicationBus.instance(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("打卡查询"),
      ),
      body: ListView(
        children: [
          const Card(
            child: Column(children: [
              Text(
                "说明",
                style: TextStyle(fontSize: 24),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                    "查询前请先前往个人设置学号/学期❤\n由于吊大的打卡查询过于垃圾，查询时间非常久，失败率也极高😅\n如果你能查到，说明你的运气不错......查不到过会试试吧😋"),
              )
            ]),
          ),
          Center(
              child: Text(
            "${bus.config.getOrDefault("nowcount", "NaN")}/${bus.config.getOrDefault("stdcount", "NaN")}",
            style: const TextStyle(fontSize: 60),
          )),
          const Center(
            child: Text(
              "打卡次数",
              style: TextStyle(fontSize: 24),
            ),
          ),
          Center(
            child: Text(bus.config.getOrDefault("lasttime", "无")),
          ),
          const SizedBox(
            height: 24,
          ),
          underloading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton(
                    child: const Text("刷新"),
                    onPressed: () => setState(() {
                      if (bus.config.has("stuid") && bus.config.has("termid")) {
                        underloading = true;
                        CheckData.fetch(bus.config.get("stuid"),
                                bus.config.get("termid"))
                            .then((value) {
                          if (mounted) {
                            setState(() {
                              if (value != null) {
                                bus.config.write("nowcount", value.nowcount);
                                bus.config.write("stdcount", value.stdcount);
                                var time = DateTime.now();
                                bus.config.write("lasttime",
                                    "${time.year}-${time.month}-${time.day} ${time.hour}:${time.minute}:${time.second}");
                              }
                              underloading = false;
                            });
                          }
                        });
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => const SimpleDialog(
                            title: Text("尚未设置学号/学期"),
                            children: [
                              Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text("点击 我的")),
                              Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text("点击 学号/学期 的相关设置进行编辑"))
                            ],
                          ),
                        );
                      }
                    }),
                  )),
        ],
      ),
    );
  }
}
