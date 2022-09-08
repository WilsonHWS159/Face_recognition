

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:face_recognize/fileRepo.dart';

import 'package:image/image.dart' as imglib;


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
  static const double THRESHOLD = 0.45;

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

  /// Add new person to DB
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
    double minDist = -100;
    double currDist = -100;
    PersonData? predictedResult;

    for (final history in historyPersonList) {
      for (final feature in history.features) {
        currDist = _euclideanDistance(feature.featureVector, data);
        if (currDist >= THRESHOLD && currDist > minDist) {
          minDist = currDist;
          predictedResult = history;
        }
      }
    }

    return predictedResult;
  }

  double _euclideanDistance(List e1, List e2) {


    List<double> normE1 = _normalize(e1);
    List<double> normE2 = _normalize(e2);

    print("before: ${e1} ${e2}");
    print("after: ${normE1} ${normE2}");

    int len = normE1.length;

    double sum = 0.0;
    for (int i = 0; i < len; i++) {
      // sum += pow((e1[i] - e2[i]), 2);
      sum += normE1[i] * normE2[i];
    }



    // sum = sqrt(sum);
    print("distance: $sum ##########");
    return sum;
  }

  List<double> _normalize(List e) {
    int len = e.length;

    double sum = 0.0;
    for (int i = 0; i < len; i++) {
      sum += e[i];
    }

    double mean = sum / len;

    double sum2 = 0.0;

    for (int i = 0; i < len; i++) {
      sum2 += e[i] * e[i];//(e[i] - mean) * (e[i] - mean);
    }

    // sum2 /= len;
    double sigma = sqrt(sum2);

    List<double> result = new List.empty(growable: true);
    for (int i = 0; i < len; i++) {
      result.add(e[i]/sigma);
    }

    // sum = sqrt(sum);
    // print("distance: $sum ##########");
    return result;
  }
}