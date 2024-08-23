import 'dart:io';

import 'package:arche/arche.dart';
import 'package:cczu_helper/controllers/platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<StatefulWidget> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> with TickerProviderStateMixin {
  void loggerCallback() => setState(() {});
  bool _showReversed = false;

  @override
  void initState() {
    super.initState();
    ArcheBus.logger.addListener(loggerCallback);
  }

  @override
  void dispose() {
    ArcheBus.logger.removeListener(loggerCallback);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var logger = ArcheBus.logger;
    var logs = _showReversed ? logger.getLogs().reversed : logger.getLogs();
    return Scaffold(
      appBar: AppBar(
        title: const Text("日志"),
        actions: [
          IconButton(
            onPressed: () => launchUrlString(
                "https://github.com/CCZU-OSSA/cczu-helper/issues"),
            icon: const Icon(FontAwesomeIcons.github),
          ),
          IconButton(
            onPressed: () async {
              var file = await writeStringToPlatDirectory(
                  logger.getLogs().join("\n"),
                  filename: "application.log");
              await Share.shareXFiles([
                XFile(file.path,
                    name: "application.log", mimeType: "text/plain")
              ]);
            },
            icon: const Icon(Icons.share),
          ),
          Visibility(
            visible: !Platform.isAndroid,
            child: IconButton(
              onPressed: () => saveFile(
                logger.getLogs().join("\n"),
                dialogTitle: "保存日志",
                fileName: "application.log",
              ),
              icon: const Icon(Icons.save),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: AnimatedRotation(
          turns: _showReversed ? 0.5 : 0,
          duration: Durations.medium4,
          child: const Icon(Icons.arrow_circle_down_rounded),
        ),
        onPressed: () {
          setState(() {
            _showReversed = !_showReversed;
          });
        },
      ),
      body: AnimatedSwitcher(
        duration: Durations.medium4,
        child: ListView(
          key: ValueKey(_showReversed),
          children: logs
              .map(
                (e) => Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(e.time.toIso8601String()),
                        subtitle: Text(
                          e.level.toString(),
                          style: TextStyle(
                              color:
                                  logger.colorTranslator.translation(e.level)),
                        ),
                        trailing: CopyIconButton(message: e.message),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(e.message),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class CopyIconButton extends StatefulWidget {
  final String message;
  const CopyIconButton({super.key, required this.message});

  @override
  State<StatefulWidget> createState() => CopyIconButtonState();
}

class CopyIconButtonState extends State<CopyIconButton> {
  bool _copy = false;
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      duration: Durations.short4,
      child: _copy
          ? IgnorePointer(
              child: IconButton(
                icon: const Icon(Icons.check),
                onPressed: () {},
              ),
            )
          : IconButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: widget.message));

                setState(() {
                  _copy = true;
                });
                await Future.delayed(const Duration(seconds: 3));

                if (mounted) {
                  setState(() {
                    _copy = false;
                  });
                }
              },
              icon: const Icon(FontAwesomeIcons.clipboard),
            ),
    );
  }
}
