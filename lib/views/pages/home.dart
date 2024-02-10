import 'package:cczu_helper/views/widgets/scrollable.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PaddingScrollView(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Card(
              child: SizedBox(
                width: double.infinity,
                height: 120,
              ),
            ),
          )
        ],
      ),
    );
  }
}
