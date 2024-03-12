import 'dart:convert';

import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:arche/extensions/iter.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/messages/common.pb.dart';
import 'package:cczu_helper/models/channel.dart';
import 'package:flutter/material.dart';

class GradesFeature extends StatefulWidget {
  const GradesFeature({super.key});

  @override
  State<StatefulWidget> createState() => _GradesFeatureState();
}

class _GradesFeatureState extends State<GradesFeature>
    with NativeChannelSubscriber {
  late final ApplicationConfigs configs;
  late final ScrollController controller;
  bool _busy = true;
  List<GradeData> data = [];
  @override
  void initState() {
    super.initState();
    configs = ArcheBus().of();
    subscriber = DartReceiveChannel.rustSignalStream.listen((event) {
      var message = event.message;
      if (message.ok) {
        setState(() {
          data = (jsonDecode(message.data) as List)
              .map((e) => GradeData.fromMap(e))
              .toList();
          _busy = false;
        });
      } else {
        ComplexDialog.instance.text(content: Text(message.data));
      }
    });

    if (!configs.currentAccount.has()) {
      ComplexDialog.instance.text(content: const Text("请先添加账户"));
    } else {
      configs.currentAccount.get().then(
            (value) => RustCallChannel(
              data: value.protoEducationAccount.encode(),
              id: channelGetGrades,
            ).sendSignalToRust(null),
          );
    }
    controller = ScrollController()..addListener(() {});
  }

  @override
  void dispose() {
    super.dispose();
    subscriber.cancel();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _busy
        ? const Center(child: ProgressIndicatorWidget())
        : Scaffold(
            body: ListView(
              controller: ScrollController(),
              children: data
                  .map<Widget>(
                    (e) => ListTile(
                      title: Text(e.name),
                      subtitle: Text(e.point),
                      trailing: Text(
                          e.grade.trim().isEmpty ? "暂无" : e.grade.toString()),
                    ),
                  )
                  .toList()
                  .addThen(const SizedBox(
                    height: 80,
                  )),
            ),
            floatingActionButton: SearchAnchor(
              suggestionsBuilder: (context, controller) => data
                  .where(
                    (element) => element.name
                        .toLowerCase()
                        .contains(controller.text.toLowerCase()),
                  )
                  .map(
                    (e) => ListTile(
                      title: Text(e.name),
                      subtitle: Text(e.point),
                      trailing: Text(
                          e.grade.trim().isEmpty ? "暂无" : e.grade.toString()),
                    ),
                  )
                  .toList(),
              builder: (context, controller) {
                return FloatingActionButton(
                    child: const Icon(Icons.search),
                    onPressed: () {
                      controller.openView();
                    });
              },
            ),
          );
  }
}
