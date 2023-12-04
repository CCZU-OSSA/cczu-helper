import 'package:cczu_helper/controller/bus.dart';
import 'package:cczu_helper/controller/logger.dart';
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
    var data = TermData();
    var client = Dio();
    loggerCell.log("访问 ${busCell.baseurl}");
    var doc = parse((await client.get(busCell.baseurl)).data.toString());
    doc.getElementsByTagName("option").forEach((element) {
      data.terms.add(Term(element.attributes["value"].toString(),
          element.text.toString().trim()));
    });
    return data;
  }
}
