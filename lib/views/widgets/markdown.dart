import 'package:arche/arche.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AssetMarkdown extends StatelessWidget {
  final String resource;
  final EdgeInsets padding;
  const AssetMarkdown({
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
      data: (data) => Markdown(
        data: data.toString(),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        onTapLink: (text, href, title) => launchUrlString(href.toString()),
      ),
    );
  }
}
