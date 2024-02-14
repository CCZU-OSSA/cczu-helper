import 'dart:io';

import 'package:arche/extensions/functions.dart';
import 'package:arche/extensions/io.dart';
import 'package:file_picker/file_picker.dart';

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
