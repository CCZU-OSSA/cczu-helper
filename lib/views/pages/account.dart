import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:arche/extensions/iter.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:cczu_helper/models/typedata.dart';
import 'package:flutter/material.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<StatefulWidget> createState() => AccountPageState();
}

class AccountPageState extends State<AccountPage> {
  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    var currentAccountNameCfg =
        ArcheBus.bus.of<ApplicationConfigs>().currentAccountName;

    var currentAccount = currentAccountNameCfg.tryGet();

    return Scaffold(
      appBar: AppBar(
        title: const Text("账户"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => pushMaterialRoute<dynamic>(
          builder: (context) => const AccountLoginPage(),
        ),
        child: const Icon(Icons.add),
      ),
      body: AccountManager.accounts.widgetBuilder(
        refresh: true,
        (context, snapshot) {
          if (snapshot.hasData) {
            return ListView(
              children: snapshot.data!.entries
                  .map<Widget>(
                    (e) => GestureDetector(
                      onLongPress: () => pushMaterialRoute(
                        builder: (context) => AccountLoginPage(
                          data: e.value,
                        ),
                      ),
                      child: RadioListTile(
                        groupValue: currentAccount,
                        value: e.key,
                        title: Text(e.key),
                        onChanged: (String? value) {
                          setState(() {
                            currentAccountNameCfg.write(e.key);
                          });
                        },
                      ),
                    ),
                  )
                  .toList(),
            );
          }
          return const Center(
            child: ProgressIndicatorWidget(),
          );
        },
      ),
    );
  }
}

class AccountLoginPage extends StatefulWidget {
  final AccountData? data;
  const AccountLoginPage({
    super.key,
    this.data,
  });

  @override
  State<StatefulWidget> createState() => _AccountLoginPageState();
}

class _AccountLoginPageState extends State<AccountLoginPage> {
  late TextEditingController stuid;
  late TextEditingController onetpwd;
  late TextEditingController eduspwd;
  @override
  void initState() {
    super.initState();
    stuid = TextEditingController(text: widget.data?.studentID);
    onetpwd = TextEditingController(text: widget.data?.onetPassword);
    eduspwd = TextEditingController(text: widget.data?.edusysPassword);
  }

  @override
  void dispose() {
    super.dispose();
    stuid.dispose();
    onetpwd.dispose();
    eduspwd.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("账户"),
        actions: [
          Visibility(
            visible: widget.data != null,
            child: IconButton(
              onPressed: () {
                ComplexDialog.instance
                    .confirm(
                  title: const Text("确认"),
                  content: const Text("是否要删除此账户?"),
                  context: context,
                )
                    .then((value) {
                  if (value) {
                    AccountManager.accountsStored.getValue().then((value) {
                      value.delete(widget.data!.studentID);
                      var cfg = ArcheBus.bus
                          .of<ApplicationConfigs>()
                          .currentAccountName;
                      if (cfg.tryGet() == widget.data!.studentID) {
                        cfg.delete();
                      }

                      accountKey.currentState?.refresh();
                      Navigator.of(context).pop();
                    });
                  }
                });
              },
              icon: const Icon(Icons.delete),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            TextField(
              controller: stuid,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), labelText: "学号"),
            ),
            TextField(
              controller: eduspwd,
              obscureText: true,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), labelText: "教务密码"),
            ),
            TextField(
              controller: onetpwd,
              obscureText: true,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), labelText: "一网通密码"),
            ),
          ].joinElement(
            const SizedBox(
              height: 8,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.check),
          onPressed: () {
            if (stuid.text.isNotEmpty) {
              var data = AccountData(stuid.text, onetpwd.text, eduspwd.text)
                  .toMapEntry();
              AccountManager.accountsStored.getValue().then((value) {
                if (widget.data != null) {
                  value.delete(widget.data!.studentID);
                }
                value.write(data.key, data.value);
                ArcheBus.bus
                    .of<ApplicationConfigs>()
                    .currentAccountName
                    .write(data.key);
                accountKey.currentState?.refresh();
                Navigator.of(context).pop();
              });
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("学号不可留空"),
              ),
            );
          }),
    );
  }
}
