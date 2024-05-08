import 'dart:async';

import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:cczu_helper/controllers/account.dart';
import 'package:cczu_helper/messages/account.pb.dart';
import 'package:cczu_helper/views/widgets/adaptive.dart';
import 'package:flutter/material.dart';
import 'package:rinf/rinf.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AccountLoginPage extends StatefulWidget {
  final bool autoLogin;
  final Function(BuildContext context) loginCallback;
  const AccountLoginPage(
      {super.key, this.autoLogin = true, required this.loginCallback});

  @override
  State<StatefulWidget> createState() => AccountLoginPageState();
}

class AccountLoginPageState extends State<AccountLoginPage> {
  late StreamSubscription<RustSignal<AccountLoginCallback>>
      _streamLoginCallback;

  late TextEditingController user;
  late TextEditingController password;
  bool _loginFailed = false;
  bool _underLogin = false;

  @override
  void initState() {
    super.initState();
    user = TextEditingController();
    password = TextEditingController();
    _streamLoginCallback =
        AccountLoginCallback.rustSignalStream.listen((event) {
      var message = event.message;
      _underLogin = false;

      if (message.ok) {
        writeAccount(message.account)
            .then((value) => widget.loginCallback(context));
        return;
      }

      ComplexDialog.instance.text(
        context: context,
        content: Text(message.error),
      );
      _loginFailed = true;
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    _streamLoginCallback.cancel();
    user.dispose();
    password.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget item = AdaptiveView(
      shrinkWrap: true,
      cardMargin: const EdgeInsets.only(top: 48, bottom: 48),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: Center(
                  child: Image.asset(
                    "assets/cczu_helper_icon.png",
                    width: 180,
                    height: 180,
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              TextField(
                controller: user,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                  labelText: "账户",
                  suffixIcon: IconButton(
                    onPressed: () {
                      ComplexDialog.instance.text(
                        content: const SelectableText(
                            "账户就是学号，密码是 一网通办/校园网登录/... 的密码，如果尚未激活账户请前往 http://sso.cczu.edu.cn/sso/active 进行激活"),
                        title: const Text("说明"),
                        context: context,
                      );
                    },
                    icon: const Icon(Icons.help),
                  ),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              ValueStateBuilder(
                builder: (context, state) {
                  return TextField(
                    controller: password,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      labelText: "密码",
                      suffixIcon: IconButton(
                        onPressed: () {
                          state.update(!state.value);
                        },
                        icon: const Icon(Icons.remove_red_eye),
                      ),
                    ),
                    obscureText: state.value,
                  );
                },
                init: true,
              ),
              const SizedBox(
                height: 32,
              ),
              FilledButton(
                  onPressed: () {
                    setState(() {
                      _loginFailed = false;
                      _underLogin = true;
                      AccountLogin(
                        user: user.text,
                        password: password.text,
                      ).sendSignalToRust(null);
                    });
                  },
                  child: const Text("登录")),
              const SizedBox(
                height: 8,
              ),
              OutlinedButton(
                onPressed: () => launchUrlString(
                    "http://sso.cczu.edu.cn/sso/active?type=getBack"),
                child: const Text("忘记密码"),
              ),
              const SizedBox(
                height: 8,
              ),
              TextButton(
                  onPressed: () {
                    ComplexDialog.instance
                        .confirm(
                            context: context,
                            title: const Text("跳过登录?"),
                            content: const Text(
                                "跳过登录可能影响某些功能的使用，跳过后，你仍可在设置页面登录你的账户。"))
                        .then((value) {
                      if (value) {
                        widget.loginCallback(context);
                      }
                    });
                  },
                  child: const Text("跳过")),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      body: AnimatedSwitcher(
        duration: Durations.medium4,
        child: FutureBuilder(
          future: tryReadAccount(),
          builder: (context, snapshot) {
            if (snapshot.hasData && !_underLogin) {
              var data = snapshot.data!;

              if (data.isSome()) {
                user.text = data.value!.user;
                password.text = data.value!.password;
              }

              if (data.isNull() || _loginFailed || !widget.autoLogin) {
                return item;
              }

              if (data.isSome() && !_loginFailed) {
                _underLogin = true;
                AccountLogin(
                  user: data.value!.user,
                  password: data.value!.password,
                ).sendSignalToRust(null);
              }
            }

            return const Center(child: ProgressIndicatorWidget());
          },
        ),
      ),
    );
  }
}
