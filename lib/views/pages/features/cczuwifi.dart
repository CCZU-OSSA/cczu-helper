import 'package:cczu_helper/controllers/platform.dart';
import 'package:flutter/material.dart';

class CCZUWifiFeature extends StatefulWidget {
  const CCZUWifiFeature({super.key});

  @override
  State<StatefulWidget> createState() => _CCZUWifiFeatureState();
}

class _CCZUWifiFeatureState extends State<CCZUWifiFeature> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var isWide = isWideScreen(context);
    var pageItems = [const Expanded(child: Text("123"))];
    return isWide
        ? Row(
            children: pageItems,
          )
        : Column(
            children: pageItems,
          );
  }
}
