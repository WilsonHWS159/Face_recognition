

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../bleModel.dart';

class BLEDetectViewModel {
  StreamController<bool> _deviceAllowedController = StreamController<bool>();

  late Stream<bool> deviceAllowed;
  bool _connected = false;

  // StreamController<bool> _charAllowController = StreamController<bool>();
  //
  // late Stream<bool> charAllowStream;

  // BluetoothDevice? _device;

  BluetoothCharacteristic? imageCharacteristic;

  bool _imageStreaming = false;

  StreamController<Uint8List> _imgController = StreamController<Uint8List>();
  late Stream<Uint8List> imgListDataStream;

  // Uint8List? imgListData;

  final imgData = List<int>.empty(growable: true);


  BLEDetectViewModel() {
    deviceAllowed = _deviceAllowedController.stream.asBroadcastStream();
    imgListDataStream = _imgController.stream;
    // charAllowStream = _charAllowController.stream;
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
        print(element.uuid.toString().toUpperCase().substring(4, 8));
        if (element.uuid.toString().toUpperCase().substring(4, 8) == '180F') {
          final char = element.characteristics.firstWhere((characteristic) => characteristic.uuid.toString().toUpperCase().substring(4, 8) == '2A19');
          imageCharacteristic = char;
        }
      });
      // final imgService = service.firstWhere((element) => element.uuid.toString().toUpperCase().substring(4, 8) == '180F');
      // //
      // final char = imgService.characteristics.firstWhere((characteristic) => characteristic.uuid.toString().toUpperCase().substring(4, 8) == '2A19');
      // //
      // imageCharacteristic = char;
    });
  }

  StreamSubscription? _listener;

  void startLoadingImage() async {
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

    imgData.clear();
    // imgListData.clear();
    _listener = characteristics.value.listen((event) {
      final int index = event[0] * 256 + event[1];

      imgData.addAll(event.sublist(2));
      DateTime now = DateTime.now();
      print("Index: $index, Time: $now");

      if (index == 0) {
        characteristics.setNotifyValue(false);

        print("SUCCESS =================");
        final newImage = Uint8List.fromList(imgData);
        _imgController.add(newImage);

        _listener?.cancel();

        _imageStreaming = false;
      }
    });



    characteristics.setNotifyValue(true);


    // characteristics.value;
  }
}