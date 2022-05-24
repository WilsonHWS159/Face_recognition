import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:flutter/material.dart';


class BluetoothPage extends StatefulWidget {
  BluetoothPage({Key? key}) : super(key: key);

  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  final List<BluetoothDevice> devicesList = new List<BluetoothDevice>.empty(growable: true);

  final Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();

  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}



class _BluetoothPageState extends State<BluetoothPage> {
  final _writeController = TextEditingController();
  BluetoothDevice? _connectingDevice;
  BluetoothDeviceState? _state;
  BluetoothDevice? _connectedDevice;
  List<BluetoothService> _services = new List<BluetoothService>.empty(growable: true);

  void _addDeviceToList(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device) && device.name != '') {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addDeviceToList(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceToList(result.device);
      }
    });
    widget.flutterBlue.startScan(timeout: Duration(seconds: 4));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text("Title"),
    ),
    body: RefreshIndicator(
      onRefresh: () => FlutterBluePlus.instance.startScan(timeout: Duration(seconds: 4)),
      child: FindDevicesScreen(),
    ),
    floatingActionButton: StreamBuilder<bool>(
      stream: FlutterBluePlus.instance.isScanning,
      initialData: false,
      builder: (c, snapshot) {
        if (snapshot.data!) {
          return FloatingActionButton(
            child: Icon(Icons.stop),
            onPressed: () => FlutterBluePlus.instance.stopScan(),
            backgroundColor: Colors.red,
          );
        } else {
          return FloatingActionButton(
              child: Icon(Icons.search),
              onPressed: () => FlutterBluePlus.instance
                  .startScan(timeout: Duration(seconds: 4)));
        }
      },
    ),
  );

}

class FindDevicesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<List<BluetoothDevice>>(
              stream: Stream.periodic(Duration(seconds: 2))
                  .asyncMap((_) => FlutterBluePlus.instance.connectedDevices),
              initialData: [],
              builder: (c, snapshot) => Column(
                children: snapshot.data!.map((d) => ListTile(
                  title: Text(d.name),
                  subtitle: Text(d.id.toString()),
                  trailing: StreamBuilder<BluetoothDeviceState>(
                    stream: d.state,
                    initialData: BluetoothDeviceState.disconnected,
                    builder: (c, snapshot) {
                      if (snapshot.data ==
                          BluetoothDeviceState.connected) {
                        return ElevatedButton(
                          child: Text('OPEN'),
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      DeviceScreen(device: d))),
                        );
                      }
                      return Text(snapshot.data.toString());
                    },
                  ),
                )).toList(),
              ),
            ),
            StreamBuilder<List<ScanResult>>(
              stream: FlutterBluePlus.instance.scanResults,
              initialData: [],
              builder: (c, snapshot) => Column(
                children: snapshot.data!.map((d) => ScanResultTile(
                  result: d,
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) {
                    d.device.connect();
                    return DeviceScreen(device: d.device);
                  })),
                ))
                    .toList()

              ),
            ),
          ],
        )
      ),
    );
  }

}


class DeviceScreen extends StatelessWidget {
  const DeviceScreen({Key? key, required this.device}) : super(key: key);

  final BluetoothDevice device;

  List<int> _getRandomBytes() {
    final math = Random();
    return [
      math.nextInt(255),
      math.nextInt(255),
      math.nextInt(255),
      math.nextInt(255)
    ];
  }

