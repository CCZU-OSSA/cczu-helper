import 'package:arche/arche.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<StatefulWidget> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  void loggerCallback() => setState(() {});
  @override
  void initState() {
    super.initState();
    ArcheBus.logger.addListener(loggerCallback);
  }

  @override
  void dispose() {
    super.dispose();
    ArcheBus.logger.removeListener(loggerCallback);
  }

  @override
  Widget build(BuildContext context) {
    var logger = ArcheBus.logger;
    return Scaffold(
      appBar: AppBar(
        title: const Text("日志"),
      ),
      body: ListView(
        children: logger
            .getLogs()
            .reversed
            .map(
              (e) => Padding(
                padding: const EdgeInsets.all(8),
                child: Card(
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
                        trailing: IconButton(
                            onPressed: () => Clipboard.setData(
                                    ClipboardData(text: e.message))
                                .then((value) => ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                        content: Text("Copied!")))),
                            icon: const Icon(FontAwesomeIcons.clipboard)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(e.message),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
