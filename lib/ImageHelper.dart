
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';


import 'package:image/image.dart' as imglib;

class ImageHelper {

  // static List cropFace(CameraImage image, Face faceDetected) {
  //   imglib.Image croppedImage = _cropFace(image, faceDetected);
  //   imglib.Image img = imglib.copyResizeCropSquare(croppedImage, 112);
  //
  //   Float32List imageAsList = ImageHelper.imageToByteListFloat32(img);
  //   return imageAsList;
  // }

  static imglib.Image cropFace(CameraImage image, Face faceDetected) {
    imglib.Image convertedImage = convertCameraImage(image);
    double x = faceDetected.boundingBox.left - 10.0;
    double y = faceDetected.boundingBox.top - 10.0;
    double w = faceDetected.boundingBox.width + 10.0;
    double h = faceDetected.boundingBox.height + 10.0;

    final croppedImage = imglib.copyCrop(convertedImage, x.round(), y.round(), w.round(), h.round());
    return imglib.copyResizeCropSquare(croppedImage, 112);
    // imglib.Image resizedImage = imglib.copyResizeCropSquare(image, 112);
    // return imglib.copyCrop(convertedImage, x.round(), y.round(), w.round(), h.round());
  }

  static imglib.Image convertCameraImage(CameraImage image) {
    var img = _convertToImage(image)!;
    var img1 = imglib.copyRotate(img, 90);
    return img1;
  }

  static imglib.Image? _convertToImage(CameraImage image) {
    try {
      if (image.format.group == ImageFormatGroup.yuv420) {
        print("============ YUV420 ============");
        return _convertYUV420(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888(image);
      }
      throw Exception('Image format not supported');
    } catch (e) {
      print("ERROR:" + e.toString());
    }
    return null;
  }

  static imglib.Image _convertBGRA8888(CameraImage image) {
    return imglib.Image.fromBytes(
      image.width,
      image.height,
      image.planes[0].bytes,
      format: imglib.Format.bgra,
    );
  }

  static const shift = (0xFF << 24);
  static imglib.Image _convertYUV420(CameraImage image) {
    // final int width = image.width;
    // final int height = image.height;
    //
    // // const int hexFF = 0xFF000000;
    //
    //
    // final int uvyButtonStride = image.planes[1].bytesPerRow;
    // final int uvPixelStride = image.planes[1].bytesPerPixel!;
    //
    //
    // var img = imglib.Image(width, height);
    // const shift = (0xFF << 24);
    //
    // for (int x = 0; x < width; x++) {
    //   for (int y = 0; y < height; y++) {
    //     final int uvIndex =
    //         uvPixelStride * (x / 2).floor() + uvyButtonStride * (y / 2).floor();
    //     final int index = y * width + x;
    //     final yp = image.planes[0].bytes[index];
    //     final up = image.planes[1].bytes[uvIndex];
    //     final vp = image.planes[2].bytes[uvIndex];
    //     int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
    //     int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
    //         .round()
    //         .clamp(0, 255);
    //     int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
    //     img.data[index] = shift | (b << 16) | (g << 8) | r;
    //   }
    // }

    // final int width = image.width;
    // final int height = image.height;
    // final int uvRowStride = image.planes[1].bytesPerRow;
    //
    // final int uvPixelStride = image.planes[1].bytesPerPixel!;
    //
    // print("bpr: " + image.planes[0].bytesPerRow.toString());
    // print("w: " + image.width.toString());
    //
    // print("uvRowStride: " + uvRowStride.toString());
    // print("uvPixelStride: " + uvPixelStride.toString());
    //
    // // imgLib -> Image package from https://pub.dartlang.org/packages/image
    // var img = imglib.Image(width, height); // Create Image buffer
    //
    // //Fill image buffer with plane[0] from YUV420_888
    // for(int x=0; x < width; x++) {
    //   for(int y=0; y < height; y++) {
    //     final int uvIndex = uvPixelStride * (x/2).floor() + uvRowStride*(y/2).floor();
    //     // final int index = y * width + x;
    //     final int index = y * uvRowStride + x;
    //
    //
    //     final yp = image.planes[0].bytes[index];
    //     final up = image.planes[1].bytes[uvIndex];
    //     final vp = image.planes[2].bytes[uvIndex];
    //     // Calculate pixel color
    //     int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
    //     int g = (yp - up * 46549 / 131072 + 44 -vp * 93604 / 131072 + 91).round().clamp(0, 255);
    //     int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
    //     // color: 0x FF  FF  FF  FF
    //     //           A   B   G   R
    //     img.data[index] = shift | (b << 16) | (g << 8) | r;
    //   }
    // }
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;
    var img = imglib.Image(width, height);
    for (int x = 0; x < width; x++) { // Fill image buffer with plane[0] from YUV420_888
      for (int y = 0; y < height; y++) {
        final int uvIndex = uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * uvRowStride + x; // Use the row stride instead of the image width as some devices pad the image data, and in those cases the image width != bytesPerRow. Using width will give you a distored image.
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

  static Float32List imageToByteListFloat32(imglib.Image image) {
    var convertedBytes = Float32List(1 * 112 * 112 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < 112; i++) {
      for (var j = 0; j < 112; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (imglib.getRed(pixel) - 128) / 128;
        buffer[pixelIndex++] = (imglib.getGreen(pixel) - 128) / 128;
        buffer[pixelIndex++] = (imglib.getBlue(pixel) - 128) / 128;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }
}