import 'package:arche/arche.dart';
import 'package:cczu_helper/controllers/accounts.dart';
import 'package:cczu_helper/src/bindings/bindings.dart';
import 'package:cczu_helper/views/widgets/termpicker.dart';
import 'package:flutter/material.dart';

class WeChatExamQueryServicePage extends StatefulWidget {
  const WeChatExamQueryServicePage({super.key});

  @override
  State<StatefulWidget> createState() => WeChatExamQueryServicePageState();
}

class WeChatExamQueryServicePageState
    extends State<WeChatExamQueryServicePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("考试查询"),
      ),
      body: Column(
        children: [
          TermPicker(
            ensureAwake: true,
            builder: (term) => ListTile(
              title: Text(term == null ? "选择学期" : "当前学期: $term"),
              trailing: const Icon(Icons.arrow_drop_down),
            ),
            onChanged: (term) => WeChatExamsInput(
                    term: term,
                    account:
                        ArcheBus().of<MultiAccoutData>().getCurrentEduAccount())
                .sendSignalToRust(),
          ),
          Divider(),
          StreamBuilder(
              stream: WeChatExamsOutput.rustSignalStream,
              builder: (context, snapshot) {
                final data = snapshot.data;
                if (data == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!data.message.ok) {
                  return Center(
                    child: Text('Error: ${data.message.error}'),
                  );
                }

                return ListView(
                  shrinkWrap: true,
                  children: data.message.data
                      .map(
                        (e) => ListTile(
                          title: Text(e.name),
                          subtitle: Text('${e.location} ${e.date}'),
                        ),
                      )
                      .toList(),
                );
              })
        ],
      ),
    );
  }
}
