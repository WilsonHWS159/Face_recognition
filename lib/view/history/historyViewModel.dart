

import 'dart:typed_data';

import 'package:face_recognize/detectedDB.dart';
import 'package:face_recognize/fileRepo.dart';
import 'package:flutter/foundation.dart';


class HistoryViewData {
  String name;
  String note;
  List<HistoryViewSubData> subData;

  HistoryViewData(this.name, this.note, this.subData);
}

class HistoryViewSubData {
  Uint8List image;
  DateTime date;

  HistoryViewSubData(this.image, this.date);
}

class HistoryViewModel extends ChangeNotifier {


  List<HistoryViewData> data = List.empty(growable: true);

  DetectedDB _detectedDB = DetectedDB();

  HistoryViewModel() {
    load();
  }

  void load() async {
    await _detectedDB.loadData();

    await _updateData();

    notifyListeners();
  }

  void delete(String name) async {
    _detectedDB.deletePerson(name);

    await _updateData();

    notifyListeners();
  }

  void deleteSubData(String name, DateTime date) async {
    _detectedDB.deletePersonSubImage(name, date);

    await _updateData();

    notifyListeners();
  }

  void updateNote(String name, String newNote) async {
    _detectedDB.updatePersonNote(name, newNote);

    await _updateData();

    notifyListeners();
  }

  Future _updateData() async {
    data.clear();

    final fileRepo = FileRepo();

    for (final historyData in _detectedDB.historyPersonList) {

      List<HistoryViewSubData> subData = List.empty(growable: true);
      for (final feature in historyData.features) {
        subData.add(
          HistoryViewSubData(
              await fileRepo.readFileAsBytes(feature.imagePath),
              feature.date
          )
        );
          // images.add(await fileRepo.readFileAsBytes(feature.imagePath));
      }

      final viewData = HistoryViewData(
          historyData.name,
          historyData.note,
          subData
      );

      data.add(viewData);
    }
  }
}