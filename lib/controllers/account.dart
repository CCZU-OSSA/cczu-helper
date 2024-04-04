import 'dart:convert';
import 'dart:io';

import 'package:arche/extensions/io.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/messages/account.pb.dart';

Future<File> platAccountFile() async =>
    (await platDirectory.getValue()).subFile("account.json");

Future<bool> hasAccount() async {
  return await (await platAccountFile()).exists();
}

Future<void> deleteAccount() async {
  await (await platAccountFile()).delete();
}

Future<void> writeAccount(AccountWithCookies account) async {
  await (await platAccountFile()).writeAsString(account.json());
}

Future<void> saveAccountLoginCallback(AccountLoginCallback callback) async {
  await writeAccount(callback.account);
}

Future<AccountWithCookies?> readAccount() async {
  var account = await platAccountFile();
  if (!await account.exists()) {
    return null;
  }

  var map = jsonDecode(await account.readAsString());

  return AccountWithCookies(
    user: map["user"],
    password: map["password"],
    cookies: map["cookies"],
  );
}

extension AccountWithCookiesSerialize on AccountWithCookies {
  Map toMap() {
    return {
      "user": user,
      "password": password,
      "cookies": cookies,
    };
  }

  String json() {
    return jsonEncode(toMap());
  }
}
