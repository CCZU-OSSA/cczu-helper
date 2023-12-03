import 'package:cczu_helper/controller/bus.dart';
import 'package:flutter/material.dart';

class LogViewPage extends StatefulWidget {
  const LogViewPage({super.key});

  @override
  State<StatefulWidget> createState() => _StateLogViewPage();
}

class _StateLogViewPage extends State<LogViewPage> {
  @override
  Widget build(BuildContext context) {
    var logger = ApplicationBus.instance(context).logger;
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.exit_to_app)),
          title: const Text("日志"),
        ),
        body: ListView(
          children: List.generate(
              logger.logs.length,
              (index) => ListTile(
                    title: Text(logger.logs[index]),
                  )),
        ));
  }
}
