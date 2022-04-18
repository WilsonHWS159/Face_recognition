import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:face_recognize/view/camera/cameraViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:image/image.dart' as imglib;


// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraViewModel viewModel;

  @override
  void initState() {
    super.initState();

    viewModel = CameraViewModel(widget.camera);
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Widget createBody(CameraViewModel vm) {
    if (!vm.cameraController.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    String text = "";

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(vm.cameraController),
        if (vm.painter != null) CustomPaint(painter: vm.painter),
        if (vm.showInputDialog) AlertDialog(
          title: const Text('AlertDialog Title'),
          content: Column(
            children: [
              Image.memory(imglib.encodePng(vm.inputDialogImage) as Uint8List),
              TextField(
                onChanged: (s) => text = s,
              )
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                vm.onCancelClick();

                // Navigator.pop(context, 'Cancel');
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                vm.onOKClick(text);
              },
              child: const Text('OK'),
            ),
          ],
        )
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      body: ChangeNotifierProvider(
        create: (context) => viewModel,
        child: Consumer<CameraViewModel>(builder: (context, vm, _) {
          return createBody(vm);
        })
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          viewModel.onAddClick();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
// class DisplayPictureScreen extends StatelessWidget {
//   final String imagePath;
//
//   const DisplayPictureScreen({Key? key, required this.imagePath})
//       : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Display the Picture')),
//       // The image is stored as a file on the device. Use the `Image.file`
//       // constructor with the given path to display the image.
//       body: Image.file(File(imagePath)),
//     );
//   }
// }