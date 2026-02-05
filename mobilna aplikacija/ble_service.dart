import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:provider/provider.dart';

import '../constants/ble_constants.dart';
import 'log_service.dart';
import 'language_service.dart';
import 'strings.dart';

class BleService extends ChangeNotifier {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  StreamSubscription<ConnectionStateUpdate>? _connectionSub;
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  QualifiedCharacteristic? _rxChar;

  bool _connected = false;
  bool get connected => _connected;

  // Praćenje pronalaska uređaja radi smanjenja preopširnog broja poruka
  bool _deviceFound = false;

  LogService? logService;

  LanguageService? _languageService;
  S? _s;

  /* -------------------------------------------------- */
  /* INICIJALIZACIJA                                    */
  /* -------------------------------------------------- */

  void _updateStrings(BuildContext? context) {
    if (context != null) {
      _languageService = context.read<LanguageService>();
      _s = S(_languageService!.lang);
    }
  }

  void initWithContext(BuildContext context) {
    _updateStrings(context);
  }

  /* -------------------------------------------------- */
  /* SPAJANJE                                           */
  /* -------------------------------------------------- */

  Future<void> connect() async {
    if (_connected) return;

    if (logService == null) {
      developer.log("LogService is not initialized yet");
      return;
    }

    logService!.addLog("BLE", _s?.bleConnectRequested ?? "BLE: connect requested");

    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      if (info.manufacturer.toLowerCase().contains("xiaomi")) {
        logService!.addLog("BLE", _s?.warningXiaomi ?? "WARNING: Xiaomi – ensure device is paired");
      }
    }

    await Permission.location.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();

    logService!.addLog("BLE", _s?.bleStartingScan(DEVICE_NAME) ?? "BLE: Starting scan for $DEVICE_NAME");

    _deviceFound = false;

