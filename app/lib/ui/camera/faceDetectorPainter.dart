
import 'dart:io';


import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class PaintData {
  Face face;
  String? name;

  PaintData(this.face, this.name);
}

class FaceDetectorPainter extends CustomPainter {

  FaceDetectorPainter(this.paintData, this.absoluteImageSize, this.rotation);

  final List<PaintData> paintData;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;


    for (final data in paintData) {
      final l = translateX(data.face.boundingBox.left, rotation, size, absoluteImageSize);
      final t = translateY(data.face.boundingBox.top, rotation, size, absoluteImageSize);
      final r = translateX(data.face.boundingBox.right, rotation, size, absoluteImageSize);
      final b = translateY(data.face.boundingBox.bottom, rotation, size, absoluteImageSize);

      if (data.name != null) {
        final span = TextSpan(
            style: TextStyle(color: Colors.lightGreenAccent),
            text: data.name
        );

        final painter = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
        painter.layout();
        painter.paint(canvas, Offset(l, b));

        paint.color = Colors.lightGreenAccent;
      } else {
        paint.color = Colors.blueAccent;
      }

      canvas.drawRect(
        Rect.fromLTRB(l, t, r, b),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.paintData != paintData;
  }
}

double translateX(double x, InputImageRotation rotation, Size size, Size absoluteImageSize) {
  switch (rotation) {
    case InputImageRotation.Rotation_90deg:
      return x *
          size.width /
          (Platform.isIOS ? absoluteImageSize.width : absoluteImageSize.height);
    case InputImageRotation.Rotation_270deg:
      return size.width -
          x *
              size.width /
              (Platform.isIOS
                  ? absoluteImageSize.width
                  : absoluteImageSize.height);
    default:
      return x * size.width / absoluteImageSize.width;
  }
}

double translateY(double y, InputImageRotation rotation, Size size, Size absoluteImageSize) {
  switch (rotation) {
    case InputImageRotation.Rotation_90deg:
    case InputImageRotation.Rotation_270deg:
      return y *
          size.height /
          (Platform.isIOS ? absoluteImageSize.height : absoluteImageSize.width);
    default:
      return y * size.height / absoluteImageSize.height;
  }
}

