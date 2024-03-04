import 'package:flutter/material.dart';

void showSnackBar({
  required BuildContext context,
  Widget content = const SizedBox.shrink(),
}) {
  var messager = ScaffoldMessenger.of(context);
  messager.hideCurrentSnackBar();
  messager.showSnackBar(
    SnackBar(
      content: Center(child: content),
      behavior: SnackBarBehavior.floating,
      showCloseIcon: true,
    ),
  );
}
