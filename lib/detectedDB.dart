

import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:face_recognize/fileRepo.dart';

import 'package:image/image.dart' as imglib;


class PersonData {
  List featureVector;
  String name;
  String imagePath;
  // Face? face;

  String _uid;
  String get uid => _uid;

  PersonData(this.featureVector, this.name, this.imagePath, this._uid);

}

class DetectedDB {
  static const double THRESHOLD = 1.0;

  List<PersonData> historyPersonList = List.empty(growable: true);

  Future<void> loadData() async {
    final dataStr = await FileRepo().readFile("saved_data");
    List<dynamic> dataJson = json.decode(dataStr);

    for (final data in dataJson) {
      final name = data["name"] as String;
      final featureVector = data["featureVector"] as List;
      final path = data["imagePath"] as String;

      final person = PersonData(featureVector, name, path, "123");

      historyPersonList.add(person);

      print("load from db, path: ${path}");

    }

    print("load from db, total: ${historyPersonList.length}");

  }

  void addPerson(List data, String name, imglib.Image image) {

    final path = "image_$name";

    FileRepo().writeFileAsBytes(path, imglib.encodePng(image) as Uint8List);

    final newData = PersonData(data, name, path, name);

    historyPersonList.add(newData);

    // FileIma

    List<Map<String, dynamic>> dataJson = List.empty(growable: true);
    for (final person in historyPersonList) {
      dataJson.add({
        "name": person.name,
        "featureVector": person.featureVector,
        "imagePath": person.imagePath
      });
    }

    final dataStr = json.encode(dataJson);

    print("save str: $dataStr");

    FileRepo().writeFile("saved_data", dataStr);
  }

  PersonData? findClosestFace(List data) {
    double minDist = 999;
    double currDist = 999;
    PersonData? predictedResult;

    for (final history in historyPersonList) {
      currDist = _euclideanDistance(history.featureVector, data);
      if (currDist <= THRESHOLD && currDist < minDist) {
        minDist = currDist;
        predictedResult = history;
      }
    }

    return predictedResult;
  }

  double _euclideanDistance(List e1, List e2) {
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow((e1[i] - e2[i]), 2);
    }
    return sqrt(sum);
  }
}