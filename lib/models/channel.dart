import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

const int channelTermview = 1;
const int channelLoginWifi = 2;
const int channelGenerateICalendar = 3;
const int channelCheckUpdate = 4;

abstract interface class Mappable {
  Map toMap();
}

extension JsonEncode on Mappable {
  String encode() => jsonEncode(toMap());
}

extension Encode on Map {
  String encode() => jsonEncode(this);
}

@immutable
class TermData {
  final String value;
  final String name;
  const TermData(this.value, this.name);
  static TermData fromMap(Map map) {
    return TermData(
      map["value"],
      map["name"],
    );
  }
}

@immutable
class AccountData {
  final String studentID;
  final String onetPassword;
  final String edusysPassword;
  const AccountData(this.studentID, this.onetPassword, this.edusysPassword);

  MapEntry<String, Map<String, String>> toMapEntry() {
    return MapEntry(
        studentID, {"eduspwd": edusysPassword, "onetpwd": onetPassword});
  }

  Map get protoEducationAccount =>
      {"username": studentID, "password": edusysPassword};
  Map get protoONetAccount => {"username": studentID, "password": onetPassword};
}

@immutable
class ICalendarGenerateData implements Mappable {
  final AccountData account;
  final String firstweekdate;

  final String reminder;
  const ICalendarGenerateData(
    this.account,
    this.firstweekdate,
    this.reminder,
  );

  @override
  Map toMap() => {
        "account": account.protoEducationAccount,
        "firstweekdate": firstweekdate,
        "reminder": reminder,
      };
}

mixin NativeChannelSubscriber {
  late StreamSubscription subscriber;
}
