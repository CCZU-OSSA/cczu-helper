import 'package:cczu_helper/controller/bus.dart';
import 'package:cczu_helper/controller/logger.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart';
import 'package:wakelock/wakelock.dart';

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
    Wakelock.enable();
    try {
      var client = Dio();

      loggerCell.log("访问 ${busCell.baseurl}/check.ashx");
      loggerCell.log((await client.post("${busCell.baseurl}/check.ashx",
              data: FormData.fromMap({"stuNo": stuid, "termID": termid})))
          .data);
      loggerCell
          .log("访问 ${busCell.baseurl}/result.aspx?sno=$stuid&tid=$termid");
      var text = (await client
              .get("${busCell.baseurl}/result.aspx?sno=$stuid&tid=$termid"))
          .data;
      var doc = parse(text);
      var data = doc
          .getElementsByTagName("td")
          .map((e) => e.text.toString().trim())
          .toList();
      loggerCell.log(data);
      Wakelock.disable();

      if (data.length <= 16) {
        return null;
      }

      return CheckData(
        name: data[8],
        nowcount: data[10],
        stdcount: data[12],
        status: data[13],
      );
    } catch (e, s) {
      loggerCell.log(s);
      loggerCell.log(e);

      Wakelock.disable();
      return null;
    }
  }
}
