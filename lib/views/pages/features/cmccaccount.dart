import 'package:cczu_helper/views/widgets/featureview.dart';
import 'package:flutter/material.dart';

class CMCCAccountFeature extends StatefulWidget {
  const CMCCAccountFeature({super.key});

  @override
  State<StatefulWidget> createState() => CMCCAccountFeatureState();
}

class CMCCAccountFeatureState extends State<CMCCAccountFeature> {
  @override
  Widget build(BuildContext context) {
    return FeatureView(primary: const Card(
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Padding(
                padding: EdgeInsets.all(36),
                child: Column(children: [
                  Text(
                    "114/514",
                    style: TextStyle(fontSize: 24),
                  ),
                  Text(
                    "最后更新日期 2077/7/21",
                    style: TextStyle(fontSize: 8),
                  ),
                ]),
              ),
            ),
          ),
        ),);
  }
}
