import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../admin/clinica_api.dart';
import '../conductor/models/telemetria.dart';
import 'api_constants.dart';
import 'telemetria_ws_paths.dart';

/// Cliente WebSocket para enviar (conductor) o recibir (admin/receptor) telemetría.
class TelemetriaWsClient {
  TelemetriaWsClient({
    required this.idViaje,
    required this.rol,
  });

  final String idViaje;
  final TelemetriaWsRol rol;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  final _incoming = StreamController<TelemetriaRegistro>.broadcast();

  String? lastError;
  DateTime? lastEnviadoEn;
  int mensajesEnviados = 0;
  bool _cerradoManual = false;

  Stream<TelemetriaRegistro> get stream => _incoming.stream;

  bool get isConnected => _channel != null && lastError == null;

  static String? bearerToken() {
    final cookie = ClinicaApi.sharedClient.sessionCookie;
    if (cookie == null) return null;
    if (cookie.startsWith('smart_session=')) {
      return cookie.substring('smart_session='.length);
    }
    return cookie;
  }

  Uri _buildUri() {
    final base = ApiConstants.baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final path = TelemetriaWsPaths.pathFor(rol);
    final token = bearerToken();
    final params = <String, String>{'id_viaje': idViaje};
    if (token != null && token.isNotEmpty) {
      params['token'] = token;
    }
    return Uri.parse('$base$path').replace(queryParameters: params);
  }

  Future<void> connect() async {
    await disconnect();
    _cerradoManual = false;
    lastError = null;

    final uri = _buildUri();
    final token = bearerToken();
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Cookie'] = 'smart_session=$token';
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isWindows)) {
        final socket = await WebSocket.connect(
          uri.toString(),
          headers: headers,
        );
        socket.pingInterval = const Duration(seconds: 25);
        _channel = IOWebSocketChannel(socket);
      } else {
        _channel = IOWebSocketChannel.connect(uri, headers: headers);
      }

      _sub = _channel!.stream.listen(
        _onMessage,
        onError: (Object e) {
          if (!_cerradoManual) {
            lastError = e.toString();
          }
          _channel = null;
        },
        onDone: () {
          _channel = null;
          if (!_cerradoManual) {
            lastError = 'Conexión cerrada (reconectando…)';
          }
        },
        cancelOnError: false,
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
    } catch (e) {
      lastError = e.toString();
      _channel = null;
      rethrow;
    }
  }

  void _onMessage(dynamic data) {
    try {
      final text = data is String ? data : utf8.decode(data as List<int>);
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        _incoming.add(TelemetriaRegistro.fromJson(decoded));
      } else if (decoded is Map) {
        _incoming.add(
          TelemetriaRegistro.fromJson(Map<String, dynamic>.from(decoded)),
        );
      }
    } catch (_) {
      // Ping u otros mensajes no JSON.
    }
  }

  bool send(TelemetriaRegistro registro) {
    final ch = _channel;
    if (ch == null) {
      lastError = 'WebSocket no conectado';
      return false;
    }
    try {
      final json = jsonEncode(registro.toWsJson());
      ch.sink.add(json);
      mensajesEnviados++;
      lastEnviadoEn = DateTime.now();
      lastError = null;
      return true;
    } catch (e) {
      lastError = e.toString();
      _channel = null;
      return false;
    }
  }

  Future<void> disconnect() async {
    _cerradoManual = true;
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _incoming.close();
  }
}
