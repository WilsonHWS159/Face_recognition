

import 'dart:typed_data';

import 'package:face_recognize/view/ble_detect/BLEDetectViewModel.dart';

import 'package:flutter/material.dart';

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
        Padding(
          padding: EdgeInsets.all(20),
          child: StreamBuilder<Uint8List?>(
              stream: vm.imgListDataStream,
              initialData: null,
              builder: (c, img) {
                final value = img.data;
                return value == null ? Text("waiting for streaming") : Image.memory(value);
              }
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


