
import 'package:camera/camera.dart';
import 'package:face_recognize/ImageHelper.dart';
import 'package:face_recognize/tfLiteModel.dart';
import 'package:face_recognize/ui/camera/faceDetectorPainter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../detect_model/detectModel.dart';

import 'package:image/image.dart';


class CameraViewModel extends ChangeNotifier {

  late CameraController cameraController;

  CameraDescription _camera;

  FaceDetectorPainter? painter;

  late DetectModel _detectModel;

  Image? _currentImage;

  bool _showInputDialog = false;
  bool get showInputDialog => _showInputDialog;

  late Image _inputDialogImage;
  Image get inputDialogImage => _inputDialogImage;

  FlutterTts _flutterTts = FlutterTts();

  CameraViewModel(this._camera) {
    cameraController = CameraController(
      _camera,
      ResolutionPreset.medium,
    );

    cameraController.initialize().then((value) {
      notifyListeners();
      startStreaming();
    });

    _detectModel = DetectModel(TFLiteModel());

    _flutterTts.setSpeechRate(0.2);
  }

  void startStreaming() {
    cameraController.startImageStream((image) {
      _onImageAvailable(image);
    });
  }

  void onAddClick() {
    final image = _currentImage;
    if (image != null) {
      _inputDialogImage = image;
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

    final result = _detectModel.getFaceFeature(_inputDialogImage);

    _detectModel.addFaceToDB(result, name, _inputDialogImage);

    notifyListeners();
  }

  void dispose() {
    cameraController.dispose();
    _detectModel.dispose();

    super.dispose();
  }


  Future _onImageAvailable(CameraImage cameraImage) async {
    if (_detectModel.isBusy) return;
    if (showInputDialog) return;

    final image = ImageHelper.convertCameraImage(cameraImage);

    final result = await _detectModel.runFlow(image);

    if (result != null) {

      List<PaintData> paintData = List.empty(growable: true);
      result.unknownList?.forEach((element) {
        paintData.add(PaintData(element.face, null));
      });
      result.knownList?.forEach((element) {
        paintData.add(PaintData(element.face, element.name));
      });

      final inputImage = ImageHelper.createInputImage(image);
      painter = FaceDetectorPainter(
          paintData,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation
      );

      if (result.unknownList?.isNotEmpty == true) {
        _currentImage = result.unknownList?.first.image;
      }

    } else {
      _currentImage = null;
      painter = null;
    }


    notifyListeners();

    // print("Result: Finish: len: ${result.length}");
  }

}
