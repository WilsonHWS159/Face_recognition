

import 'dart:ffi';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEModel {
  static final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;

  static Future<void> startScan() {
    return _flutterBlue.startScan(timeout: Duration(seconds: 5));
  }

  static Future<void> stopScan() {
    return _flutterBlue.stopScan();
  }

  static Stream<bool> isScanning() {
    return _flutterBlue.isScanning;
  }

  static Future<List<BluetoothDevice>> getConnectedDevice() {
    return _flutterBlue.connectedDevices;
  }

  static Stream<List<ScanResult>> getScanResult() {
    return _flutterBlue.scanResults;
  }
}