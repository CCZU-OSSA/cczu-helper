import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/snackbar.dart';
import 'package:cczu_helper/messages/common.pb.dart';
import 'package:cczu_helper/models/channel.dart';
import 'package:cczu_helper/views/widgets/featureview.dart';
import 'package:cczu_helper/views/widgets/markdown.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CCZUWifiFeature extends StatefulWidget {
  const CCZUWifiFeature({super.key});

  @override
  State<StatefulWidget> createState() => _CCZUWifiFeatureState();
}

class _CCZUWifiFeatureState extends State<CCZUWifiFeature>
    with NativeChannelSubscriber {
  bool _busy = false;
  @override
  void initState() {
    super.initState();

    subscriber = DartReceiveChannel.rustSignalStream.listen((event) {
      setState(() {
        _busy = false;
      });
      var message = event.message;

      if (message.ok) {
        ComplexDialog.instance
            .text(context: context, content: const Text("登录成功！"));
      } else {
        ComplexDialog.instance.text(
            context: context,
            title: const Text("确认接入校园网?"),
            content: Text(message.data));
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    subscriber.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Durations.medium4,
      child: _busy
          ? const Center(
              child: ProgressIndicatorWidget(
                data: ProgressIndicatorWidgetData(text: "正在登陆中..."),
              ),
            )
          : Scaffold(
              floatingActionButton: FloatingActionButton(
                child: const Icon(Icons.wifi),
                onPressed: () async {
                  var account = ArcheBus()
                      .of<ApplicationConfigs>()
                      .currentAccount
                      .tryGet();
                  if (account == null) {
                    showSnackBar(
                      context: context,
                      content: const Text("请先在设置中添加并选择账户"),
                    );
                    return;
                  }

                  if (_busy) {
                    return;
                  }

                  setState(
                    () {
                      _busy = true;
                    },
                  );

                  RustCallChannel(
                    id: channelLoginWifi,
                    data: (await account).protoONetAccount.encode(),
                  ).sendSignalToRust(null);
                },
              ),
              body: FeatureView(
                primary: const Card(
                  child: SizedBox.expand(
                    child: READMEWidget(resource: "assets/README_CCZUWIFI.md"),
                  ),
                ),
                secondary: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.account_circle),
                        onPressed: () => launchUrlString(
                            "http://sso.cczu.edu.cn/sso/active"),
                        label: const SizedBox(
                          width: double.infinity,
                          child: Center(
                            child: Text("激活账户"),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
