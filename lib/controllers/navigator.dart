import 'package:arche/arche.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:flutter/material.dart';

Future<T?> pushMaterialRoute<T extends Object?>(
    {BuildContext? context, required WidgetBuilder builder}) {
  ArcheBus.bus.getLogger.info("pushMaterialRoute `$builder`");
  return Navigator.of(context ?? viewKey.currentContext!)
      .push<T>(MaterialPageRoute(builder: builder));
}
