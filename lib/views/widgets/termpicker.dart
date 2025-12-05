import 'dart:async';

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
  String? term;
  @override
  void initState() {
    super.initState();
    if (widget.ensureAwake) {
      late final StreamSubscription listener;
      listener = WeChatTermsOutput.rustSignalStream.listen((data) {
        widget.onChanged(data.message.terms.first);
        setState(() {
          terms = data.message.terms;
          term = data.message.terms.first;
        });
        listener.cancel();
      });

      WeChatTermsInput().sendSignalToRust();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      key: termPopMenuKey,
      onSelected: (value) => setState(() {
        term = value;
        widget.onChanged(value);
      }),
      itemBuilder: (context) {
        if (terms == null || terms!.isEmpty) {
          WeChatTermsOutput.rustSignalStream.listen((data) {
            terms = (data.message.terms);
            termPopMenuKey.currentState?.showButtonMenu();
          });

          WeChatTermsInput().sendSignalToRust();
          terms = [];
        }

        return terms!
            .map((term) => PopupMenuItem(value: term, child: Text(term)))
            .toList();
      },
      child: widget.builder(term),
    );
  }
}
