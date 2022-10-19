

import 'package:flutter_tts/flutter_tts.dart';

import 'detectModel.dart';
import 'package:image/image.dart';


class KnownPerson {
  final String id;
  DateTime date;

  bool visible = false;
  bool checked = false;
  int notifyCount = 0;

  KnownPerson(this.id, this.date);
}


class DetectKnownModel {

  List<KnownPerson> _cache = List.empty(growable: true);

  FlutterTts _flutterTts = FlutterTts()
    ..setSpeechRate(0.2);

  bool _isSpeaking = false;

  reset() {

  }

  runFlow(DetectResult result) {

    _cache.forEach((e) {
      e.checked = false;
    });

    final known = result.knownList;

    if (known == null || known.isEmpty) {
      _cache.forEach((e) {
        e.visible = false;
      });
      return;
    }

    for (final person in known) {
      _handleKnownPerson(person);
    }

    _cache.forEach((e) {
      if (!e.checked) e.visible = false;
    });
  }

  _handleKnownPerson(DetectPerson person) {
    print("_handleKnownPerson ${person.name}");
    final id = person.name!;
    final ids = _cache.map((e) => e.id);
    if (!ids.contains(id)) {
      _cache.add(
          KnownPerson(id, DateTime.now())
            ..checked = true
            ..visible = true
      );
      return;
    }

    final existKnownPerson = _cache.firstWhere((element) => element.id == id);

    if (existKnownPerson.visible) {
      if (existKnownPerson.date.add(Duration(seconds: 3)).compareTo(DateTime.now()) < 0) {
        if (!_isSpeaking) {
          if (existKnownPerson.notifyCount < 1) { // TODO: change this
            _notify(person);
            existKnownPerson.notifyCount++;
          }
        }
      }
    } else {
      existKnownPerson.date = DateTime.now();
    }

    existKnownPerson
      ..visible = true
      ..checked = true;

  }

  _notify(DetectPerson person) async {
    final notifyInfo = "辨識到：${person.name}，${person.note}";
    _isSpeaking = true;
    await _flutterTts.speak(notifyInfo);
    _isSpeaking = false;
  }

}