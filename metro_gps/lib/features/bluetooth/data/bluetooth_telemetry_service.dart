import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothTelemetryService {
  StreamSubscription<List<int>>? _subscription;

  Future<List<BluetoothDevice>> scanDevices({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final devices = <BluetoothDevice>{};
    final scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        devices.add(result.device);
      }
    });

    await FlutterBluePlus.startScan(timeout: timeout);
    await Future<void>.delayed(timeout);
    await FlutterBluePlus.stopScan();
    await scanSub.cancel();

    return devices.toList();
  }

  Future<void> connectAndListen({
    required BluetoothDevice device,
    required void Function(Map<String, dynamic> data) onTelemetry,
  }) async {
    await device.connect(license: License.free);
    final services = await device.discoverServices();

    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (!characteristic.properties.notify &&
            !characteristic.properties.read) {
          continue;
        }

        await characteristic.setNotifyValue(true);
        _subscription = characteristic.lastValueStream.listen((bytes) {
          if (bytes.isEmpty) return;
          final raw = utf8.decode(bytes, allowMalformed: true).trim();
          if (raw.isEmpty) return;
          try {
            final data = jsonDecode(raw) as Map<String, dynamic>;
            onTelemetry(data);
          } catch (_) {
            // Ignora paquetes que no sean JSON valido.
          }
        });
        return;
      }
    }

    throw Exception('No se encontro caracteristica BLE legible/notificable.');
  }

  Future<void> disconnect(BluetoothDevice device) async {
    await _subscription?.cancel();
    _subscription = null;
    await device.disconnect();
  }
}