  List<Widget> _buildServiceTiles(List<BluetoothService> services) {
    return services
        .map(
          (s) => ServiceTile(
        service: s,
        characteristicTiles: s.characteristics
            .map(
              (c) => CharacteristicTile(
            characteristic: c,
            onReadPressed: () => c.read(),
            onWritePressed: (str) {
              c.write(utf8.encode(str));
            },
            onNotificationPressed: () {
              c.setNotifyValue(true);
            },
            descriptorTiles: c.descriptors
                .map(
                  (d) => DescriptorTile(
                descriptor: d,
                onReadPressed: () => d.read(),
                onWritePressed: () => d.write(_getRandomBytes()),
              ),
            )
                .toList(),
          ),
        )
            .toList(),
      ),
    )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        actions: <Widget>[
          StreamBuilder<BluetoothDeviceState>(
            stream: device.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) {
              VoidCallback? onPressed;
              String text;
              switch (snapshot.data) {
                case BluetoothDeviceState.connected:
                  onPressed = () => device.disconnect();
                  text = 'DISCONNECT';
                  break;
                case BluetoothDeviceState.disconnected:
                  onPressed = () => device.connect();
                  text = 'CONNECT';
                  break;
                default:
                  onPressed = null;
                  text = snapshot.data.toString().substring(21).toUpperCase();
                  break;
              }
              return TextButton(
                  onPressed: onPressed,
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .primaryTextTheme
                        .button
                        ?.copyWith(color: Colors.white),
                  ));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<BluetoothDeviceState>(
              stream: device.state,
              initialData: BluetoothDeviceState.connecting,
              builder: (c, snapshot) => ListTile(
                leading: (snapshot.data == BluetoothDeviceState.connected)
                    ? Icon(Icons.bluetooth_connected)
                    : Icon(Icons.bluetooth_disabled),
                title: Text(
                    'Device is ${snapshot.data.toString().split('.')[1]}.'),
                subtitle: Text('${device.id}'),
                trailing: StreamBuilder<bool>(
                  stream: device.isDiscoveringServices,
                  initialData: false,
                  builder: (c, snapshot) => IndexedStack(
                    index: snapshot.data! ? 1 : 0,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: () => device.discoverServices(),
                      ),
                      IconButton(
                        icon: SizedBox(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.grey),
                          ),
                          width: 18.0,
                          height: 18.0,
                        ),
                        onPressed: null,
                      )
                    ],
                  ),
                ),
              ),
            ),
            StreamBuilder<int>(
              stream: device.mtu,
              initialData: 0,
              builder: (c, snapshot) => ListTile(
                title: Text('MTU Size'),
                subtitle: Text('${snapshot.data} bytes'),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => device.requestMtu(512),
                ),
              ),
            ),
            StreamBuilder<List<BluetoothService>>(
              stream: device.services,
              initialData: [],
              builder: (c, snapshot) {
                return Column(
                  children: _buildServiceTiles(snapshot.data!),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


class ServiceTile extends StatelessWidget {
  final BluetoothService service;
  final List<CharacteristicTile> characteristicTiles;

  const ServiceTile(
      {Key? key, required this.service, required this.characteristicTiles})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (characteristicTiles.length > 0) {
      return ExpansionTile(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Service'),
            Text('0x${service.uuid.toString().toUpperCase().substring(4, 8)}',
                style: Theme.of(context).textTheme.bodyText1?.copyWith(
                    color: Theme.of(context).textTheme.caption?.color))
          ],
        ),
        children: characteristicTiles,
      );
    } else {
      return ListTile(
        title: Text('Service'),
        subtitle:
        Text('0x${service.uuid.toString().toUpperCase().substring(4, 8)}'),
      );
    }
  }
}

class CharacteristicTile extends StatelessWidget {
  final BluetoothCharacteristic characteristic;
  final List<DescriptorTile> descriptorTiles;
  final VoidCallback? onReadPressed;
  final Function(String)? onWritePressed;
  final VoidCallback? onNotificationPressed;

  final imgData = List<int>.empty(growable: true);
  // Img.Image? img;
  Uint8List? imgListData;

  CharacteristicTile(
      {Key? key,
        required this.characteristic,
        required this.descriptorTiles,
        this.onReadPressed,
        this.onWritePressed,
        this.onNotificationPressed})
      : super(key: key) {


    final v = characteristic.value;
    v.listen((event) {
      final int index = event[0] * 256 + event[1];

      imgData.addAll(event.sublist(2));
      DateTime now = DateTime.now();
      print("Index: $index, Time: $now");

      if (index == 0) {
        print("SUCCESS =================");

        if ('0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}' == "0x2A1A") {
          textTest.data = Uint8List.fromList(imgData);
          textTest.update();
        } else {
          imageTest.imgListData = Uint8List.fromList(imgData);
          imageTest.update();
        }


      }
    });
  }

