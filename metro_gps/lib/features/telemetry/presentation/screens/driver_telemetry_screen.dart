import 'dart:convert';

import 'package:metro_gps/app/providers.dart';
import 'package:metro_gps/core/constants/app_colors.dart';
import 'package:metro_gps/core/permissions/ble_permission_service.dart';
import 'package:metro_gps/core/widgets/empty_state_card.dart';
import 'package:metro_gps/features/auth/domain/models/user_model.dart';
import 'package:metro_gps/features/auth/presentation/widgets/role_badge.dart';
import 'package:metro_gps/features/telemetry/domain/models/telemetry_point.dart';
import 'package:metro_gps/features/telemetry/presentation/widgets/osm_routes_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class DriverTelemetryScreen extends ConsumerStatefulWidget {
  const DriverTelemetryScreen({super.key, required this.user});

  final UserModel user;

  @override
  ConsumerState<DriverTelemetryScreen> createState() => _DriverTelemetryScreenState();
}

class _DriverTelemetryScreenState extends ConsumerState<DriverTelemetryScreen> {
  final List<TelemetryPoint> _points = <TelemetryPoint>[];
  final BlePermissionService _blePermissionService = BlePermissionService();
  BluetoothDevice? _connectedDevice;
  bool _connecting = false;
  bool _showOpenSettingsButton = false;
  String _status = 'Sin conexion BLE';

  Future<void> _connectBle() async {
    await HapticFeedback.selectionClick();
    setState(() {
      _connecting = true;
      _status = 'Buscando dispositivos...';
    });

    try {
      final permissionResult = await _blePermissionService.ensureBlePermissions();
      if (!permissionResult.granted) {
        if (permissionResult.openSettingsRecommended && mounted) {
          await _showPermissionsDialog(permissionResult.message);
        }
        setState(() {
          _status = permissionResult.message;
          _showOpenSettingsButton = permissionResult.openSettingsRecommended;
          _connecting = false;
        });
        return;
      }

      final ble = ref.read(bluetoothTelemetryServiceProvider);
      final devices = await ble.scanDevices();
      if (devices.isEmpty) {
        setState(() {
          _status = 'No se encontraron dispositivos BLE.';
          _connecting = false;
        });
        return;
      }

      final device = devices.first;
      await ble.connectAndListen(
        device: device,
        onTelemetry: (json) {
          final point = _fromBleJson(json);
          if (point == null) return;
          if (mounted) {
            setState(() {
              _points.add(point);
              _status = 'Conectado a ${device.platformName}';
            });
          }
        },
      );

      setState(() {
        _connectedDevice = device;
        _connecting = false;
        _showOpenSettingsButton = false;
        _status = 'Conectado a ${device.platformName}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error BLE: $e';
        _connecting = false;
      });
    }
  }

  TelemetryPoint? _fromBleJson(Map<String, dynamic> jsonData) {
    try {
      return TelemetryPoint(
        idTelemetria: const Uuid().v4(),
        idBus: jsonData['id_bus']?.toString() ?? '',
        lat: _toDouble(jsonData['lat']),
        long: _toDouble(jsonData['long']),
        fecha: DateTime.tryParse(jsonData['fecha']?.toString() ?? '') ?? DateTime.now(),
        idRuta: jsonData['id_ruta']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  Future<void> _showPermissionsDialog(String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Permisos requeridos'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Abrir ajustes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel conductor'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: RoleBadge(role: widget.user.rol)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_status),
                    ),
                    const SizedBox(height: 8),
                    if (_showOpenSettingsButton) ...[
                      OutlinedButton.icon(
                        onPressed: openAppSettings,
                        icon: const Icon(Icons.settings),
                        label: const Text('Abrir ajustes'),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: _connecting ? null : _connectBle,
                          icon: const Icon(Icons.bluetooth_connected),
                          label: const Text('Conectar ESP32'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            final jsonPreview = _points.isEmpty
                                ? '{}'
                                : jsonEncode({
                                    'lat': _points.last.lat,
                                    'long': _points.last.long,
                                    'fecha': _points.last.fecha.toIso8601String(),
                                  });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Ultimo paquete: $jsonPreview')),
                            );
                          },
                          child: const Text('Ver ultimo JSON'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: _points.isEmpty
                      ? const EmptyStateCard(
                          key: ValueKey('empty-map'),
                          title: 'Sin datos de telemetria',
                          subtitle: 'Conecta el ESP32 para empezar a ver la ruta.',
                          icon: Icons.bluetooth_searching_rounded,
                        )
                      : OSMRoutesMap(
                          key: const ValueKey('data-map'),
                          points: _points,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    final device = _connectedDevice;
    if (device != null) {
      ref.read(bluetoothTelemetryServiceProvider).disconnect(device);
    }
    super.dispose();
  }
}
