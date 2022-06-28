

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../bleModel.dart';

class LabelViewModel {
  StreamController<bool> _deviceAllowedController = StreamController<bool>();

  late Stream<bool> deviceAllowed;
  bool _connected = false;


  BluetoothCharacteristic? unlabeledCharacteristic, imageCharacteristic;

  bool _jsonStreaming = false;

  bool _imageStreaming = false;


  String? _rawJson;

  StreamController<List<UnlabeledData>> _unlabeledListController = StreamController<List<UnlabeledData>>();
  late Stream<List<UnlabeledData>> unlabeled;

  List<UnlabeledImageData> _fetchedImage = List.empty(growable: true);

  LabelViewModel() {
    deviceAllowed = _deviceAllowedController.stream.asBroadcastStream();

    unlabeled = _unlabeledListController.stream;

    connect();
  }

  Future<void> connect() async {
    final devices = await BLEModel.getConnectedDevice();

    final device = devices.firstWhere((device) => device.name == "NCLAB");
    device.requestMtu(512);
    device.discoverServices();

    // _device = device;

    _deviceAllowedController.addStream(device.state.asyncMap((event) {
      return event == BluetoothDeviceState.connected;
    }));

    deviceAllowed.listen((event) => _connected = event);

    device.services.listen((service) {

      service.forEach((element) {
        // print(element.uuid.toString().toUpperCase().substring(4, 8));
        if (element.uuid.toString().toUpperCase().substring(4, 8) == '180F') {
          unlabeledCharacteristic = element.characteristics.firstWhere((characteristic) => characteristic.uuid.toString().toUpperCase().substring(4, 8) == '2A1A');
          imageCharacteristic = element.characteristics.firstWhere((characteristic) => characteristic.uuid.toString().toUpperCase().substring(4, 8) == '2A19');
        }
      });
    });
  }

  StreamSubscription? _listener;

  void startLoadingUnlabeled() async {
    if (_jsonStreaming) {
      print("ERROR1========");

      return;
    }

    if (!_connected) {
      print("ERROR2========");

      return;
    }

    if (unlabeledCharacteristic == null) {
      print("ERROR3========");
      return;
    }

    final characteristics = unlabeledCharacteristic!;

    _jsonStreaming = true;

    final jsonData = List<int>.empty(growable: true);

    _listener = characteristics.value.listen((event) {
      print("listen: ${utf8.decode(event.sublist(2))}");
      final int index = event[0] * 256 + event[1];

      jsonData.addAll(event.sublist(2));
      if (index == 0) {
        // characteristics.setNotifyValue(false);

        _rawJson = String.fromCharCodes(jsonData);
        _parseJson();

        _listener?.cancel();
        _jsonStreaming = false;
      }
    });

    characteristics.setNotifyValue(true);
  }

  void loadImage(UnlabeledImageData originData) async {

    final path = originData.path;

    for (final img in _fetchedImage) {
      if (img.path == path && img.faceImg != null) {
        print("======= WARNING: NOT NEED TO FETCH ========");
        return;
      }
    }


    if (_imageStreaming) {
      print("ERROR1========");

      return;
    }

    if (!_connected) {
      print("ERROR2========");

      return;
    }

    if (imageCharacteristic == null) {
      print("ERROR3========");
      return;
    }

    final characteristics = imageCharacteristic!;

    _imageStreaming = true;

    await characteristics.write(utf8.encode("$path/face.jpg"));

    // final currentPath = utf8.decode(await characteristics.read());
    // print("PATH: $currentPath");
    //
    // if (currentPath != "$path/face.jpg") {
    //   _imageStreaming = false;
    //
    //   print("ERROR4========");
    //
    //   return;
    // }

    final imgData = List<int>.empty(growable: true);

    // bool pathGet = false;

    _listener = characteristics.value.listen((event) {
      // if (!pathGet) {
      //   final tryGetPath = utf8.decode(event);
      //   print("listen: ${utf8.decode(event)}");
      //
      //   if (tryGetPath == currentPath) {
      //     pathGet = true;
      //     return;
      //   }
      // }
      // return;
      // print("listen: ${utf8.decode(event)}");

      final int index = event[0] * 256 + event[1];

      // print("Index: $index");
      // print("Event: $event");


      imgData.addAll(event.sublist(2));
      if (index == 0) {

        // characteristics.setNotifyValue(false);

        UnlabeledImageData newImgData = UnlabeledImageData(
            originData.time,
            path
        );

        newImgData.faceImg = Uint8List.fromList(imgData);

        _fetchedImage.add(newImgData);
        // final rawJson = String.fromCharCodes(jsonData);
        _parseJson();

        _listener?.cancel();

        _imageStreaming = false;
      }
    });

    characteristics.setNotifyValue(true);
  }

  void dataChanged(List<UnlabeledData> fullData) {
    _unlabeledListController.add(fullData);
  }

  void createLabeled(List<UnlabeledData> data) {

  }

  void _parseJson() {
    if (_rawJson == null) {
      return;
    }

    final rawJson = _rawJson!;

    List<dynamic> jsonArray = json.decode(rawJson);

    List<UnlabeledData> newData = List.empty(growable: true);

    for (final person in jsonArray) {
      String date = person["firstDate"];
      List<dynamic> rawImages = person["images"];

      List<UnlabeledImageData> images = List.empty(growable: true);
      for (final image in rawImages) {
        String path = image["path"];
        String time = image["time"];

        // if already exist, use it.
        final data = _fetchedImage.firstWhere((element) => element.path == path, orElse: () => UnlabeledImageData(time, path));

        images.add(data);
      }

      newData.add(
        UnlabeledData(date, images)
      );
    }

    _unlabeledListController.add(newData);
  }
}

class UnlabeledData {
  String date;
  List<UnlabeledImageData> images;

  bool selected = false;
  String name = "";

  UnlabeledData(this.date, this.images);
}

class UnlabeledImageData {
  String time, path;

  Uint8List? faceImg, fullImg;

  UnlabeledImageData(this.time, this.path);
}

