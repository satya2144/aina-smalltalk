import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:smalltalk/utils/constants/global_constants.dart';
import 'package:smalltalk/utils/constants/string_constants.dart';
import 'package:rxdart/rxdart.dart';
import 'package:logger/logger.dart';

import 'bluetooth_listener.dart';

enum BluetoothState { Idle, Connecting, Connected }
enum Led { Red, Green, Blue }

class BluetoothManager {
  final _logger = Logger();

  BluetoothDeviceListener _listener;
  BluetoothState _state = BluetoothState.Idle;
  final flutterReactiveBle = FlutterReactiveBle();
  String _connectedDevice;
  final pttLongPress = new BehaviorSubject<bool>();
  bool mfbPressed = false;
  int _previousValue = 0;

  StreamSubscription<ConnectionStateUpdate> _connection;
  Function(String, String) _onConnect;
  static final BluetoothManager _singleton = BluetoothManager._internal();

  factory BluetoothManager() => _singleton;

  BluetoothManager._internal() {
    pttLongPress
        .debounceTime(
            Duration(milliseconds: GlobalConstants.pttPrivateCallResponseTime))
        .listen((islongPress) {
      if (islongPress) {
        _listener.onMultifunctionLongPress();
      }
    });
    flutterReactiveBle.statusStream.listen((event) {
      if (event == BleStatus.ready) {
        _connectLinkedDevice();
      }
    });
  }

  setListener(BluetoothDeviceListener listener) { 
    _listener = listener;
  }

  static getInstance() {
    return _singleton;
  }

  Future<void> _connectLinkedDevice() async {
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    await _prefs.then((SharedPreferences prefs) async {
      String deviceId = prefs.getString(StringConstants.btDeviceId) ?? null;
      if (deviceId != null) {
        connectDevice(deviceId, prefs.getString(StringConstants.btDeviceName));
      }
    });
  }

  void startScan(Function(String, String) onConnect) {
    _onConnect = onConnect;
    start();
  }

  void start() {
    flutterReactiveBle.scanForDevices(
        withServices: [Uuid.parse(StringConstants.bluetoothUUID)],
        scanMode: ScanMode.lowLatency).listen((device) {
      connectDevice(device.id, device.name);
    }, onError: (err) {
      _state = BluetoothState.Idle;
    });
  }

  void connectDevice(String id, String name) {
    if (_state == BluetoothState.Idle) {
      _state = BluetoothState.Connecting;
      _connection = flutterReactiveBle
          .connectToDevice(
        id: id,
        connectionTimeout:
            Duration(seconds: GlobalConstants.bluetoothConnectionTimeOut),
      ).listen((connectionState) async {
        if (connectionState.connectionState ==
            DeviceConnectionState.connected) {
          Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
          await _prefs.then((SharedPreferences prefs) async {
            prefs.setString(StringConstants.btDeviceId, id);
            if(name != null) {
              prefs.setString(StringConstants.btDeviceName, name);
            }
          });

          onConnected(id, name);
          _state = BluetoothState.Connected;
          _connectedDevice = id;
          flutterReactiveBle
              .subscribeToCharacteristic(QualifiedCharacteristic(
                  characteristicId: Uuid.parse(
                      StringConstants.bluetoothButtonCharactersticsUUID),
                  serviceId: Uuid.parse(StringConstants.bluetoothServicesUUID),
                  deviceId: id))
              .listen((val) {
            onValue(val);
          });
        } else if (connectionState.connectionState ==
            DeviceConnectionState.disconnected) {
          _state = BluetoothState.Idle;
          _listener.onDeviceDisconnected();
          start();
        } else {
          _state = BluetoothState.Idle;
          _listener.onDeviceDisconnected();
          start();
        }
        // Handle connection state updates
      }, onError: (error) async {
        _state = BluetoothState.Idle;
        Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
        await _prefs.then((SharedPreferences prefs) async {
          prefs.setString(StringConstants.btDeviceId, null);
          prefs.setString(StringConstants.btDeviceName, null);
          start();
        });
      });
    }
  }

  disconnect() {
    if(_connection != null) {
      _connection.cancel();
      _connection = null;
      _state = BluetoothState.Idle;
      _listener.onDeviceDisconnected();
    }
  }

  onConnected(String id, String name) {
    if(_onConnect != null) {
      _onConnect(id, name);
    }
    _listener.onDeviceConnected();    
  }

  updateLed(List<int> value) async {
    if (_connectedDevice != null)
      await flutterReactiveBle.writeCharacteristicWithResponse(
          QualifiedCharacteristic(
              characteristicId:
                  Uuid.parse(StringConstants.bluetoothLedCharactersticsUUID),
              serviceId: Uuid.parse(StringConstants.bluetoothServicesUUID),
              deviceId: _connectedDevice),
          value: value);
  }

  enableLed(Led led) {
    switch (led) {
      case Led.Blue:
        {
          updateLed([0x4]);
          break;
        }
      case Led.Green:
        {
          updateLed([0x2]);
          break;
        }
      case Led.Red:
        {
          updateLed([0x1]);
          break;
        }
    }
  }

  disableLeds() async {
    updateLed([0x0]);
  }

  bool isPressed(int value, int previous, int buttonMask) {
    return (value & buttonMask == buttonMask) && !(previous & buttonMask == buttonMask);
  }

  bool isReleased(int previous, int value, int buttonMask) {
    return !(value & buttonMask == buttonMask) && (previous & buttonMask == buttonMask);
  }

  onValue(List<int> value) {
    if (isPressed(value[0], _previousValue, GlobalConstants.ptt1ButtonValue)) {
      _listener.onPTT1ButtonDown();
    } else if (isReleased(_previousValue, value[0], GlobalConstants.ptt1ButtonValue)) {
      _listener.onPTT1ButtonUp();
    }

    if (isPressed(value[0], _previousValue, GlobalConstants.ptt2ButtonValue)) {
      _listener.onPTT2ButtonDown();
    } else if (isReleased(_previousValue, value[0], GlobalConstants.ptt2ButtonValue)) {
      _listener.onPTT2ButtonUp();
    }

    if (isPressed(value[0], _previousValue, GlobalConstants.pttMultiFunction) && !mfbPressed) {
      mfbPressed = true;
      pttLongPress.add(true);
    } else if (isReleased(_previousValue, value[0], GlobalConstants.pttMultiFunction)) {
      mfbPressed = false;
      pttLongPress.add(false);
      _listener.onMultifunctionPress();
    }

    if (isPressed(value[0], _previousValue, GlobalConstants.pttPrevious)) {
      _listener.onPreviousChannel();
    }

    if (isPressed(value[0], _previousValue, GlobalConstants.pttNext)) {
      _listener.onNextChannel();
    }

    _previousValue = value[0];
  }
}
