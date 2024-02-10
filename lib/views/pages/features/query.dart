import 'package:cczu_helper/views/widgets/scrollable.dart';
import 'package:flutter/material.dart';

class QueryPage extends StatefulWidget {
  const QueryPage({super.key});

  @override
  State<StatefulWidget> createState() => _StateQueryPage();
}

class _StateQueryPage extends State<QueryPage> {
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
