
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import 'package:google_ml_kit/google_ml_kit.dart';

class FaceDetectModel {

  bool isBusy = false;

  final faceDetector = GoogleMlKit.vision.faceDetector(FaceDetectorOptions(
    // enableTracking: true,
    minFaceSize: 0.1,
    mode: FaceDetectorMode.accurate
  ));

  Future<List<Face>> detect(InputImage inputImage) async {
    if (isBusy) return List.empty();

    isBusy = true;
    final result = await faceDetector.processImage(inputImage);
    isBusy = false;

    return result;
  }

  void dispose() {
    faceDetector.close();
  }

}