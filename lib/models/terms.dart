import 'package:arche/arche.dart';
import 'package:cczu_helper/models/fields.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart';

class Term {
  String val;
  String name;
  Term(this.val, this.name);
}

class TermData {
  List<Term> terms = [];

  static Future<TermData> fetch() async {
    var logger = ArcheBus.logger;
    var data = TermData();
    var client = Dio();
    logger.info("访问 $checkInBaseUrl");
    var doc = parse((await client.get(checkInBaseUrl)).data.toString());
    doc.getElementsByTagName("option").forEach((element) {
      data.terms.add(Term(element.attributes["value"].toString(),
          element.text.toString().trim()));
    });
    return data;
  }
}
