import 'package:arche/arche.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class READMEWidget extends StatelessWidget {
  final String resource;
  final EdgeInsetsGeometry padding;
  const READMEWidget({
    super.key,
    required this.resource,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return FutureResolver(
      future: rootBundle.loadString(resource),
      loading: const ProgressIndicatorWidget(
        data: ProgressIndicatorWidgetData(text: "正在读取文件"),
      ),
      data: (data) => Padding(
        padding: padding,
        child: ListView(
          children: [
            const ListTile(
              leading: Icon(Icons.book),
              title: Text("说明"),
              subtitle: Text("README"),
            ),
            Markdown(
              data: data.toString(),
              shrinkWrap: true,
            ),
          ],
        ),
      ),
    );
  }
}
