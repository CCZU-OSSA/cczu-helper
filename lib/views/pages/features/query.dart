import 'package:cczu_helper/views/widgets/scrollable.dart';
import 'package:flutter/material.dart';

class QueryFeature extends StatefulWidget {
  const QueryFeature({super.key});

  @override
  State<StatefulWidget> createState() => QueryFeatureState();
}

class QueryFeatureState extends State<QueryFeature> {
  @override
  Widget build(BuildContext context) {
    return const PaddingScrollView(
      child: Column(
        children: [
          Card(
            child: Text("30/300"),
          )
        ],
      ),
    );
  }
}