  final ImageTest imageTest = new ImageTest();
  final TextTest textTest = new TextTest();

  String write = "";

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: ListTile(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Characteristic'),
            Text(
                '0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}',
                style: Theme.of(context).textTheme.bodyText1?.copyWith(
                    color: Theme.of(context).textTheme.caption?.color))
          ],
        ),
        subtitle: '0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}' == "0x2A1A" ? textTest :
        imageTest,
            // Text(value.toString()),
        contentPadding: EdgeInsets.all(0.0),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (characteristic.properties.read)
            IconButton(
              icon: Icon(
                Icons.file_download,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
              ),
              onPressed: onReadPressed,
            ),
          if (characteristic.properties.write)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60.0,
                  child: TextField(
                    onChanged: (s) => write = s
                  )
                ),
                IconButton(
                  icon: Icon(Icons.file_upload,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                  onPressed: () => onWritePressed?.call(write),
                ),
              ],
            ),
          if (characteristic.properties.notify)
            IconButton(
                icon: Icon(
                    characteristic.isNotifying
                        ? Icons.sync_disabled
                        : Icons.sync,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                onPressed: () {
                  imgData.clear();
                  onNotificationPressed?.call();
                }
            )
        ],
      ),
      children: descriptorTiles,
    );
    // return StreamBuilder<List<int>>(
    //   stream: characteristic.value,
    //   initialData: characteristic.lastValue,
    //   builder: (c, snapshot) {
    //     return ExpansionTile(
    //       title: ListTile(
    //         title: Column(
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: <Widget>[
    //             Text('Characteristic'),
    //             Text(
    //                 '0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}',
    //                 style: Theme.of(context).textTheme.bodyText1?.copyWith(
    //                     color: Theme.of(context).textTheme.caption?.color))
    //           ],
    //         ),
    //         subtitle: Column(mainAxisAlignment: MainAxisAlignment.center,
    //           children: <Widget>[
    //             // Text(value.toString()),
    //             img == null ? Text("--") : Image.memory(imgListData!)
    //           ],
    //         ),
    //         contentPadding: EdgeInsets.all(0.0),
    //       ),
    //       trailing: Row(
    //         mainAxisSize: MainAxisSize.min,
    //         children: <Widget>[
    //           if (characteristic.properties.read)
    //             IconButton(
    //               icon: Icon(
    //                 Icons.file_download,
    //                 color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
    //               ),
    //               onPressed: onReadPressed,
    //             ),
    //           if (characteristic.properties.write)
    //             IconButton(
    //               icon: Icon(Icons.file_upload,
    //                   color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
    //               onPressed: onWritePressed,
    //             ),
    //           if (characteristic.properties.notify)
    //             IconButton(
    //               icon: Icon(
    //                   characteristic.isNotifying
    //                       ? Icons.sync_disabled
    //                       : Icons.sync,
    //                   color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
    //               onPressed: () => {
    //                 onNotificationPressed?.call()
    //               }
    //             )
    //         ],
    //       ),
    //       children: descriptorTiles,
    //     );
    //   },
    // );
  }
}

class ImageTest extends StatefulWidget {
  ImageTest({Key? key}) : super(key: key);

  Uint8List? imgListData;

  final _ImageTestState state = new _ImageTestState();

  void update() {
    state.change();
  }

  @override
  State<ImageTest> createState() => state;
}

class _ImageTestState extends State<ImageTest> {
  @override
  Widget build(BuildContext context) {
    return widget.imgListData == null ? Text("") : Image.memory(widget.imgListData!);
  }

