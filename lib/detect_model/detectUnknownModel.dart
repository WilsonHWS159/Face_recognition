

import 'dart:convert';
import 'dart:typed_data';

import 'package:analyzer_plugin/utilities/pair.dart';
import 'package:face_recognize/detect_model/faceFeatureComparator.dart';

import '../fileRepo.dart';
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
    _cache = List.empty(growable: true);
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

    print("_handleUnknownPerson, closestID: $closestID");
    
    if (closestID == null) {
      // This person is a new unknown person
      _handleNewUnknownPerson(person);
    } else {
      // This person is recorded unknown person
      _handleExistedUnknownPerson(person, closestID);
    }
  }

  /// Find closest person in unknown person cache
  String? _findClosestPerson(DetectPerson person) {
    final unknownCache = _cache.map((unknownPerson) =>
        unknownPerson.features.map((e) => Pair(unknownPerson.id, e.feature))
    ).expand((element) => element).toList();

    return _comparator.findBest(person.feature, unknownCache);
  }

  _handleNewUnknownPerson(DetectPerson person) {
    print("_handleNewUnknownPerson");

    final id = "id_${_cache.length}"; // TODO: Use more reasonable id
    final now = DateTime.now();
    final newPerson = UnknownPerson(id, now);
    newPerson.features.add(
        UnknownPersonFeature(person.image, now, person.feature)
    );
    _cache.add(newPerson);
  }

  _handleExistedUnknownPerson(DetectPerson person, String id) {
    print("_handleExistedUnknownPerson");

    final existData = _cache.firstWhere((element) => element.id == id);
    final now = DateTime.now();

    final lastFeature = existData.features.last;
    if (lastFeature.date.add(Duration(seconds: 5)).isBefore(now)) {
      // Feature append min interval is 5 seconds
      existData.features.add(
          UnknownPersonFeature(person.image, now, person.feature)
      );
    }
  }
  
  createUnlabeledFile() {
    // Only convert the person that has more then one images.
    final personList = _cache.where((element) => element.features.length > 1);
    final fileRepo = FileRepo();

    List<Map<String, dynamic>> dataJson = List.empty(growable: true);

    personList.forEach((person) {
      final date = person.date.microsecondsSinceEpoch.toString();

      List<Map<String, dynamic>> featureJson = List.empty(growable: true);

      person.features.forEach((feature) {
        final date = feature.date.millisecondsSinceEpoch.toString();
        final image = feature.image;
        final path = "image/${person.id}_$date.png";

        fileRepo.writeFileAsBytes(path, encodePng(image) as Uint8List);
        featureJson.add({
          "path": path,
          "time": date
        });
      });

      dataJson.add({
        "firstDate": date,
        "images": featureJson
      });
    });

    final dataStr = json.encode(dataJson);

    FileRepo().writeFile("unlabeled.json", dataStr);
  }

}
