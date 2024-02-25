import 'package:cczu_helper/controllers/platform.dart';
import 'package:flutter/material.dart';

class CurriculumPage extends StatefulWidget {
  const CurriculumPage({super.key});

  @override
  State<StatefulWidget> createState() => CurriculumPageState();
}

class CurriculumPageState extends State<CurriculumPage> {
  @override
  Widget build(BuildContext context) {
    var widescreen = isWideScreen(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: List.generate(
            10,
            (index) => Padding(
              padding: const EdgeInsets.all(8),
              child: Card(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 60,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: FittedBox(
                        child: Text("Rust程序设计语言"),
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text("时间"),
                    subtitle: Visibility(
                      visible: !widescreen,
                      child: const Text("114~514"),
                    ),
                    trailing: Visibility(
                      visible: widescreen,
                      child: const Text("114~514"),
                    ),
                  ),
                  ListTile(
                    title: const Text("地点"),
                    subtitle: Visibility(
                      visible: !widescreen,
                      child: const Text("CCZU"),
                    ),
                    trailing: Visibility(
                      visible: widescreen,
                      child: const Text("CCZU"),
                    ),
                  )
                ],
              )),
            ),
          ),
        ),
      ),
    );
  }
}