  void change() {
    setState(() {
      // this.text = this.text == "original" ? "changed" : "original";
    });
  }
}

class TextTest extends StatefulWidget {
  TextTest({Key? key}) : super(key: key);

  Uint8List? data;

  final _TextTestState state = new _TextTestState();


  void update() {
    state.change();
  }

  @override
  State<TextTest> createState() => state;
}

class _TextTestState extends State<TextTest> {
  @override
  Widget build(BuildContext context) {
    return widget.data == null ? Text("") : Text(String.fromCharCodes(widget.data!));
  }

  void change() {
    setState(() {
      // this.text = this.text == "original" ? "changed" : "original";
    });
  }
}




class DescriptorTile extends StatelessWidget {
  final BluetoothDescriptor descriptor;
  final VoidCallback? onReadPressed;
  final VoidCallback? onWritePressed;

  const DescriptorTile(
      {Key? key,
        required this.descriptor,
        this.onReadPressed,
        this.onWritePressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Descriptor'),
          Text('0x${descriptor.uuid.toString().toUpperCase().substring(4, 8)}',
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(color: Theme.of(context).textTheme.caption?.color))
        ],
      ),
      subtitle: StreamBuilder<List<int>>(
        stream: descriptor.value,
        initialData: descriptor.lastValue,
        builder: (c, snapshot) => Text(snapshot.data.toString()),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            icon: Icon(
              Icons.file_download,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            onPressed: onReadPressed,
          ),
          IconButton(
            icon: Icon(
              Icons.file_upload,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            onPressed: onWritePressed,
          )
        ],
      ),
    );
  }
}

class AdapterStateTile extends StatelessWidget {
  const AdapterStateTile({Key? key, required this.state}) : super(key: key);

  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.redAccent,
      child: ListTile(
        title: Text(
          'Bluetooth adapter is ${state.toString().substring(15)}',
          style: Theme.of(context).primaryTextTheme.subtitle2,
        ),
        trailing: Icon(
          Icons.error,
          color: Theme.of(context).primaryTextTheme.subtitle2?.color,
        ),
      ),
    );
  }
}

class ScanResultTile extends StatelessWidget {
  const ScanResultTile({Key? key, required this.result, this.onTap})
      : super(key: key);

  final ScanResult result;
  final VoidCallback? onTap;

  Widget _buildTitle(BuildContext context) {
    if (result.device.name.length > 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            result.device.name,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            result.device.id.toString(),
            style: Theme.of(context).textTheme.caption,
          )
        ],
      );
    } else {
      return Text(result.device.id.toString());
    }
  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.caption),
          SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .caption
                  ?.apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'
        .toUpperCase();
  }

  String getNiceManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) {
      return 'N/A';
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add(
          '${id.toRadixString(16).toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  String getNiceServiceData(Map<String, List<int>> data) {
    if (data.isEmpty) {
      return 'N/A';
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add('${id.toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle(context),
      leading: Text(result.rssi.toString()),
      trailing: ElevatedButton(
        child: Text('CONNECT'),
        style: ElevatedButton.styleFrom(
          primary: Colors.black,
          onPrimary: Colors.white,
        ),
        onPressed: (result.advertisementData.connectable) ? onTap : null,
      ),
      children: <Widget>[
        _buildAdvRow(
            context, 'Complete Local Name', result.advertisementData.localName),
        _buildAdvRow(context, 'Tx Power Level',
            '${result.advertisementData.txPowerLevel ?? 'N/A'}'),
        _buildAdvRow(context, 'Manufacturer Data',
            getNiceManufacturerData(result.advertisementData.manufacturerData)),
        _buildAdvRow(
            context,
            'Service UUIDs',
            (result.advertisementData.serviceUuids.isNotEmpty)
                ? result.advertisementData.serviceUuids.join(', ').toUpperCase()
                : 'N/A'),
        _buildAdvRow(context, 'Service Data',
            getNiceServiceData(result.advertisementData.serviceData)),
      ],
    );
  }
}