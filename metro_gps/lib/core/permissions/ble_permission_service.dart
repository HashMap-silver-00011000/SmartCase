import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class BlePermissionService {
  Future<PermissionRequestResult> ensureBlePermissions() async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      return _mapStatuses(statuses);
    }

    if (Platform.isIOS) {
      final statuses = await [
        Permission.bluetooth,
        Permission.locationWhenInUse,
      ].request();
      return _mapStatuses(statuses);
    }

    return const PermissionRequestResult(
      granted: true,
      message: 'Permisos BLE no requeridos en esta plataforma.',
    );
  }

  PermissionRequestResult _mapStatuses(Map<Permission, PermissionStatus> statuses) {
    final denied = <Permission>[];
    final permanentlyDenied = <Permission>[];

    statuses.forEach((permission, status) {
      if (status.isGranted) return;
      if (status.isPermanentlyDenied || status.isRestricted) {
        permanentlyDenied.add(permission);
      } else {
        denied.add(permission);
      }
    });

    if (denied.isEmpty && permanentlyDenied.isEmpty) {
      return const PermissionRequestResult(
        granted: true,
        message: 'Permisos BLE concedidos.',
      );
    }

    if (permanentlyDenied.isNotEmpty) {
      return PermissionRequestResult(
        granted: false,
        openSettingsRecommended: true,
        message:
            'Permisos bloqueados permanentemente: ${_labelList(permanentlyDenied)}. Debes habilitarlos en ajustes.',
      );
    }

    return PermissionRequestResult(
      granted: false,
      message: 'Permisos denegados: ${_labelList(denied)}.',
    );
  }

  static String _labelList(List<Permission> permissions) {
    return permissions.map(_permissionLabel).join(', ');
  }

  static String _permissionLabel(Permission permission) {
    if (permission == Permission.bluetoothScan) return 'Bluetooth Scan';
    if (permission == Permission.bluetoothConnect) return 'Bluetooth Connect';
    if (permission == Permission.bluetooth) return 'Bluetooth';
    if (permission == Permission.locationWhenInUse) return 'Ubicacion';
    return permission.toString();
  }
}

class PermissionRequestResult {
  const PermissionRequestResult({
    required this.granted,
    required this.message,
    this.openSettingsRecommended = false,
  });

  final bool granted;
  final String message;
  final bool openSettingsRecommended;
}
