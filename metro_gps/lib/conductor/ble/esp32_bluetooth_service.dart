import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

import 'esp32_telemetria_packet.dart';

/// Conexión Bluetooth clásico (SPP) al ESP32 — nombre en firmware: ESP32_Telemetria_Bryan.
class Esp32BluetoothService extends ChangeNotifier {
  Esp32BluetoothService._();

  static final Esp32BluetoothService instance = Esp32BluetoothService._();

  static const deviceName = 'ESP32_Telemetria_Bryan';

  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _inputSub;
  String _lineBuffer = '';

  bool get isConnected => _connection?.isConnected ?? false;
  String? statusMessage;
  Esp32TelemetriaPacket? lastPacket;
  String? lastError;
  int bytesRecibidos = 0;
  int lineasProcesadas = 0;

  final _packetController = StreamController<Esp32TelemetriaPacket>.broadcast();
  Stream<Esp32TelemetriaPacket> get packets => _packetController.stream;

  bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<bool> ensurePermissions() async {
    if (!isSupported) return false;
    final results = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ].request();
    final connect = results[Permission.bluetoothConnect];
    final scan = results[Permission.bluetoothScan];
    final connectOk = connect?.isGranted ?? false;
    final scanOk = scan?.isGranted ?? connectOk;
    return connectOk && scanOk;
  }

  Future<List<BluetoothDevice>> listBondedDevices() async {
    if (!isSupported) return [];
    final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
    return bonded.toList();
  }

  BluetoothDevice? pickEsp32Device(List<BluetoothDevice> devices) {
    for (final d in devices) {
      if (d.name == deviceName) return d;
    }
    for (final d in devices) {
      final name = d.name ?? '';
      if (name.contains('ESP32') || name.contains('Telemetria')) return d;
    }
    return null;
  }

  Future<void> connect({String? address}) async {
    if (!isSupported) {
      statusMessage =
          'Bluetooth clásico del ESP32 solo en Android. Empareja el módulo en Ajustes.';
      notifyListeners();
      return;
    }

    if (isConnected) return;

    final ok = await ensurePermissions();
    if (!ok) {
      statusMessage = 'Permisos de Bluetooth denegados';
      notifyListeners();
      return;
    }

    statusMessage = 'Buscando $deviceName…';
    lastError = null;
    notifyListeners();

    BluetoothDevice? device;
    if (address != null) {
      device = BluetoothDevice(address: address, name: deviceName);
    } else {
      final bonded = await listBondedDevices();
      device = pickEsp32Device(bonded);
      device ??= await _discoverEsp32();
    }

    if (device == null) {
      statusMessage =
          'No se encontró $deviceName. Empareja el ESP32 en Bluetooth del teléfono e intenta de nuevo.';
      notifyListeners();
      return;
    }

    try {
      statusMessage = 'Conectando a ${device.name ?? device.address}…';
      notifyListeners();

      final connection = await BluetoothConnection.toAddress(device.address);
      _connection = connection;
      _lineBuffer = '';
      bytesRecibidos = 0;
      lineasProcesadas = 0;

      final input = _connection!.input;
      if (input == null) {
        lastError = 'El socket Bluetooth no expuso canal de lectura';
        statusMessage = lastError;
        await _cleanupConnection();
        notifyListeners();
        return;
      }

      _inputSub = input.listen(
        _onData,
        onDone: _handleDisconnect,
        onError: (Object e) {
          lastError = e.toString();
          _handleDisconnect();
        },
        cancelOnError: false,
      );

      statusMessage = 'Conectado a ${device.name ?? device.address}';
      notifyListeners();
    } catch (e) {
      lastError = e.toString();
      statusMessage = 'Error al conectar: $e';
      await _cleanupConnection();
      notifyListeners();
    }
  }

  Future<BluetoothDevice?> _discoverEsp32() async {
    final completer = Completer<BluetoothDevice?>();
    StreamSubscription<BluetoothDiscoveryResult>? sub;

    sub = FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
      final d = result.device;
      if (d.name == deviceName ||
          (d.name?.contains('ESP32') ?? false) ||
          (d.name?.contains('Telemetria') ?? false)) {
        FlutterBluetoothSerial.instance.cancelDiscovery();
        if (!completer.isCompleted) completer.complete(d);
      }
    });

    try {
      return await completer.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          FlutterBluetoothSerial.instance.cancelDiscovery();
          return null;
        },
      );
    } finally {
      await sub.cancel();
      await FlutterBluetoothSerial.instance.cancelDiscovery();
    }
  }

  Future<void> disconnect() async {
    statusMessage = 'Desconectado';
    await _cleanupConnection();
    notifyListeners();
  }

  Future<void> _cleanupConnection() async {
    await _inputSub?.cancel();
    _inputSub = null;
    await _connection?.close();
    _connection = null;
    _lineBuffer = '';
  }

  void _handleDisconnect() {
    _cleanupConnection();
    statusMessage = 'Conexión cerrada';
    notifyListeners();
  }

  void _onData(Uint8List data) {
    bytesRecibidos += data.length;
    _lineBuffer += utf8.decode(data, allowMalformed: true);
    _drainBuffer();
    notifyListeners();
  }

  void _drainBuffer() {
    while (true) {
      final nl = _lineBuffer.indexOf('\n');
      if (nl >= 0) {
        final line = _lineBuffer.substring(0, nl).replaceAll('\r', '').trim();
        _lineBuffer = _lineBuffer.substring(nl + 1);
        if (line.isNotEmpty) _processLine(line);
        continue;
      }

      final start = _lineBuffer.indexOf('{');
      final end = _lineBuffer.lastIndexOf('}');
      if (start >= 0 && end > start) {
        final jsonLine = _lineBuffer.substring(start, end + 1);
        if (_tryParseAndEmit(jsonLine)) {
          _lineBuffer = _lineBuffer.substring(end + 1);
          continue;
        }
      }
      break;
    }
  }

  void _processLine(String line) {
    if (line.isEmpty) return;
    final start = line.indexOf('{');
    if (start < 0) return;
    _tryParseAndEmit(line.substring(start));
  }

  bool _tryParseAndEmit(String jsonLine) {
    try {
      final packet = Esp32TelemetriaPacket.fromJsonLine(jsonLine);
      lastPacket = packet;
      lastError = null;
      lineasProcesadas++;
      _packetController.add(packet);
      notifyListeners();
      return true;
    } catch (e) {
      lastError = 'JSON inválido: $e · $jsonLine';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _cleanupConnection();
    _packetController.close();
    super.dispose();
  }
}
