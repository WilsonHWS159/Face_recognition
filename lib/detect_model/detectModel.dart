

import 'package:face_recognize/ImageHelper.dart';
import 'package:face_recognize/detect_model/faceFeatureComparator.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart';

import '../detectedDB.dart';
import '../faceDetectModel.dart';
import '../tfLiteModel.dart';

/// Detect model's detect flow result data
class DetectResult {
  bool noPerson;
  List<DetectPerson>? unknownList;
  List<DetectPerson>? knownList;

  DetectResult(this.noPerson, {this.unknownList, this.knownList});
}

class DetectPerson {
  Face face;
  Image image;
  String? name;
  String? note;
  List<double> feature;

  DetectPerson(this.face, this.image, this.name, this.note, this.feature);
}

class DetectModel {

  TFLiteModel _tfLiteModel;

  FaceDetectModel _faceDetectModel = FaceDetectModel();

  DetectedDB _detectedDB;

  bool isBusy = false;

  DetectModel(this._tfLiteModel, FaceFeatureComparator comparator)
      : _detectedDB = DetectedDB(comparator) {
    _tfLiteModel.initialize();
    _detectedDB.loadData();
  }

  dispose() {
    _faceDetectModel.dispose();
  }

  reset() {

  }

  Future<DetectResult?> runFlow(Image image) async {
    if (!_tfLiteModel.isInitialized) return null;
    if (isBusy) return null;
    isBusy = true;

    final mlKitImage = ImageHelper.createInputImage(image);
    final result = await _detectFlowCore(mlKitImage, image);

    isBusy = false;

    return result;
  }

  Future<DetectResult> _detectFlowCore(InputImage mlKitImage, Image image) async {
    // Do MLKit's face detection.
    final faceList = await _faceDetectModel.detect(mlKitImage);

    // No face in image.
    if (faceList.isEmpty) return DetectResult(true);

    List<DetectPerson> unknownList = List.empty(growable: true);
    List<DetectPerson> knownList = List.empty(growable: true);

    // Process each face in detected face list
    for (final face in faceList) {
      final croppedImage = ImageHelper.cropFace(image, face);

      final feature = getFaceFeature(croppedImage);

      final person = _detectedDB.findClosestFace(feature);

      final data = DetectPerson(face, croppedImage, person?.name, person?.note, feature);

      person != null ? knownList.add(data) : unknownList.add(data);
    }

    return DetectResult(false, unknownList: unknownList, knownList: knownList);
  }


  List<double> getFaceFeature(Image image) {
    return _tfLiteModel.outputFaceFeature(image);
  }

  addFaceToDB(List<double> feature, String name, Image image) {
    _detectedDB.addPerson(feature, name, image);
  }
}