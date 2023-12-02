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
  static Future<CheckData?> fetch(String stuid, String termid) async {
    var data = [];
    var len = 0;
    var ct = 0;
    while (len <= 16) {
      await Dio().get(
          "http://202.195.100.156:808/check.ashx?stuNo=$stuid&termID=$termid");
      var text = (await Dio().get(
              "http://202.195.100.156:808/result.aspx?sno=$stuid&tid=$termid"))
          .data;
      var doc = parse(text);
      data = doc
          .getElementsByTagName("td")
          .map((e) => e.text.toString().trim())
          .toList();
      len = data.length;
      debugPrint(data.toString());
      debugPrint(data.length.toString());
      if (ct++ == 10) {
        return null;
      }
    }

    return CheckData(
      name: data[8],
      nowcount: data[10],
      stdcount: data[12],
      status: data[13],
    );
  }
}
