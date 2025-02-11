import 'dart:async';

import 'package:arche/arche.dart';
import 'package:cczu_helper/messages/all.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:cczu_helper/models/version.dart';
import 'package:cczu_helper/views/widgets/adaptive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rinf/rinf.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CheckUpdatePage extends StatefulWidget {
  const CheckUpdatePage({super.key});

  @override
  State<StatefulWidget> createState() => CheckUpdatePageState();
}

class CheckUpdatePageState extends State<CheckUpdatePage> {
  late StreamSubscription<RustSignal<GetVersionOutput>> _streamVersionOutput;
  VersionInfo? data;

  @override
  void initState() {
    super.initState();
    _streamVersionOutput = GetVersionOutput.rustSignalStream.listen((event) {
      var message = event.message;
      if (message.ok) {
        setState(() {
          data = message.data;
        });
      } else {
        data = null;
      }
    });
    GetVersionInput().sendSignalToRust();
  }

  @override
  void dispose() {
    _streamVersionOutput.cancel();

    super.dispose();
  }

  // busy fail ok
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("检查更新"),
        ),
        body: Center(
          child: AnimatedSwitcher(
            duration: Durations.medium4,
            child: data == null
                ? const ProgressIndicatorWidget(
                    data: ProgressIndicatorWidgetData(text: "正在拉取版本信息..."),
                  )
                : AdaptiveView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Tooltip(
                            message: data!.tagName,
                            child: Text(
                              data!.name,
                              style: const TextStyle(
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Card.outlined(
                          child: Markdown(
                            data: data!.body,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            onTapLink: (text, href, title) =>
                                launchUrlString(href.toString()),
                          ),
                        ),
                        Column(
                          children: data!.assets
                              .map(
                                (e) => ListTile(
                                    leading: const Icon(FontAwesomeIcons.file),
                                    title: Tooltip(
                                      message: e.name,
                                      child: Text(
                                        e.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    subtitle: Text(
                                        "${(e.size / 1024 / 1024).toStringAsFixed(2)} MB"),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Tooltip(
                                          message: "下载",
                                          child: IconButton(
                                            onPressed: () => launchUrlString(
                                              e.browserDownloadUrl,
                                              mode: LaunchMode
                                                  .externalApplication,
                                            ),
                                            icon: const Icon(Icons.download),
                                          ),
                                        ),
                                        Tooltip(
                                          message: "镜像下载",
                                          child: IconButton(
                                            onPressed: () => launchUrlString(
                                              "https://ghfast.top/${e.browserDownloadUrl}",
                                              mode: LaunchMode
                                                  .externalApplication,
                                            ),
                                            icon: const Icon(
                                                FontAwesomeIcons.server),
                                          ),
                                        )
                                      ],
                                    )),
                              )
                              .toList(),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: getVersionfromString(data!.tagName) !=
                                    appVersion
                                ? ActionChip(
                                    backgroundColor: Colors.amber,
                                    avatar: Icon(
                                      Icons.warning,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                    label: Text(
                                        getVersionfromString(data!.tagName) <
                                                appVersion
                                            ? "正在使用测试版本"
                                            : "有可用更新"),
                                    onPressed: () => launchUrlString(
                                        "https://github.com/CCZU-OSSA/cczu-helper/releases/latest"),
                                  )
                                : Chip(
                                    backgroundColor: Colors.green,
                                    avatar: Icon(
                                      Icons.check,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                    label: const Text("已是最新版本"),
                                  ),
                          ),
                        )
                      ],
                    ),
                  ),
          ),
        ));
  }
}
