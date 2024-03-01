import 'package:cczu_helper/messages/common.pb.dart';
import 'package:flutter/material.dart';

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

  ProtoAccountData get protoEduS =>
      ProtoAccountData(username: studentID, password: edusysPassword);
  ProtoAccountData get protoONet =>
      ProtoAccountData(username: studentID, password: onetPassword);
}
