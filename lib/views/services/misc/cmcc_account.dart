import 'dart:async';
import 'dart:io';

import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:cczu_helper/messages/all.dart';
import 'package:cczu_helper/views/widgets/adaptive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:rinf/rinf.dart';

class CMCCAccoutService extends StatefulWidget {
  const CMCCAccoutService({super.key});

  @override
  State<StatefulWidget> createState() => CMCCAccountServiceState();
}

class CMCCAccountServiceState extends State<CMCCAccoutService> {
  late TextEditingController _phoneTextController;
  late TextEditingController _pwdTextController;
  late TextEditingController _nameTextController;

  late StreamSubscription<RustSignal<CMCCAccountGenerateOutput>>
      _streamAccountGenerateOutput;
  bool _existError = false;
  bool _generatebat = true;
  @override
  void initState() {
    super.initState();
    _phoneTextController = TextEditingController();
    _pwdTextController = TextEditingController();
    _nameTextController = TextEditingController(text: "Band Connection");
    _streamAccountGenerateOutput =
        CMCCAccountGenerateOutput.rustSignalStream.listen((event) {
      var message = event.message;

      if (!mounted) {
        return;
      }

      ComplexDialog.instance.text(
        title: const Text("成功! 请复制保存!"),
        context: context,
        content: SelectableText(message.account),
      );
      if (_generatebat) {
        FilePicker.platform.saveFile(
          fileName: "一键拨号连接.bat",
          type: FileType.custom,
          allowedExtensions: [".bat"],
        ).then((path) async {
          if (path != null) {
            await File(path).writeAsString(
                "@rasdial \"${_nameTextController.text}\" ${message.account} ${_pwdTextController.text}");
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _phoneTextController.dispose();
    _pwdTextController.dispose();
    _nameTextController.dispose();
    _streamAccountGenerateOutput.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("生成CMCC宽带拨号账户"),
      ),
      body: AdaptiveView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () {
                ComplexDialog.instance.text(
                  title: const Text("说明"),
                  content: const SelectableText("""
此功能受GUID所限制，仅适用于Windows端，如果你是Mac/Linux用户想必你早已向客服说明将账户改为你的手机号。

这个功能是用来取代移动的上网助手的，上网助手的通过加密账户(PPPoE拨号账户)创建宽带连接，而这个功能将会直接给你PPPoE拨号账户进行取舍。

如果你想方便点，建议勾选`生成一键上网脚本`并提供上网助手的密码，保存好`bat`文件之后，每次连接仅需运行这个文件即可。
如果你不知道密码是什么可以通过向`10086`发送`重置密码`来获取/重置你的密码。

如果你想自行连接而不是使用脚本，可以自行搜索`PPPoE宽带连接`的相关教程。

宽带连接名称仅用于显示在本地电脑，因此无论叫`Ciallo～(∠・ω< )⌒★`还是叫`宽带连接`都无所谓，不过请不要留空。
(据说不使用纯英文可能会出现代理软件失效的情况，所以默认设置为`Band Connection`)

如果你想用于路由器可以参考下方这个文档，账户可以通过这个功能生成，祝你有美好的一天~
https://cczu-ossa.github.io/home/pdf/cczu-cmcc-router.pdf
"""),
                  context: context,
                );
              },
              icon: const Icon(Icons.help),
              label: const Text("说明"),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: _phoneTextController,
                onChanged: (value) {
                  if (_existError) {
                    setState(() {
                      _existError = false;
                    });
                  }
                },
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: "手机号",
                  prefixIcon: const Icon(Icons.phone),
                  errorText: _existError ? "请输入11位手机号" : null,
                ),
                autofocus: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.all(4),
                initiallyExpanded: true,
                title: const Text("生成一键上网脚本"),
                leading: Checkbox(
                  value: _generatebat,
                  onChanged: (value) => setState(() {
                    _generatebat = value ?? false;
                  }),
                ),
                shape: const RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.all(Radius.circular(4))),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: TextField(
                      controller: _pwdTextController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "密码",
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: TextField(
                      controller: _nameTextController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "连接名称",
                        prefixIcon: Icon(Icons.abc),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () {
                    _existError = _phoneTextController.text.length != 11;
                    if (_existError) {
                      setState(() {});
                    } else {
                      CMCCAccountGenerateInput(phone: _phoneTextController.text)
                          .sendSignalToRust();
                    }
                  },
                  child: const Text("生成"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
