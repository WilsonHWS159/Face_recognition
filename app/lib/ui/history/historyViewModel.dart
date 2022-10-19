

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:face_recognize/detectedDB.dart';
import 'package:face_recognize/fileRepo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../bleModel.dart';
import '../../detect_model/faceFeatureComparator.dart';


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

  DetectedDB _detectedDB = DetectedDB(ArcFaceComparator(0.45));

  StreamController<bool> _deviceAllowedController = StreamController<bool>();

  late Stream<bool> deviceAllowed;
  bool _connected = false;


  BluetoothCharacteristic? labeledCharacteristic;

  HistoryViewModel() {
    deviceAllowed = _deviceAllowedController.stream.asBroadcastStream();

    load();
    connect();
  }

  Future<void> connect() async {
    final devices = await BLEModel.getConnectedDevice();

    final device = devices.firstWhere((device) => device.name == "NCLAB");
    device.requestMtu(512);
    device.discoverServices();

    _deviceAllowedController.addStream(device.state.asyncMap((event) {
      return event == BluetoothDeviceState.connected;
    }));

    deviceAllowed.listen((event) => _connected = event);

    device.services.listen((service) {

      service.forEach((element) {
        if (element.uuid.toString().toUpperCase().substring(4, 8) == '180F') {
          labeledCharacteristic = element.characteristics.firstWhere((characteristic) => characteristic.uuid.toString().toUpperCase().substring(4, 8) == '2A18');
        }
      });
    });
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

  void sendJsonToBLEServer() async {
    if (!_connected) {
      print("ERROR1========");
      return;
    }

    if (labeledCharacteristic == null) {
      print("ERROR2========");
      return;
    }

    final data = _detectedDB.encodeData();

    final encodedData = utf8.encode(data);

    final len = encodedData.length;
    final size = 250; // TODO: use mtu size
    final blocks = len ~/ size + 1;
    int currentBlocks = blocks;
    int start = 0;

    while (currentBlocks > 0) {
      print(currentBlocks);
      final end = start + size >= len ? len : start + size;
      final separatedData = Uint8List.fromList([currentBlocks ~/ 256, currentBlocks % 256]) + encodedData.sublist(start, end);
      await labeledCharacteristic!.write(separatedData);

      start += size;
      currentBlocks -= 1;
    }
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