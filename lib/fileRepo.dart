

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class FileRepo {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<void> createFolder(String dir) async {
    final path = await _localPath;
    final directory = Directory("$path/$dir");

    if (await directory.exists()) {
      return;
    }

    await directory.create();
  }

  Future<File> getFile(String dir) async {
    final path = await _localPath;
    return File('$path/$dir');
  }

  Future<void> writeFile(String fileDir, String contents) async {
    final file = await getFile(fileDir);

    await file.writeAsString(contents);
  }

  Future<void> writeFileAsBytes(String fileDir, Uint8List contents) async {
    final file = await getFile(fileDir);

    await file.writeAsBytes(contents);

    print("WRITE: $fileDir");
  }

  Future<String> readFile(String fileDir) async {
    try {
      final file = await getFile(fileDir);

      final contents = file.readAsStringSync();

      return contents;
    } catch (e) {
      return "";
    }
  }

  Future<Uint8List> readFileAsBytes(String fileDir) async {
    try {
      final file = await getFile(fileDir);

      return file.readAsBytesSync();
    } catch (e) {
      print("error: $e");
      return Uint8List.fromList(List.empty());
    }
  }
}