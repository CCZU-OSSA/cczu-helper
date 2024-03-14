import 'dart:convert';

import 'package:arche/arche.dart';
import 'package:arche/extensions/iter.dart';
import 'package:cczu_helper/controllers/platform.dart';
import 'package:cczu_helper/messages/common.pb.dart';
import 'package:cczu_helper/models/channel.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:cczu_helper/models/version.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CheckUpdatePage extends StatefulWidget {
  const CheckUpdatePage({super.key});

  @override
  State<StatefulWidget> createState() => CheckUpdatePageState();
}

class CheckUpdatePageState extends State<CheckUpdatePage>
    with NativeChannelSubscriber {
  bool _busy = true;
  String status = "空空如也";
  bool hasUpdate = false;
  bool ok = true;
  Map data = {};

  @override
  void initState() {
    super.initState();
    subscriber = DartReceiveChannel.rustSignalStream.listen((event) {
      var message = event.message;
      _busy = false;

      if (message.ok) {
        ok = true;
        var data = jsonDecode(message.data);
        Version latestVersion = getVersionfromString(data["tag_name"]);
        if (latestVersion < appVersion) {
          return setState(() {
            status = "正在使用测试版本";
          });
        } else if (latestVersion == appVersion) {
          return setState(() {
            status = "已是最新版";
          });
        }

        return setState(() {
          this.data = data;
          hasUpdate = true;
        });
      }

      return setState(() {
        ok = false;
      });
    });

    RustCallChannel(id: channelCheckUpdate).sendSignalToRust(null);
  }

  @override
  void dispose() {
    super.dispose();
    subscriber.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("检查更新"),
      ),
      body: Center(
        child: AnimatedSwitcher(
          duration: Durations.medium4,
          child: _busy
              ? const ProgressIndicatorWidget(
                  data: ProgressIndicatorWidgetData(text: "你先别急"),
                )
              : ok
                  ? hasUpdate
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: SingleChildScrollView(
                                child: SizedBox(
                                  width: isWideScreen(context)
                                      ? MediaQuery.of(context).size.width * 0.6
                                      : null,
                                  child: Column(
                                    children: [
                                      ListTile(
                                        title: Text(
                                          data["name"].toString(),
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                      ),
                                      Markdown(
                                        data: data["body"],
                                        shrinkWrap: true,
                                        onTapLink: (text, href, title) =>
                                            launchUrlString(href.toString()),
                                      ),
                                    ].addAllThen((data["assets"] as List)
                                        .map(
                                          (e) => Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: FilledButton.icon(
                                              onPressed: () => launchUrlString(
                                                  e["browser_download_url"]),
                                              icon: const Icon(Icons.download),
                                              label: Center(
                                                child: Text(e["name"]),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList()),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              const Icon(
                                Icons.check,
                                size: 48,
                              ),
                              Text(status)
                            ])
                  : ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _busy = true;
                        });

                        RustCallChannel(id: channelCheckUpdate)
                            .sendSignalToRust(null);
                      },
                      label: const Text("重试"),
                      icon: const Icon(Icons.refresh),
                    ),
        ),
      ),
    );
  }
}
