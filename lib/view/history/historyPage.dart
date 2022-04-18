

import 'dart:typed_data';

import 'package:face_recognize/fileRepo.dart';
import 'package:face_recognize/view/history/historyViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:image/image.dart' as imglib;


class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {

  final viewModel = HistoryViewModel();

  Widget createBody(HistoryViewModel vm) {
    // for (final data in vm.detectedDB.historyPersonList) {
    //  
    // }
    final data = vm.data;
    
    return ListView.builder(
      itemBuilder: ((context, index) {
        return Padding(
          padding: EdgeInsets.all(24),
          child:Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.memory(data[index].image, height: 64, width: 64),
              ),
              SizedBox(width: 24),
              Text(data[index].name),
              Spacer(),
              IconButton(
                onPressed: () {

                },
                icon: Icon(
                  Icons.delete,
                  color: Colors.blue,
                )
              )
            ],
          ),
        );
      }),
      itemCount: data.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: ChangeNotifierProvider(
          create: (context) => viewModel,
          child: Consumer<HistoryViewModel>(builder: (context, vm, _) {
            return createBody(vm);
          })
      ),
    );
  }
}
