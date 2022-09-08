import 'dart:async';

import 'package:camera/camera.dart';
import 'package:face_recognize/fileRepo.dart';
import 'package:face_recognize/ui/ble_detect/bleDetectPage.dart';
import 'package:face_recognize/ui/bluetoothPage.dart';
import 'package:face_recognize/ui/camera/cameraPage.dart';
import 'package:face_recognize/ui/history/historyPage.dart';
import 'package:face_recognize/ui/label/labelPage.dart';
import 'package:flutter/material.dart';


Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  FileRepo().createFolder("image");

  runApp(
      MaterialApp(
          home: MainPage(camera: firstCamera,)
      )
  );
}

class MainPage extends StatelessWidget {
  const MainPage({Key? key, required this.camera,}) : super(key: key);

  final CameraDescription camera;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MainPage'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            OutlinedButton(
              child: Text("ble detect"),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BLEDetectPage())
                );
              },
            ),
            OutlinedButton(
              child: Text("camera"),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TakePictureScreen(camera: camera,))
                );
              },
            ),
            OutlinedButton(
              child: Text("Bluetooth"),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BluetoothPage())
                );
              },
            ),
            SizedBox(height: 24),
            OutlinedButton(
              child: Text("Label"),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LabelPage())
                );
              },
            ),
            SizedBox(height: 24),
            OutlinedButton(
              child: Text("History"),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HistoryPage())
                );
              }
            )
          ],
        ),
      ),
    );
  }
}

