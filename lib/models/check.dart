import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';

class CheckData {
  String status;
  String name;
  String stdcount;
  String nowcount;
  CheckData({
    required this.name,
    required this.status,
    required this.nowcount,
    required this.stdcount,
  });
  static Future<CheckData> fetch(String stuid, String termid) async {
    var data = [];

    while (data.length < 16) {
      await Dio().get(
          "http://202.195.100.156:808/check.ashx?stuNo=$stuid&termID=$termid");
      var doc = parse((await Dio().get(
              "http://202.195.100.156:808/result.aspx?sno=$stuid&tid=$termid"))
          .data);
      var data = doc
          .getElementsByTagName("td")
          .map((e) => e.text.toString().trim())
          .toList();
      debugPrint(data.toString());
      debugPrint(data.length.toString());
    }

    return CheckData(
      name: data[8],
      nowcount: "0",
      stdcount: data[9],
      status: data[13],
    );
  }
}
