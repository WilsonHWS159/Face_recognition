

import 'dart:io';
import 'dart:typed_data';

import 'package:face_recognize/detectedDB.dart';
import 'package:face_recognize/fileRepo.dart';
import 'package:flutter/foundation.dart';

import 'package:image/image.dart' as imglib;


class HistoryViewData {
  String name;
  Uint8List image;

  HistoryViewData(this.name, this.image);
}

class HistoryViewModel extends ChangeNotifier {


  List<HistoryViewData> data = List.empty(growable: true);

  DetectedDB _detectedDB = DetectedDB();

  HistoryViewModel() {
    load();
  }

  void load() async {
    await _detectedDB.loadData();

    final fileRepo = FileRepo();

    for (final historyData in _detectedDB.historyPersonList) {

      final viewData = HistoryViewData(
          historyData.name,
          await fileRepo.readFileAsBytes(historyData.imagePath)
      );

      data.add(viewData);
    }

    notifyListeners();
  }
}