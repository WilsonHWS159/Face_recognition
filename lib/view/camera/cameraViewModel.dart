
import 'package:camera/camera.dart';
import 'package:face_recognize/ImageHelper.dart';
import 'package:face_recognize/faceDetectModel.dart';
import 'package:face_recognize/mlModel.dart';
import 'package:face_recognize/view/camera/faceDetectorPainter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import '../../detectedDB.dart';

import 'package:image/image.dart' as imglib;


class CameraViewModel extends ChangeNotifier {

  late CameraController cameraController;

  CameraDescription _camera;

  FaceDetectorPainter? painter;

  FaceDetectModel _faceDetectModel = FaceDetectModel();

  MLModel _mlModel = MLModel();

  DetectedDB _detectedDB = DetectedDB();

  imglib.Image? _currentImage;

  bool _showInputDialog = false;
  bool get showInputDialog => _showInputDialog;

  late imglib.Image _inputDialogImage;
  imglib.Image get inputDialogImage => _inputDialogImage;


  // Future<void>? _detecting;

  CameraViewModel(this._camera) {
    cameraController = CameraController(
      _camera,
      ResolutionPreset.medium,
    );

    cameraController.initialize().then((value) {
      notifyListeners();
      startStreaming();
    });

    _mlModel.initialize();
  }

  void startStreaming() {
    cameraController.startImageStream((image) {
      // if (_detecting == null) {
      //   _detecting = _onImageAvailable(image);
      //   _detecting?.then((value) => _detecting = null);
      // }
      _onImageAvailable(image);

      // imageData = image.planes[0].bytes;



      // cameraController.stopImageStream();
      // print("Streaming... ${imageData}");
      // notifyListeners();
    });
  }

  void onAddClick() {
    if (_currentImage != null) {
      _inputDialogImage = _currentImage!;
      _showInputDialog = true;
      notifyListeners();
    }

  }

  void onCancelClick() {
    _showInputDialog = false;
    notifyListeners();
  }

  void onOKClick(String name) {
    _showInputDialog = false;

    final result = _predictFace(_inputDialogImage);

    if (result != null) {
      _detectedDB.addPerson(result, name);
    }

    notifyListeners();
  }

  void dispose() {
    _faceDetectModel.dispose();
    _mlModel.dispose();
    cameraController.dispose();

    super.dispose();
  }

  Future _onImageAvailable(CameraImage image) async {
    if (_faceDetectModel.isBusy) return;
    if (showInputDialog) return;

    final inputImage = _createInputImage(image);
    final result = await _faceDetectModel.detect(inputImage);

    if (result.isNotEmpty) {

      // TODO: predict every face, currently only first face
      final croppedImage = ImageHelper.cropFace(image, result.first);
      _currentImage = croppedImage;

      final mlResult = _predictFace(croppedImage);

      PersonData? person;
      if (mlResult != null) {
        person = _detectedDB.findClosestFace(mlResult);
      }


      List<PaintData> paintData = List.empty(growable: true);
      paintData.add(PaintData(result.first, person?.name));

      // final paintData = result.map((e) {
      //   return PaintData(e, null);
      // }).toList();

      painter = FaceDetectorPainter(
          paintData,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation
      );

    } else {
      _currentImage = null;
      painter = null;
    }

    notifyListeners();

    // print("Result: Finish: len: ${result.length}");
  }

  // void _predictFace(CameraImage cameraImage, List<Face> face) {
  List? _predictFace(imglib.Image image) {
    if (!_mlModel.isInitialized) return null;
    // if (_mlModel.isBusy) return;



    return _mlModel.predict(image);
    // _mlModel.setCurrentPrediction(cameraImage, face);
    // final current = _mlModel.predictedData;
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