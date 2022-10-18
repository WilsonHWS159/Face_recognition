import 'package:face_recognize/ui/label/lableViewModel.dart';
import 'package:flutter/material.dart';

class LabelPage extends StatelessWidget {
  LabelPage({Key? key}) : super(key: key);

  final vm = LabelViewModel();

  @override
  Widget build(BuildContext context) => StreamBuilder<List<UnlabeledData>>(
      stream: vm.unlabeled,
      initialData: [],
      builder: (c, snapshot) => Scaffold(
          appBar: AppBar(
            title: Text("Label Page"),
          ),
          body: SingleChildScrollView(
            child: Column(
                children: [
                  StreamBuilder<bool>(
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
                                        onPressed: () => vm.startLoadingUnlabeled(),
                                        child: Text("Sync unlabeled")
                                    ),
                                ]
                            )
                        );
                      }
                  ),
                  Column(
                    children: snapshot.data!.map((data) => ExpansionTile(
                      title: Row(
                        children: [
                          Text(data.date),
                          SizedBox(width: 12),
                          Flexible(
                            child: TextField(
                              onChanged: (String value) {
                                data.name = value;
                              },
                            ),
                            flex: 1,
                          )
                        ],
                      ),
                      trailing: Checkbox(
                        value: data.selected,
                        onChanged: (bool? value) {
                          data.selected = value!;
                          vm.dataChanged(snapshot.data!);
                        },
                      ),
                      children: data.images.map((e) => imageListItem(e, c)).toList(),
                    )).toList(),
                  )
                ]
            ),
          ),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () {
              vm.createLabeled(snapshot.data!);
            }
        )
      )
  );

  Widget imageListItem(UnlabeledImageData data, BuildContext c) => ListTile(
    leading: data.faceImg == null ? Container(
      width: 20.0,
      height: 20.0,
      decoration: new BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
    ) : CircleAvatar(
      foregroundImage: Image.memory(data.faceImg!).image,
    ),
    title: Row(
      children: [
        Text(data.time),
        if (data.faceImg == null) IconButton(
          onPressed: () => vm.loadImage(data),
          icon: Icon(
            Icons.file_download,
            color: Theme.of(c).iconTheme.color?.withOpacity(0.5),
          )
        )
      ],
    ),
  );
}
