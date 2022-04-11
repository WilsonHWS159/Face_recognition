

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:face_recognize/ImageHelper.dart';

import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'package:image/image.dart' as imglib;

class MLModel {
  late Interpreter _interpreter;

  late List _predictedData;
  List get predictedData => _predictedData;
  bool isInitialized = false;

  Future initialize() async {
    Delegate delegate;
    try {
      if (Platform.isAndroid) {
        delegate = GpuDelegateV2(
            options: GpuDelegateOptionsV2(
              isPrecisionLossAllowed: false,
              inferencePreference: TfLiteGpuInferenceUsage.fastSingleAnswer,
              inferencePriority1: TfLiteGpuInferencePriority.minLatency,
              inferencePriority2: TfLiteGpuInferencePriority.auto,
              inferencePriority3: TfLiteGpuInferencePriority.auto,
            ));
      } else if (Platform.isIOS) {
        delegate = GpuDelegate(
          options: GpuDelegateOptions(
              allowPrecisionLoss: true,
              waitType: TFLGpuDelegateWaitType.active
          ),
        );
      } else {
        return;
      }
      var interpreterOptions = InterpreterOptions()..addDelegate(delegate);

      this._interpreter = await Interpreter.fromAsset('mobilefacenet.tflite',
          options: interpreterOptions);

      isInitialized = true;
    } catch (e) {
      print('Failed to load model.');
      print(e);
    }
  }

  // bool isBusy = false;

  List predict(imglib.Image image) {
    // if (isBusy) return;
    print("=========== IN ****** ===========");

    // isBusy = true;

    List input = _preProcess(image);

    input = input.reshape([1, 112, 112, 3]);
    List output = List.generate(1, (index) => List.filled(192, 0));

    this._interpreter.run(input, output);

    print("=========== out size: ${output.shape} =============");

    output = output.reshape([192]);

    // this._predictedData = List.from(output);
    print("=========== Success ===========");
    return output;

    // isBusy = false;

  }

  // Future<User> predict() async {
  //   return _searchResult(this._predictedData);
  // }


  List _preProcess(imglib.Image image) {//}, Face faceDetected) {
    // imglib.Image croppedImage = ImageHelper.cropFace(image, faceDetected);
    // imglib.Image resizedImage = imglib.copyResizeCropSquare(image, 112);

    Float32List imageAsList = ImageHelper.imageToByteListFloat32(image);
    return imageAsList;
  }
  //
  // imglib.Image _cropFace(CameraImage image, Face faceDetected) {
  //   imglib.Image convertedImage = ImageHelper.convertCameraImage(image);
  //   double x = faceDetected.boundingBox.left - 10.0;
  //   double y = faceDetected.boundingBox.top - 10.0;
  //   double w = faceDetected.boundingBox.width + 10.0;
  //   double h = faceDetected.boundingBox.height + 10.0;
  //   return imglib.copyCrop(convertedImage, x.round(), y.round(), w.round(), h.round());
  // }


  // Future<User> _searchResult(List predictedData) async {
  //   DatabaseHelper _dbHelper = DatabaseHelper.instance;
  //
  //   List<User> users = await _dbHelper.queryAllUsers();
  //   double minDist = 999;
  //   double currDist = 0.0;
  //   User predictedResult;
  //
  //   for (User u in users) {
  //     currDist = _euclideanDistance(u.modelData, predictedData);
  //     if (currDist <= threshold && currDist < minDist) {
  //       minDist = currDist;
  //       predictedResult = u;
  //     }
  //   }
  //   return predictedResult;
  // }

  // double _euclideanDistance(List e1, List e2) {
  //
  //   double sum = 0.0;
  //   for (int i = 0; i < e1.length; i++) {
  //     sum += pow((e1[i] - e2[i]), 2);
  //   }
  //   return sqrt(sum);
  // }

  // void setPredictedData(value) {
  //   this._predictedData = value;
  // }

  dispose() {
    _interpreter.close();
  }
}
