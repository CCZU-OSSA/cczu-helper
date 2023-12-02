import 'package:cczu_helper/controller/config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ApplicationBus {
  final ApplicationConfig config = ApplicationConfig("app.config.json");

  static ApplicationBus instance(BuildContext context) {
    return Provider.of<ApplicationBus>(context, listen: false);
  }
}
