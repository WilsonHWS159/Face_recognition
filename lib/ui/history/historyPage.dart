

import 'dart:typed_data';

import 'package:face_recognize/fileRepo.dart';
import 'package:face_recognize/ui/history/historyViewModel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final data = vm.data;
    
    return Padding(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          StreamBuilder(
            stream: vm.deviceAllowed,
            initialData: false,
            builder: (c, allowed) {
              return Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                      children: [
                        Text("Connected: ${allowed.data}"),
                        if (allowed.data == true)
                          TextButton(
                              onPressed: () => vm.sendJsonToBLEServer(),
                              child: Text("Send labeled")
                          ),
                      ]
                  )
              );
            }
          ),
          ListView.separated(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemBuilder: (context, index) =>
                  ExpansionTile(
                    leading: CircleAvatar(
                      foregroundImage: Image.memory(data[index].subData[0].image).image,
                    ),
                    title: Row(
                      children: [
                        Text(data[index].name),
                        Spacer(),
                        IconButton(
                            onPressed: () {
                              vm.delete(data[index].name);
                            },
                            icon: Icon(
                              Icons.delete,
                              color: Colors.blue,
                            )
                        )
                      ],
                    ),
                    children: [
                      SubList(data: data[index], vm: vm)
                    ],
                  ),
              itemCount: data.length,
              separatorBuilder: (context, index) => Divider()
          )
        ],
      ),
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

class SubList extends StatefulWidget {
  const SubList({Key? key, required this.data, required this.vm}) : super(key: key);

  final HistoryViewData data;
  final HistoryViewModel vm;

  @override
  State<SubList> createState() => _SubListState();
}

class _SubListState extends State<SubList> {

  bool editing = false;

  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
            title: editing ? TextField(
              controller: controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Note',
              ),
            ) : Text(widget.data.note),
            trailing: IconButton(
                onPressed: () {
                  if (editing) {
                    widget.vm.updateNote(widget.data.name, controller.text);
                  }

                  setState(() {
                    editing = !editing;
                  });
                },
                icon: Icon(
                  !editing ? Icons.edit : Icons.save,
                  color: Colors.blue,
                )
            )
        ),
        ListView.builder(
          shrinkWrap: true,
          itemBuilder: (context, index) =>
              ListTile(
                  leading: CircleAvatar(
                    foregroundImage: Image.memory(widget.data.subData[index].image).image,
                  ),
                  title: Text(
                      DateFormat("yyyy-MM-dd HH:mm").format(widget.data.subData[index].date)
                  ),
                  trailing: IconButton(
                      onPressed: () {
                        widget.vm.deleteSubData(widget.data.name, widget.data.subData[index].date);
                      },
                      icon: Icon(
                        Icons.delete,
                        color: Colors.blue,
                      )
                  )

              ),
          itemCount: widget.data.subData.length,
        )
      ],
    );
  }
}

