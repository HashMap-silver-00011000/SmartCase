import 'package:metro_gps/core/network/api_client.dart';
import 'package:metro_gps/features/auth/data/auth_service.dart';
import 'package:metro_gps/features/bluetooth/data/bluetooth_telemetry_service.dart';
import 'package:metro_gps/features/telemetry/data/telemetry_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _baseUrl = 'http://localhost:8080';

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(baseUrl: _baseUrl),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.read(apiClientProvider)),
);

final telemetryApiServiceProvider = Provider<TelemetryApiService>(
  (ref) => TelemetryApiService(ref.read(apiClientProvider)),
);

final bluetoothTelemetryServiceProvider = Provider<BluetoothTelemetryService>(
  (ref) => BluetoothTelemetryService(),
);
