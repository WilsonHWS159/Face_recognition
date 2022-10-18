import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:face_recognize/ui/camera/cameraViewModel.dart';
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => viewModel,
        child: Consumer<CameraViewModel>(builder: (context, vm, _) =>
          Scaffold(
              appBar: AppBar(title: const Text('Take a picture')),
              body: content(vm),
              floatingActionButton: vm.showInputDialog ? null : Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    onPressed: () => viewModel.onStopClick(),
                    child: const Icon(Icons.stop),
                  ),
                  FloatingActionButton(
                    onPressed: () =>viewModel.onAddClick(),
                    child: const Icon(Icons.add),
                  ),
                ],
              )
          )
        )
    );

  }

  Widget content(CameraViewModel vm) {
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
          content: Column(
            children: [
              Image.memory(
                imglib.encodePng(vm.inputDialogImage) as Uint8List,
                height: 64,
                width: 64,
              ),
              TextField(
                onChanged: (t) => text = t,
              )
            ],
            mainAxisSize: MainAxisSize.min,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                vm.onCancelClick();
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
}
