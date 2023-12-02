import 'package:cczu_helper/controller/bus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _StateSettingsPage();
}

class _StateSettingsPage extends State<SettingsPage> {
  final TextEditingController _stuidcontroller = TextEditingController();
  final TextEditingController _termidcontroller = TextEditingController();
  String stuid = "1145141919810";
  String termid = "0d00";
  @override
  Widget build(BuildContext context) {
    var bus = ApplicationBus.instance(context);
    stuid = bus.config.getOrDefault("stuid", "1145141919810");
    termid = bus.config.getOrDefault("termid", "0d00");
    _stuidcontroller.text = stuid;
    _termidcontroller.text = termid;
    return Scaffold(
      appBar: AppBar(
        title: const Text("设置"),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.perm_identity),
            title: const Text("学号"),
            subtitle: const Text("Student ID"),
            trailing: Text(stuid),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: const Text("输入学号"),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _stuidcontroller,
                          onChanged: (v) {
                            setState(() {
                              bus.config.write("stuid", v);
                            });
                          },
                          decoration: const InputDecoration(
                              border: OutlineInputBorder()),
                        ),
                      )
                    ],
                  );
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text("学期"),
            subtitle: const Text("Term ID"),
            trailing: Text(termid),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: const Text("输入学期(不知道填什么问问别人)"),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _termidcontroller,
                          onChanged: (v) {
                            setState(() {
                              bus.config.write("termid", v);
                            });
                          },
                          decoration: const InputDecoration(
                              border: OutlineInputBorder()),
                        ),
                      )
                    ],
                  );
                },
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text("开源地址"),
            subtitle: const Text("Open Source"),
            onTap: () =>
                launchUrlString("https://github.com/CCZU-OSSA/cczu-helper"),
          ),
          ListTile(
            leading: const Icon(Icons.label),
            title: const Text("关于"),
            subtitle: const Text("About"),
            onTap: () => showDialog(
              context: context,
              builder: (context) => const AboutDialog(
                children: [],
              ),
            ),
          )
        ],
      ),
    );
  }
}
