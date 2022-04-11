

import 'dart:ffi';
import 'dart:math';

import 'package:google_ml_kit/google_ml_kit.dart';

class PersonData {
  List featureVector;
  String name;
  // Face? face;

  String _uid;
  String get uid => _uid;

  PersonData(this.featureVector, this.name, this._uid);

}

class DetectedDB {
  static const double THRESHOLD = 1.0;

  List<PersonData> historyPersonList = List.empty(growable: true);

  void addPerson(List data, String name) {
    final newData = PersonData(data, name, name);

    historyPersonList.add(newData);
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