

import 'package:analyzer_plugin/utilities/pair.dart';
import 'package:face_recognize/detect_model/faceFeatureComparator.dart';

import 'detectModel.dart';
import 'package:image/image.dart';


class UnknownPerson {
  String id;
  DateTime date;
  List<UnknownPersonFeature> features = List.empty(growable: true);

  UnknownPerson(this.id, this.date);
}

class UnknownPersonFeature {
  Image image;
  DateTime date;
  List<double> feature;

  UnknownPersonFeature(this.image, this.date, this.feature);
}

class DetectUnknownModel {

  FaceFeatureComparator _comparator;

  List<UnknownPerson> _cache = List.empty(growable: true);

  DetectUnknownModel(this._comparator);

  reset() {

  }

  runFlow(DetectResult result) {
    final unknown = result.unknownList;

    if (unknown == null || unknown.isEmpty) return;

    for (final person in unknown) {
      _handleUnknownPerson(person);
    }
  }

  _handleUnknownPerson(DetectPerson person) {
    final closestID = _findClosestPerson(person);

    if (closestID == null) {

    }
  }

  String? _findClosestPerson(DetectPerson person) {
    final unknownCache = _cache.map((unknownPerson) =>
        unknownPerson.features.map((e) => Pair(unknownPerson.id, e.feature))
    ).expand((element) => element).toList();

    return _comparator.findBest(person.feature, unknownCache);
  }

  _createUnlabeledFile() {

  }

}