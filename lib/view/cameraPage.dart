import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:face_recognize/view/cameraViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  // late CameraController _controller;
  // late Future<void> _initializeControllerFuture;

  late CameraViewModel viewModel;

  @override
  void initState() {
    super.initState();

    viewModel = CameraViewModel(widget.camera);
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    // _controller.dispose();
    viewModel.dispose();
    super.dispose();
  }

  Widget createBody(CameraViewModel vm) {
    if (!vm.cameraController.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(vm.cameraController),
        if (vm.painter != null) CustomPaint(painter: vm.painter)
      ],
    );

    //return CameraPreview(vm.cameraController);
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
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key? key, required this.imagePath})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(File(imagePath)),
    );
  }
}