import 'dart:convert';

import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/snackbar.dart';
import 'package:cczu_helper/messages/common.pb.dart';
import 'package:cczu_helper/models/channel.dart';
import 'package:flutter/material.dart';

class TermView extends StatefulWidget {
  final VoidCallback? onChanged;
  const TermView({super.key, this.onChanged});

  @override
  State<StatefulWidget> createState() => _TermViewState();
}

class _TermViewState extends State<TermView> with NativeChannelSubscriber {
  List<TermData>? _data;
  @override
  void initState() {
    super.initState();
    subscriber = DartReceiveChannel.rustSignalStream.listen((message) {
      var data = message.message;
      if (data.ok) {
        if (mounted) {
          setState(() {
            _data = (jsonDecode(data.data) as List)
                .map((map) => TermData.fromMap(map))
                .toList();
          });
        }
      } else {
        ComplexDialog.instance
            .text(content: Text(data.data), context: context)
            .then((value) => Navigator.of(context).pop());
      }
    });
    RustCallChannel(id: channelTermview).sendSignalToRust(null);
  }

  @override
  void dispose() {
    super.dispose();
    subscriber.cancel();
  }

  @override
  Widget build(BuildContext context) {
    var configs = ArcheBus().of<ApplicationConfigs>();
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("学期"),
      ),
      body: _data == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _data!.isEmpty
              ? const Center(
                  child: Text("空"),
                )
              : ListView(
                  children: _data!
                      .map(
                        (e) => ListTile(
                          title: Text(e.name),
                          trailing: Text(e.value),
                          onTap: () {
                            configs.termid.write(e.value);
                            configs.termname.write(e.name);
                            showSnackBar(
                              context: context,
                              content: Text("切换至 ${e.name}(${e.value})"),
                            );

                            widget.onChanged?.call();
                          },
                        ),
                      )
                      .toList(),
                ),
    );
  }
}
