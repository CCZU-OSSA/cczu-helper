import 'package:cczu_helper/controller/logger.dart';
import 'package:dio/dio.dart';
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
    loggerCell.log(
        "访问 http://202.195.100.156:808/check.ashx?stuNo=$stuid&termID=$termid");
    await Dio().get(
        "http://202.195.100.156:808/check.ashx?stuNo=$stuid&termID=$termid");
    loggerCell.log(
        "访问 http://202.195.100.156:808/result.aspx?sno=$stuid&tid=$termid");
    var text = (await Dio().get(
            "http://202.195.100.156:808/result.aspx?sno=$stuid&tid=$termid"))
        .data;
    var doc = parse(text);
    var data = doc
        .getElementsByTagName("td")
        .map((e) => e.text.toString().trim())
        .toList();
    loggerCell.log(data);
    if (data.length <= 16) {
      return null;
    }

    return CheckData(
      name: data[8],
      nowcount: data[10],
      stdcount: data[12],
      status: data[13],
    );
  }
}
