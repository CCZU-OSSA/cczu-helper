import 'dart:io';
import 'dart:typed_data';

import 'package:arche/extensions/io.dart';
import 'package:cczu_helper/controllers/config.dart';

Future<Directory> platCalendarDirectory() async =>
    (await platDirectory.getValue()).subDirectory("calendar").check();

Future<Stream<File>> listCalendarFiles() async =>
    (await platCalendarDirectory())
        .list()
        .where((event) => event.statSync().type == FileSystemEntityType.file)
        .map((event) => event as File);

Future<File> writeCalendarString(String name, String data) async =>
    await (await platCalendarDirectory()).subFile(name).writeAsString(data);

Future<File> writeCalendarBytes(String name, Uint8List data) async =>
    await (await platCalendarDirectory()).subFile(name).writeAsBytes(data);
