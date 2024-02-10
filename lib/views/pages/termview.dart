import 'package:arche/arche.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:cczu_helper/models/terms.dart';
import 'package:flutter/material.dart';

class TermView extends StatelessWidget {
  const TermView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("学期"),
      ),
      body: FutureResolver(
        future: TermData.fetch(),
        loading: const Center(child: CircularProgressIndicator()),
        error: (stackTrace) => SingleChildScrollView(
            child: SizedBox(
                width: double.infinity, child: Text(stackTrace.toString()))),
        data: (value) => ListView(
          children: value!.terms
              .map(
                (e) => ListTile(
                  title: Text(e.name),
                  trailing: Text(e.val),
                  onTap: () {
                    ArcheBus().of<ApplicationConfigs>().termid.write(e.val);

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("切换至 ${e.name}(${e.val})"),
                      showCloseIcon: true,
                    ));
                    settingKey.currentState?.refresh();
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
