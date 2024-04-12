import 'dart:async';

import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:cczu_helper/controllers/account.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/controllers/platform.dart';
import 'package:cczu_helper/main.dart';
import 'package:cczu_helper/messages/account.pb.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:flutter/material.dart';
import 'package:rinf/rinf.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AccountLoginPage extends StatefulWidget {
  const AccountLoginPage({super.key});

  @override
  State<StatefulWidget> createState() => AccountLoginPageState();
}

class AccountLoginPageState extends State<AccountLoginPage> {
  late StreamSubscription<RustSignal<AccountLoginCallback>>
      _streamLoginCallback;

  late TextEditingController user;
  late TextEditingController password;
  bool _obscurePasswordText = true;
  bool _loginFailed = false;
  bool _underLogin = false;

  @override
  void initState() {
    super.initState();
    _streamLoginCallback =
        AccountLoginCallback.rustSignalStream.listen((event) {
      var message = event.message;

      if (message.ok) {
        writeAccount(message.account).then(
          (value) => pushMaterialRoute(
            context: context,
            builder: (context) => MainView(
              key: viewKey,
            ),
          ),
        );
      } else {
        ComplexDialog.instance.text(
          context: context,
          content: Text(message.error),
        );
        setState(() {
          _underLogin = false;
          _loginFailed = true;
        });
      }
    });

    user = TextEditingController();
    password = TextEditingController();
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
    Widget item;

    item = Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
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
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
              labelText: "账户",
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          TextField(
            controller: password,
            decoration: InputDecoration(
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                labelText: "密码",
                suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePasswordText = !_obscurePasswordText;
                      });
                    },
                    icon: const Icon(Icons.remove_red_eye))),
            obscureText: _obscurePasswordText,
          ),
          const SizedBox(
            height: 32,
          ),
          FilledButton(
              onPressed: () {
                _loginFailed = false;
                _underLogin = true;
                setState(() {
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
        ],
      ),
    );
    if (isWideScreen(context)) {
      item = Row(
        children: [
          const Flexible(
            flex: 4,
            child: SizedBox.expand(),
          ),
          Flexible(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Card(
                child: item,
              ),
            ),
          ),
          const Flexible(
            flex: 4,
            child: SizedBox.expand(),
          ),
        ],
      );
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: Durations.medium4,
        child: FutureBuilder(
          future: hasAccount(),
          builder: (context, snapshot) {
            if (snapshot.data != true || _loginFailed) {
              return item;
            }

            if (snapshot.data == true && !_underLogin) {
              _underLogin = true;
              _loginFailed = false;
              readAccount().then((account) {
                if (account != null) {
                  setState(() {
                    user = TextEditingController(text: account.user);
                    password = TextEditingController(text: account.password);
                    AccountLogin(user: account.user, password: account.password)
                        .sendSignalToRust(null);
                  });
                } else {
                  _underLogin = false;
                }
              });
            }

            return const Center(child: ProgressIndicatorWidget());
          },
        ),
      ),
    );
  }
}
