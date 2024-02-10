import 'package:arche/arche.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:flutter/material.dart';

void pushMaterialRoute(
    {BuildContext? context, required WidgetBuilder builder}) {
  ArcheBus.bus.getLogger.info("pushMaterialRoute `$builder`");
  Navigator.of(context ?? viewKey.currentContext!)
      .push(MaterialPageRoute(builder: builder));
}
