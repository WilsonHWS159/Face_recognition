
import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';


import 'package:image/image.dart';

/// Image helper class
class ImageHelper {

  static InputImage createInputImage(Image image) {
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

  static Image cropFace(Image image, Face faceDetected, {int outputSize = 112, double expandRatio = 0.1}) {
    double xExpand = faceDetected.boundingBox.width * expandRatio;
    double yExpand = faceDetected.boundingBox.height * expandRatio;
    double x = faceDetected.boundingBox.left - xExpand;
    double y = faceDetected.boundingBox.top - yExpand;
    double w = faceDetected.boundingBox.width + xExpand * 2;
    double h = faceDetected.boundingBox.height + yExpand * 2;

    final croppedImage = copyCrop(image, x.round(), y.round(), w.round(), h.round());
    return copyResizeCropSquare(croppedImage, outputSize);
  }

  static Image convertCameraImage(CameraImage image, {int sensorOrientation = 90}) {
    var img = _convertToImage(image)!;
    return copyRotate(img, sensorOrientation);
  }

  static Image? _convertToImage(CameraImage image) {
    try {
      switch (image.format.group) {
        case ImageFormatGroup.yuv420:
          return _convertYUV420(image);
        case ImageFormatGroup.bgra8888:
          return _convertBGRA8888(image);
        case ImageFormatGroup.jpeg:
          throw Exception("Image format not supported");
        case ImageFormatGroup.unknown:
          throw Exception("Image format not supported");
      }
    } catch (e) {
      print("ImageHelper ERROR: " + e.toString());
    }
    return null;
  }

  static Image _convertBGRA8888(CameraImage image) {
    return Image.fromBytes(
      image.width,
      image.height,
      image.planes[0].bytes,
      format: Format.bgra,
    );
  }

  static const shift = (0xFF << 24);
  static Image _convertYUV420(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;
    var img = Image(width, height);
    for (int x = 0; x < width; x++) { // Fill image buffer with plane[0] from YUV420_888
      for (int y = 0; y < height; y++) {
        final int uvIndex = uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        // Use the row stride instead of the image width as some devices pad the image data,
        // and in those cases the image width != bytesPerRow. Using width will give you a destroyed image.
        final int index = y * uvRowStride + x;
        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255).toInt();
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255).toInt();
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255).toInt();
        img.setPixelRgba(x, y, r, g, b);
        // img.data[index] = shift | (b << 16) | (g << 8) | r;
      }
    }

    return img;
  }

  static Float32List imageToByteListFloat32(Image image, {int size = 112}) {
    var convertedBytes = Float32List(1 * size * size * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < size; i++) {
      for (var j = 0; j < size; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (getRed(pixel) - 128) / 128;
        buffer[pixelIndex++] = (getGreen(pixel) - 128) / 128;
        buffer[pixelIndex++] = (getBlue(pixel) - 128) / 128;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }
}
