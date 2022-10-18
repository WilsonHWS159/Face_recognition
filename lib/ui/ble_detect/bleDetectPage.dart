import 'dart:typed_data';

import 'package:face_recognize/ui/ble_detect/bleDetectViewModel.dart';

import 'package:flutter/material.dart';

import '../camera/faceDetectorPainter.dart';

class BLEDetectPage extends StatelessWidget {
  BLEDetectPage({Key? key}) : super(key: key);

  final BLEDetectViewModel vm = BLEDetectViewModel();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text("Detect Page"),
    ),
    body: Column(
      children: [
        StreamBuilder<bool>(
            stream: vm.deviceAllowed,
            initialData: false,
            builder: (c, allowed) {
              return Padding(
                padding: EdgeInsets.all(20),
                child: Text("Connected: ${allowed.data}"),
              );
            }
        ),
        Container(
            width: 300,
            height: 300,
            alignment: Alignment.center,
            child: Padding(
                padding: EdgeInsets.all(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    StreamBuilder<Uint8List?>(
                        stream: vm.imgListDataStream,
                        initialData: null,
                        builder: (c, img) {
                          final value = img.data;
                          return value == null ? Text("waiting for streaming") : Image.memory(value);
                        }
                    ),
                    StreamBuilder<FaceDetectorPainter?>(
                        stream: vm.boxPainterStream,
                        initialData: null,
                        builder: (c, painter) {
                          final value = painter.data;
                          return value == null ? Text("") : CustomPaint(painter: value);
                        }
                    ),
                  ],
                )
            )
        )
      ]
    ),
    floatingActionButton: FloatingActionButton(
        child: Icon(Icons.search),
        onPressed: () => vm.startLoadingImage()
    )
  );


}


