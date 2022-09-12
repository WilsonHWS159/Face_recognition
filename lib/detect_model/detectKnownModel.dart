

import 'detectModel.dart';
import 'package:image/image.dart';


class KnownPerson {
  DateTime date;
  List feature;

  KnownPerson(this.date, this.feature);
}


class DetectKnownModel {

  List<KnownPerson> _cache = List.empty(growable: true);

  reset() {

  }

  runFlow(DetectResult result) {
    final known = result.knownList;

    if (known == null || known.isEmpty) return;

    for (final person in known) {
      _handleKnownPerson(person);
    }
  }

  _handleKnownPerson(DetectPerson person) {

  }

  _createUnlabeledFile() {

  }

}