import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:face_recognize/faceDetectModel.dart';
import 'package:face_recognize/view/faceDetectorPainter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_ml_kit/google_ml_kit.dart';




class CameraViewModel extends ChangeNotifier {

  late CameraController cameraController;

  CameraDescription _camera;

  FaceDetectorPainter? painter;
  // Uint8List? imageData;

  FaceDetectModel _faceDetectModel = FaceDetectModel();

  Future<void>? _detecting;

  CameraViewModel(this._camera) {
    cameraController = CameraController(
      _camera,
      ResolutionPreset.medium,
    );

    cameraController.initialize().then((value) {
      notifyListeners();
      startStreaming();
    });
  }

  void startStreaming() {
    cameraController.startImageStream((image) {
      if (_detecting == null) {
        _detecting = _onImageAvailable(image);
        _detecting?.then((value) => _detecting = null);
      }

      // imageData = image.planes[0].bytes;



      // cameraController.stopImageStream();
      // print("Streaming... ${imageData}");
      // notifyListeners();
    });
  }

  void dispose() {
    _faceDetectModel.dispose();
    cameraController.dispose();

    super.dispose();
  }

  Future _onImageAvailable(CameraImage image) async {
    final inputImage = _createInputImage(image);
    final result = await _faceDetectModel.detect(inputImage);

    if (result.isNotEmpty) {
      painter = FaceDetectorPainter(
          result,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation
      );
    } else {
      painter = null;
    }

    notifyListeners();

    print("Result: Finish: len: ${result.length}");
  }

  InputImage _createInputImage(CameraImage cameraImage) {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in cameraImage.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    int width = cameraImage.planes[0].bytesPerRow;
    final Size imageSize = Size(width.toDouble(), cameraImage.height.toDouble());
    // final Size imageSize = Size(cameraImage.width.toDouble(), cameraImage.height.toDouble());

    final InputImageRotation imageRotation =
        InputImageRotationMethods.fromRawValue(_camera.sensorOrientation) ??
            InputImageRotation.Rotation_0deg;

    final InputImageFormat inputImageFormat =
        InputImageFormatMethods.fromRawValue(cameraImage.format.raw) ??
            InputImageFormat.NV21;

    final planeData = cameraImage.planes.map(
          (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    return InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
  }

}