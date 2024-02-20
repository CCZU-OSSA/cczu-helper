import 'dart:io';

import 'package:arche/arche.dart';
import 'package:arche/extensions/functions.dart';
import 'package:arche/extensions/io.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

Future<void> saveFile(
  String data, {
  String? dialogTitle,
  required String fileName,
}) async {
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    return FilePicker.platform
        .saveFile(
          dialogTitle: dialogTitle,
          fileName: fileName,
        )
        .then((value) =>
            whenNotNull(value, (value) => File(value).writeAsString(data)));
  }

  return FilePicker.platform.getDirectoryPath(dialogTitle: dialogTitle).then(
        (value) => whenNotNull(
          value,
          (value) => Directory(value).subFile(fileName).writeAsString(data),
        ),
      );
}

Future<File> writeStringToPlatDirectory(String data,
    {required String filename}) async {
  var file = (await platDirectory.getValue()).subFile(filename);
  await file.writeAsString(data);
  return file.absolute;
}

bool isWideScreen(BuildContext context) {
  var size = MediaQuery.of(context).size;

  return size.width > size.height;
}

void saveLog() async {
  var logger = ArcheBus.logger;
  logger.info("saving logs... (${(await platDirectory.getValue()).path})");

  await writeStringToPlatDirectory(ArcheBus.logger.getLogs().join("\n"),
      filename: "${DateTime.now()}.log");
}
