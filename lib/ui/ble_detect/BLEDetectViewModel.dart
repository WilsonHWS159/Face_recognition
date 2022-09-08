

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart';

import '../../ImageHelper.dart';
import '../../bleModel.dart';
import '../../detectedDB.dart';
import '../../faceDetectModel.dart';
import '../../tfLiteModel.dart';
import '../camera/faceDetectorPainter.dart';

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

  StreamController<FaceDetectorPainter?> _painterController = StreamController<FaceDetectorPainter?>();
  late Stream<FaceDetectorPainter?> boxPainterStream;
  // bool _painter = false;
  // FaceDetectorPainter? painter;

  FaceDetectModel _faceDetectModel = FaceDetectModel();

  TFLiteModel _mlModel = TFLiteModel();

  DetectedDB _detectedDB = DetectedDB();


  BLEDetectViewModel() {
    deviceAllowed = _deviceAllowedController.stream.asBroadcastStream();
    imgListDataStream = _imgController.stream;
    boxPainterStream = _painterController.stream;
    // charAllowStream = _charAllowController.stream;
    connect();

    _mlModel.initialize();
    _detectedDB.loadData();
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

    final imgData = List<int>.empty(growable: true);

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
        
        detectImage(newImage);

        _listener?.cancel();

        _imageStreaming = false;
      }
    });



    characteristics.setNotifyValue(true);


  }

  void detectImage(Uint8List image) async {
    Image img = decodeImage(image)!;

    final inputImage = _createInputImage(img);
    final result = await _faceDetectModel.detect(inputImage);

    for (final r in result) {
      print("boundingBox ==========");
      print(r.boundingBox);
    }

    if (result.isEmpty) {
      return;
    }

    final croppedImage = ImageHelper.cropFace(img, result.first);

    final mlResult = _predictFace(croppedImage);

    PersonData? person;
    if (mlResult != null) {
      print("result not null ==========");

      person = _detectedDB.findClosestFace(mlResult);
    }

    List<PaintData> paintData = List.empty(growable: true);
    paintData.add(PaintData(result.first, person?.name));

    final painter = FaceDetectorPainter(
        paintData,
        inputImage.inputImageData!.size,
        inputImage.inputImageData!.imageRotation
    );

    _painterController.add(painter);
  }

  InputImage _createInputImage(Image image) {
    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final InputImageRotation imageRotation = InputImageRotation.Rotation_0deg;
    final InputImageFormat inputImageFormat = InputImageFormat.NV21;

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: null,
    );

    return InputImage.fromBytes(bytes: Uint8List.fromList(image.data), inputImageData: inputImageData);
  }

  List? _predictFace(Image image) {
    if (!_mlModel.isInitialized) return null;

    return _mlModel.outputFaceFeature(image);
  }

}