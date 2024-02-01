import 'package:arche/arche.dart';
import 'package:cczu_helper/models/fields.dart';
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

    var logger = ArcheBus().of<ArcheLogger>();
    try {
      var client = Dio();

      logger.info("访问 $checkInBaseUrl/check.ashx");
      logger.info((await client.post("$checkInBaseUrl/check.ashx",
              data: FormData.fromMap({"stuNo": stuid, "termID": termid})))
          .data);
      logger.info("访问 $checkInBaseUrl/result.aspx?sno=$stuid&tid=$termid");
      var text = (await client
              .get("$checkInBaseUrl/result.aspx?sno=$stuid&tid=$termid"))
          .data;
      var doc = parse(text);
      var data = doc
          .getElementsByTagName("td")
          .map((e) => e.text.toString().trim())
          .toList();
      logger.info(data.toString());
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
      logger.error(s);
      logger.error(e);

      Wakelock.disable();
      return null;
    }
  }
}
