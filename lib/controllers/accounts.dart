import 'dart:convert';
import 'dart:io';

import 'package:arche/arche.dart';
import 'package:arche/extensions/io.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/messages/all.dart';

extension MapSerializer on AccountData {
  Map toMap() {
    return {"user": user, "passward": password};
  }

  static AccountData fromMap(Map data) {
    return AccountData(user: data["user"], password: data["passward"]);
  }
}

extension PartialEq on AccountData {
  bool equal(AccountData? other) => other != null && user == other.user;
}

enum AccountType { sso, edu }

class MultiAccoutData {
  Map<String, List<AccountData>> accounts;
  Map<String, AccountData?> current;
  static final AccountData _empty = AccountData(user: "", password: "");

  MultiAccoutData({required this.current, required this.accounts});

  static MultiAccoutData fromMap(Map data) {
    return MultiAccoutData(
        current: (data["current"] as Map).map(
            (k, v) => MapEntry(k, v == null ? null : MapSerializer.fromMap(v))),
        accounts: (data["accounts"] as Map).map((k, v) => MapEntry(
            k, (v as List).map((e) => MapSerializer.fromMap(e)).toList())));
  }

  Map toMap() => {
        "current": current.map((key, value) => MapEntry(key, value?.toMap())),
        "accounts": accounts.map(
            (key, value) => MapEntry(key, value.map((e) => e.toMap()).toList()))
      };

  static MultiAccoutData get template => MultiAccoutData(
      current: {AccountType.sso.name: null, AccountType.edu.name: null},
      accounts: {AccountType.sso.name: [], AccountType.edu.name: []});

  List<AccountData> getAccounts(AccountType type) {
    return accounts[type.name]!;
  }

  AccountData? getCurrentAccount(AccountType type) {
    return current[type.name];
  }

  AccountData getCurrentSSOAccount() => current[AccountType.sso.name] ?? _empty;
  AccountData getCurrentEduAccount() => current[AccountType.edu.name] ?? _empty;
  bool hasCurrentSSOAccount() => current[AccountType.sso.name] != null;
  bool hasCurrentEduAccount() => current[AccountType.edu.name] != null;

  List<AccountData> getSSOAccounts() => getAccounts(AccountType.sso);
  List<AccountData> getEduAccounts() => getAccounts(AccountType.edu);

  MultiAccoutData addAccount(AccountData data, AccountType type) {
    if (!hasAccount(data, type)) {
      accounts[type.name]!.add(data);
    }

    return this;
  }

  MultiAccoutData addSSOAccount(AccountData data) =>
      addAccount(data, AccountType.sso);

  MultiAccoutData addEduAccount(AccountData data) =>
      addAccount(data, AccountType.edu);

  bool hasAccount(AccountData data, AccountType type) {
    for (var account in accounts[type.name]!) {
      if (account.equal(data)) {
        return true;
      }
    }
    return false;
  }

  bool hasSSOAccount(AccountData data) => hasAccount(data, AccountType.sso);
  bool hasEduAccount(AccountData data) => hasAccount(data, AccountType.edu);

  void deleteAccount(AccountData data, AccountType type) {
    accounts[type.name] =
        accounts[type.name]!.where((account) => !account.equal(data)).toList();
    if (current[type.name] != null && current[type.name]!.equal(data)) {
      current[type.name] = null;
    }
  }

  void deleteSSOAccount(AccountData data) =>
      deleteAccount(data, AccountType.sso);

  void deleteEduAccount(AccountData data) =>
      deleteAccount(data, AccountType.edu);

  static Future<File> platAccountsFile() async =>
      (await platUserDataDirectory.getValue()).subFile("accounts.json");

  static Future<bool> hasAccountsFile() async {
    return await (await platAccountsFile()).exists();
  }

  static Future<void> deleteAccountsFile() async {
    await (await platAccountsFile()).delete();
  }

  Future<void> writeAccounts() async {
    await (await platAccountsFile()).writeAsString(jsonEncode(toMap()));
  }

  static Future<MultiAccoutData?> readAccounts() async {
    var account = await platAccountsFile();
    if (!await account.exists()) {
      return null;
    }

    return fromMap(jsonDecode(await account.readAsString()));
  }

  static Future<Optional<MultiAccoutData>> tryReadAccounts() async {
    var data = await readAccounts();
    if (data == null) {
      return const Optional.none();
    }

    return Optional(value: data);
  }
}
