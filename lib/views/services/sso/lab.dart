import 'dart:async';

import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:cczu_helper/controllers/accounts.dart';
import 'package:cczu_helper/controllers/snackbar.dart';
import 'package:cczu_helper/messages/all.dart';
import 'package:cczu_helper/views/widgets/adaptive.dart';
import 'package:flutter/material.dart';
import 'package:rinf/rinf.dart';

class LabServicePage extends StatefulWidget {
  const LabServicePage({super.key});

  @override
  State<StatefulWidget> createState() => LabServicePageState();
}

class LabServicePageState extends State<LabServicePage> {
  int count = 960;
  bool working = false;
  late StreamSubscription<RustSignal<LabDurationUserOutput>> _output;

  @override
  void initState() {
    super.initState();
    _output = LabDurationUserOutput.rustSignalStream.listen((data) {
      if (mounted) {
        if (data.message.ok) {
          showSnackBar(context: context, content: const Text("完成"));
        } else {
          ComplexDialog.instance
              .text(context: context, content: Text(data.message.err));
        }

        setState(() {
          working = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _output.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("实验室时长"),
      ),
      body: AdaptiveView(
        cardMargin: const EdgeInsets.only(bottom: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: const Text("设置时长"),
              subtitle: const Text("Duration"),
              trailing: FilledButton.icon(
                onPressed: () async {
                  var data = await ComplexDialog.instance
                      .withContext(context: context)
                      .input(
                        title: const Text("N * 30s"),
                        keyboardType: const TextInputType.numberWithOptions(),
                        decoration:
                            const InputDecoration(border: OutlineInputBorder()),
                      );
                  if (data == null) {
                    return;
                  }
                  var count = int.tryParse(data);
                  if (count == null || count < 1) {
                    if (mounted) {
                      showSnackBar(
                          context: this.context,
                          content: const Text("请输入正整数!"));
                    }
                  } else {
                    setState(() {
                      this.count = count;
                    });
                  }
                },
                icon: const Icon(Icons.edit),
                label: Text(
                    "${count * 30 ~/ 3600} 时 ${count * 30 ~/ 60 % 60} 分 ${count * 30 % 60} 秒"),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: working
            ? null
            : () {
                LabDurationUserInput(
                        account: ArcheBus()
                            .of<MultiAccoutData>()
                            .getCurrentSSOAccount(),
                        count: count)
                    .sendSignalToRust();
                setState(() {
                  working = true;
                });
              },
        child: working
            ? const CircularProgressIndicator()
            : const Icon(Icons.check),
      ),
    );
  }
}
