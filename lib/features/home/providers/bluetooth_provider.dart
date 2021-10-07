import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';
import 'package:smalltalk/features/login/model/login_config_response.dart';
import 'package:smalltalk/sip_library/sip_engine.dart';
import 'package:smalltalk/utils/commons/enums.dart';
import 'package:logger/logger.dart';
import 'package:smalltalk/utils/constants/global_constants.dart';
import 'package:smalltalk/features/settings/bluetooth_service_provider/bluetooth_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class BluetoothDevice {
  String id;
  String name;

  BluetoothDevice(this.id, this.name) {
  }
}

class BluetoothProvider extends ChangeNotifier {
  Logger _logger = Logger();
  BluetoothManager _bt = BluetoothManager();

  String connectedDeviceName;

  startScan(Function(String, String) onConnect) {
    _bt.startScan(onConnect);
  }

  disconnect() {
    _bt.disconnect();
  }

}
