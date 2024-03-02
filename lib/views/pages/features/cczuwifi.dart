import 'package:cczu_helper/views/widgets/featureview.dart';
import 'package:cczu_helper/views/widgets/markdown.dart';
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
    return const FeatureView(
      primary: Card(
        child: SizedBox.expand(
          child: READMEWidget(resource: "resource"),
        ),
      ),
    );
  }
}
