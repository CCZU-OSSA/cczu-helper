import 'package:arche/arche.dart';
import 'package:cczu_helper/controllers/accounts.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/messages/all.dart';
import 'package:flutter/material.dart';

class AccountManagePage extends StatefulWidget {
  const AccountManagePage({
    super.key,
  });

  @override
  State<StatefulWidget> createState() => AccountManagePageState();
}

class AccountManagePageState extends State<AccountManagePage>
    with RefreshMountedStateMixin {
  Set<AccountType> accountType = const {AccountType.sso};

  @override
  Widget build(BuildContext context) {
    List<Widget> items = [];
    if (ArcheBus.bus.has<MultiAccoutData>()) {
      var colorScheme = Theme.of(context).colorScheme;
      var data = ArcheBus.bus.of<MultiAccoutData>();
      items = data.accounts[accountType.first.name]!
          .map(
            (element) => Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                leading: const Icon(Icons.person),
                tileColor: element.equal(data.current[accountType.first.name])
                    ? colorScheme.primaryContainer
                    : null,
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: colorScheme.primary),
                    borderRadius: const BorderRadius.all(Radius.circular(4))),
                onTap: () {
                  setState(() {
                    data.current[accountType.first.name] = element;
                    data.writeAccounts();
                  });
                },
                onLongPress: () {
                  pushMaterialRoute(
                    builder: (context) => AddAccountPage(
                      account: element,
                      accountType: accountType.first,
                      callback: refreshMounted,
                    ),
                  );
                },
                title: Text(element.user),
              ),
            ),
          )
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("账号管理"),
        actions: [
          SegmentedButton(
            segments: const [
              ButtonSegment(
                  value: AccountType.sso,
                  icon: Icon(Icons.school),
                  label: Text("一网通办")),
              ButtonSegment(
                  value: AccountType.edu,
                  icon: Icon(Icons.school),
                  label: Text("教务系统"))
            ],
            selected: accountType,
            onSelectionChanged: (value) {
              setState(() {
                accountType = value;
              });
            },
          ),
          const SizedBox(
            width: 8,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => pushMaterialRoute(
          builder: (context) => AddAccountPage(
            accountType: accountType.first,
            callback: refreshMounted,
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text("暂无账户"),
            )
          : ListView(
              key: ValueKey(accountType.first),
              children: items,
            ),
    );
  }
}

class AddAccountPage extends StatefulWidget {
  final AccountType accountType;
  final AccountData? account;
  final Function() callback;
  const AddAccountPage({
    super.key,
    this.accountType = AccountType.sso,
    this.account,
    required this.callback,
  });

  @override
  State<StatefulWidget> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  late TextEditingController user;
  late TextEditingController password;
  bool userError = false;
  bool passwordError = false;

  bool obscurePassword = true;
  @override
  void initState() {
    super.initState();
    AccountData account = AccountData(user: "", password: "");
    if (widget.account != null) {
      account = widget.account!;
    }
    user = TextEditingController(text: account.user);
    password = TextEditingController(text: account.password);
  }

  @override
  void dispose() {
    user.dispose();
    password.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var nav = Navigator.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account != null ? "编辑账户" : "添加账户"),
        actions: [
          Visibility(
            visible: widget.account != null,
            child: IconButton(
              onPressed: () {
                var data = ArcheBus.bus.of<MultiAccoutData>();
                data.deleteAccount(widget.account!, widget.accountType);
                data.writeAccounts().then((_) {
                  nav.pop();
                  widget.callback();
                });
              },
              icon: const Icon(Icons.delete),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (user.text.isEmpty || password.text.isEmpty) {
            setState(() {
              userError = user.text.isEmpty;
              passwordError = password.text.isEmpty;
            });
            return;
          }

          var data = ArcheBus.bus.provideof(instance: MultiAccoutData.template);

          var account = AccountData(
            user: user.text,
            password: password.text,
          );

          if (widget.account != null) {
            data.deleteAccount(widget.account!, widget.accountType);
          }
          data.addAccount(account, widget.accountType);
          data.current[widget.accountType.name] = account;

          data.writeAccounts().then((_) {
            nav.pop();
            widget.callback();
          });
        },
        child: const Icon(Icons.check),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              TextField(
                controller: user,
                onChanged: (value) {
                  if (userError) {
                    setState(() {
                      userError = false;
                    });
                  }
                },
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                  labelText: "账户",
                  errorText: userError ? "不能为空" : null,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              TextField(
                controller: password,
                onChanged: (value) {
                  if (passwordError) {
                    setState(() {
                      passwordError = false;
                    });
                  }
                },
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  errorText: passwordError ? "不能为空" : null,
                  labelText: "密码",
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: const Icon(Icons.visibility),
                  ),
                ),
                obscureText: obscurePassword,
              ),
              const SizedBox(
                height: 8,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("测试登录"),
                        content: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _LoginWidget(
                                  widget.accountType,
                                  AccountData(
                                      user: user.text,
                                      password: password.text)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text("测试登录"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginWidget extends StatefulWidget {
  final AccountType type;
  final AccountData account;
  const _LoginWidget(this.type, this.account);

  @override
  State<StatefulWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<_LoginWidget> {
  @override
  void initState() {
    super.initState();
    if (widget.type == AccountType.edu) {
      EDUAccountLoginInput(account: widget.account).sendSignalToRust();
    } else if (widget.type == AccountType.sso) {
      SSOAccountLoginInput(account: widget.account).sendSignalToRust();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: StreamBuilder(
        stream: AccountLoginCallback.rustSignalStream,
        builder: (context, snapshot) {
          var signal = snapshot.data;
          if (signal == null) {
            return const CircularProgressIndicator();
          }

          var message = signal.message;
          if (message.ok) {
            return const Icon(Icons.check);
          }

          return Text("${message.error} (可能由于网络问题导致，请多尝试)");
        },
      ),
    );
  }
}
