import 'package:arche/arche.dart';
import 'package:cczu_helper/controllers/accounts.dart';
import 'package:cczu_helper/messages/all.dart';
import 'package:flutter/material.dart';

class WeChatRankServicePage extends StatefulWidget {
  const WeChatRankServicePage({super.key});

  @override
  State<StatefulWidget> createState() => WeChatRankServicePageState();
}

class WeChatRankServicePageState extends State<WeChatRankServicePage> {
  @override
  void initState() {
    super.initState();
    WeChatRankInput(
            account: ArcheBus.bus.of<MultiAccoutData>().getCurrentEduAccount())
        .sendSignalToRust();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: WeChatRankDataOutput.rustSignalStream,
        builder: (context, snapshot) {
          var signal = snapshot.data;
          if (signal == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          var message = signal.message;

          if (!message.ok) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(
                child: Text(message.error),
              ),
            );
          }
          var data = message.data;
          return Scaffold(
            appBar: AppBar(),
            body: ListView(
              children: [
                ListTile(
                  title: Text("绩点"),
                  trailing: Text(data.gpa),
                ),
                ListTile(
                  title: Text("总学分"),
                  trailing: Text(data.totalCredits),
                ),
                ListTile(
                  title: Text("排名"),
                  trailing: Text(data.rank),
                ),
                ListTile(
                  title: Text("专业排名"),
                  trailing: Text(data.majorRank),
                ),
              ],
            ),
          );
        });
  }
}
