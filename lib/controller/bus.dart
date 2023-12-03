import 'package:cczu_helper/controller/config.dart';
import 'package:cczu_helper/controller/logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

late ApplicationBus busCell;

class ApplicationBus {
  final ApplicationLogger logger;
  final Config config;
  String baseurl = "http://202.195.100.156:808";
  ApplicationBus({required this.config, required this.logger}) {
    busCell = this;
  }

  static ApplicationBus instance(BuildContext context) {
    return Provider.of<ApplicationBus>(context, listen: false);
  }
}
