import 'package:cczu_helper/models/fields.dart';
import 'package:flutter/material.dart';

void showSnackBar({
  required BuildContext context,
  Widget content = const SizedBox.shrink(),
}) {
  var messager = messagerKey.currentState!;
  messager.hideCurrentSnackBar();
  messager.showSnackBar(
    SnackBar(
      content: Center(child: content),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}
