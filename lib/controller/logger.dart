import 'package:cczu_helper/controller/bus.dart';
import 'package:flutter/material.dart';

late ApplicationLogger loggerCell;

class ApplicationLogger {
  List<String> logs = [];
  ApplicationLogger() {
    loggerCell = this;
  }

  static ApplicationLogger instance(BuildContext context) {
    return ApplicationBus.instance(context).logger;
  }

  ApplicationLogger log(dynamic msg) {
    var smsg = "${DateTime.now()} $msg";
    debugPrint(smsg);
    logs.insert(0, smsg);
    return this;
  }
}
