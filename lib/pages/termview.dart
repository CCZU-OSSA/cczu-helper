import 'package:cczu_helper/models/terms.dart';
import 'package:flutter/material.dart';

class TermView extends StatelessWidget {
  const TermView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.exit_to_app)),
        title: const Text("学期(填右边的)"),
      ),
      body: FutureBuilder(
        future: TermData.fetch(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var data = snapshot.data!.terms;
            return ListView(
              children: List.generate(
                  data.length,
                  (index) => ListTile(
                        title: Text(data[index].name),
                        trailing: Text(data[index].val),
                      )),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
