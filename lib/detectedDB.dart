

import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';


import 'package:face_recognize/fileRepo.dart';

import 'package:image/image.dart' as imglib;
import 'package:intl/intl.dart';


class ImageAndFeature {
  String imagePath;
  DateTime date;
  List featureVector;

  ImageAndFeature(this.imagePath, this.date, this.featureVector);
}

class PersonData {
  String name;
  String note;
  List<ImageAndFeature> features;

  String _uid;
  String get uid => _uid;

  PersonData(this.name, this.note, this.features, this._uid);

}

class DetectedDB {
  static const double THRESHOLD = 1.0;

  List<PersonData> historyPersonList = List.empty(growable: true);

  Future<void> loadData() async {
    final dataStr = await FileRepo().readFile("saved_data.json");
    List<dynamic> dataJson = json.decode(dataStr);

    for (final data in dataJson) {
      String name = data["name"];
      String note = data["note"];
      List<dynamic> featureJson = data["features"];

      List<ImageAndFeature> features = List.empty(growable: true);

      for (final feature in featureJson) {
        String path = feature["imagePath"];
        List vector = feature["featureVector"];
        DateTime date = DateTime.fromMillisecondsSinceEpoch(feature["date"]);

        features.add(ImageAndFeature(path, date, vector));
      }

      final person = PersonData(name, note, features, "123");

      historyPersonList.add(person);

      // print("load from db, path: ${path}");

    }

    print("load from db, total: ${historyPersonList.length}");

  }

  void addPerson(List data, String name, imglib.Image image) {

    final now = DateTime.now();
    final path = "image/${name}_${now.millisecondsSinceEpoch}.png";

    FileRepo().writeFileAsBytes(path, imglib.encodePng(image) as Uint8List);

    // final newData = PersonData(data, name, path, name);

    // historyPersonList.add(newData);
    bool existPerson = false;
    for (final person in historyPersonList) {
      if (person.name == name) {

        person.features.add(ImageAndFeature(path, now, data));

        existPerson = true;
        break;
      }
    }

    if (!existPerson) {
      historyPersonList.add(
        PersonData(name, "note", List.of([ImageAndFeature(path, now, data)]), "123")
      );
    }

    _save();
  }

  void deletePerson(String name) {
    historyPersonList.removeWhere((element) => element.name == name);

    _save();
  }

  void deletePersonSubImage(String name, DateTime date) {
    for (var person in historyPersonList) {
      person.features.removeWhere((element) =>
        person.name == name && element.date == date
      );
    }

    historyPersonList.removeWhere((element) => element.features.isEmpty);

    _save();
  }
  void updatePersonNote(String name, String newNote) {
    for (var person in historyPersonList) {
      if (person.name == name) {
        person.note = newNote;
        break;
      }
    }

    _save();
  }

  String encodeData() {
    List<Map<String, dynamic>> dataJson = List.empty(growable: true);
    for (final person in historyPersonList) {
      List<dynamic> featureJson = List.empty(growable: true);
      for (final feature in person.features) {
        final featureVector = feature.featureVector.map((e) => double.parse(e.toStringAsFixed(5))).toList();
        featureJson.add({
          "imagePath": feature.imagePath,
          "date": feature.date.millisecondsSinceEpoch,
          "featureVector": featureVector
        });
      }
      dataJson.add({
        "name": person.name,
        "note": person.note,
        "features": featureJson
      });
    }

    return json.encode(dataJson);
  }

  void _save() {
    final dataStr = encodeData();

    print("save str: $dataStr");

    FileRepo().writeFile("saved_data.json", dataStr);
  }

  PersonData? findClosestFace(List data) {
    double minDist = 999;
    double currDist = 999;
    PersonData? predictedResult;

    for (final history in historyPersonList) {
      for (final feature in history.features) {
        currDist = _euclideanDistance(feature.featureVector, data);
        if (currDist <= THRESHOLD && currDist < minDist) {
          minDist = currDist;
          predictedResult = history;
        }
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