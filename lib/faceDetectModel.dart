
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import 'package:google_ml_kit/google_ml_kit.dart';

class FaceDetectModel {
  final faceDetector = GoogleMlKit.vision.faceDetector(FaceDetectorOptions(
    enableContours: true,
    enableClassification: true,
  ));

  Future<List<Face>> detect(InputImage inputImage) async {
    final result = faceDetector.processImage(inputImage);

    return result;
  }

  void dispose() {
    faceDetector.close();
  }

}