    _scanSubscription = _ble.scanForDevices(withServices: []).listen((device) async {
      // Skupljaj poruke o pronalascima uređaja jedino ako naš još nije pronađen (radi smanjenja preopširnog broja poruka)
      if (!_deviceFound) {
        logService!.addLog("BLE", _s?.bleFoundDevice(device.name, device.id) ?? "BLE: Found device: ${device.name} (${device.id})");
      }

      if (device.name == DEVICE_NAME && !_deviceFound) {
        _deviceFound = true;
        logService!.addLog("SUCCESS", _s?.successFoundEsp ?? "SUCCESS: Found ESP32-CarKey!");

        // Zaustavi skeniranje sad kad je nađen naš uređaj
        _scanSubscription?.cancel();
        _scanSubscription = null;

        await _connectToDevice(device.id);
      }
    }, onError: (error) {
      logService!.addLog("ERROR", _s?.errorScan(error.toString()) ?? "ERROR: Scan error: $error");
    });
  }

  Future<void> _connectToDevice(String deviceId) async {
    logService!.addLog("BLE", _s?.bleConnecting ?? "BLE: Connecting to device...");

    _connectionSub = _ble.connectToDevice(id: deviceId).listen((update) async {
      if (update.connectionState == DeviceConnectionState.connected) {
        _connected = true;
        _deviceFound = true;
        notifyListeners();
        logService!.addLog("SUCCESS", _s?.successBleConnected ?? "SUCCESS: BLE connected to ESP32");
        await _discoverServices(deviceId);
      }

      if (update.connectionState == DeviceConnectionState.disconnected) {
        _connected = false;
        _deviceFound = false;
        notifyListeners();
        logService!.addLog("WARNING", _s?.warningBleDisconnected ?? "WARNING: BLE disconnected - trying to reconnect...");
        Future.delayed(const Duration(seconds: 2), () => connect());
      }
    }, onError: (error) {
      logService!.addLog("ERROR", _s?.errorConnection(error.toString()) ?? "ERROR: Connection error: $error");
    });
  }

  /* -------------------------------------------------- */
  /* PRONALAŽENJE USLUGA                                */
  /* -------------------------------------------------- */

  Future<void> _discoverServices(String deviceId) async {
    try {
      logService!.addLog("BLE", _s?.bleDiscoveringServices ?? "BLE: Discovering services...");

      // Prvo otkrij sve usluge
      await _ble.discoverAllServices(deviceId);

      // Prihvati pronađene usluge
      final services = await _ble.getDiscoveredServices(deviceId);

      logService!.addLog("BLE", _s?.bleFoundServices(services.length) ?? "BLE: Found ${services.length} services");

      bool foundService = false;
      bool foundCharacteristic = false;

      for (final service in services) {
        final serviceStr = service.id.toString();
        logService!.addLog("BLE", _s?.bleService(serviceStr) ?? "BLE: Service: $serviceStr");

        if (service.id == Uuid.parse(SERVICE_UUID)) {
          foundService = true;
          logService!.addLog("SUCCESS", _s?.successFoundService ?? "SUCCESS: Found our service!");

          for (final characteristic in service.characteristics) {
            final charStr = characteristic.id.toString();
            logService!.addLog("BLE", _s?.bleCharacteristic(charStr) ?? "BLE: Characteristic: $charStr");

            if (characteristic.id == Uuid.parse(RX_UUID)) {
              foundCharacteristic = true;
              _rxChar = QualifiedCharacteristic(
                serviceId: service.id,
                characteristicId: characteristic.id,
                deviceId: deviceId,
              );
              logService!.addLog("SUCCESS", _s?.successFoundRxChar ?? "SUCCESS: Found RX characteristic for writing!");

              // Slanje testne poruke radi potvrde ostvarivanja komunikacije
              await send("HELLO");
            }
          }
        }
      }

      if (!foundService) {
        logService!.addLog("ERROR", _s?.errorServiceNotFound ?? "ERROR: Service not found! Available services:");
        for (final service in services) {
          logService!.addLog("DEBUG", "  - ${service.id}");
        }
      }

      if (!foundCharacteristic) {
        logService!.addLog("ERROR", _s?.errorRxCharNotFound ?? "ERROR: RX characteristic not found!");
      }

    } catch (e) {
      logService!.addLog("ERROR", _s?.errorServiceDiscovery(e.toString()) ?? "ERROR: Service discovery failed: $e");
    }
  }

  /* -------------------------------------------------- */
  /* SLANJE NAREDBI                                     */
  /* -------------------------------------------------- */

  Future<void> send(String msg) async {
    if (logService == null) {
      developer.log("Cannot send $msg - LogService not initialized");
      return;
    }

    if (!_connected) {
      logService!.addLog("ERROR", _s?.errorCannotSendNotConnected ?? "ERROR: Cannot send - not connected");
      return;
    }

    if (_rxChar == null) {
      logService!.addLog("ERROR", _s?.errorCannotSendRxNotFound ?? "ERROR: Cannot send - RX characteristic not found");
      return;
    }

    try {
      logService!.addLog("BLE", _s?.bleSend(msg) ?? "BLE SEND: '$msg'");

      // Pisanje s odgovorima (pouzdanije)
      await _ble.writeCharacteristicWithResponse(
        _rxChar!,
        value: utf8.encode(msg),
      );

      logService!.addLog("SUCCESS", _s?.successSent(msg) ?? "SUCCESS: Sent '$msg'");

    } catch (e) {
      logService!.addLog("ERROR", _s?.errorFailedToSend(msg, e.toString()) ?? "ERROR: Failed to send '$msg': $e");

      // Pokušaj pisanja bez odgovora u slučaju ranijeg neuspjeha
      try {
        logService!.addLog("DEBUG", _s?.debugTryingWriteWithoutResponse ?? "DEBUG: Trying write without response...");
        await _ble.writeCharacteristicWithoutResponse(
          _rxChar!,
          value: utf8.encode(msg),
        );
        logService!.addLog("SUCCESS", _s?.successSentWithoutResponse(msg) ?? "SUCCESS: Sent '$msg' (without response)");
      } catch (e2) {
        logService!.addLog("ERROR", _s?.errorBothWriteMethodsFailed(e2.toString()) ?? "ERROR: Both write methods failed: $e2");
      }
    }
  }

  /* -------------------------------------------------- */
  /* ODSPAJANJE                                         */
  /* -------------------------------------------------- */

  Future<void> disconnect() async {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _connectionSub?.cancel();
    _connected = false;
    _deviceFound = false;
    _rxChar = null;
    notifyListeners();
    if (logService != null) {
      logService!.addLog("BLE", _s?.bleDisconnected ?? "BLE: Disconnected");
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}