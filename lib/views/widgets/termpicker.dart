import 'dart:async';

import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:cczu_helper/src/bindings/signals/signals.dart';
import 'package:flutter/material.dart';

class TermPicker extends StatefulWidget {
  final Widget Function(String? term) builder;
  final Function(String term) onChanged;
  final bool ensureAwake;
  const TermPicker({
    super.key,
    required this.builder,
    required this.onChanged,
    this.ensureAwake = false,
  });

  @override
  State<StatefulWidget> createState() => _TermPickerState();
}

class _TermPickerState extends State<TermPicker> {
  final termPopMenuKey = GlobalKey<PopupMenuButtonState>();
  List<String>? terms;
  late final StreamSubscription listener;
  String? term;
  @override
  void initState() {
    super.initState();
    if (widget.ensureAwake) {
      listener = WeChatTermsOutput.rustSignalStream.listen((data) {
        if (data.message.terms.isEmpty) {
          if (viewKey.currentContext != null) {
            ComplexDialog.instance.text(
                title: Text("Error"),
                context: viewKey.currentContext,
                content: Text(
                    "Failed to get terms: ${data.message.error}, please check connection and reopen"));
          }
          return;
        }

        widget.onChanged(data.message.terms.first);
        setState(() {
          terms = data.message.terms;
          term = data.message.terms.first;
        });
      });

      WeChatTermsInput().sendSignalToRust();
    }
  }

  @override
  void dispose() {
    super.dispose();
    listener.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      key: termPopMenuKey,
      onSelected: (value) => setState(() {
        term = value;
        widget.onChanged(value);
      }),
      onOpened: () {
        if (terms?.isEmpty ?? true) {
          WeChatTermsInput().sendSignalToRust();
        }
      },
      itemBuilder: (context) {
        if (terms == null) {
          return [
            PopupMenuItem(
              enabled: false,
              child: CircularProgressIndicator(),
            )
          ];
        }

        return terms!
            .map((term) => PopupMenuItem(value: term, child: Text(term)))
            .toList();
      },
      child: widget.builder(term),
    );
  }
}
