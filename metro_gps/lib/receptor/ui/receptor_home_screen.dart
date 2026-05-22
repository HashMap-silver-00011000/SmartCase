import 'package:flutter/material.dart';

import '../../auth/logout_action.dart';
import '../../conductor/models/viaje.dart';
import '../../core/telemetria_ws_paths.dart';
import '../../shared/ui/viaje_telemetria_screen.dart';
import '../receptor_viaje_api.dart';

class ReceptorHomeScreen extends StatefulWidget {
  const ReceptorHomeScreen({super.key});

  @override
  State<ReceptorHomeScreen> createState() => _ReceptorHomeScreenState();
}

class _ReceptorHomeScreenState extends State<ReceptorHomeScreen> {
  final _api = ReceptorViajeApi();
  bool _cargando = true;
  String? _error;
  List<Viaje> _viajes = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final res = await _api.listarMisViajes();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (res.isSuccess && res.data != null) {
        _viajes = res.data!;
        _error = _viajes.isEmpty ? 'No tienes viajes asignados' : null;
      } else {
        _error = res.errorMessage;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receptor'),
        actions: [
          IconButton(onPressed: _cargar, icon: const Icon(Icons.refresh)),
          const LogoutAppBarButton(),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.builder(
      itemCount: _viajes.length,
      itemBuilder: (context, i) => _tile(_viajes[i]),
    );
  }

  Widget _tile(Viaje v) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text('Viaje ${v.idCorto}'),
        subtitle: Text(
          'Estado: ${v.estadoViaje ?? '—'}\n'
          'Conductor: ${_idCorto(v.idUsuarioConductor)}',
        ),
        trailing: const Icon(Icons.monitor_heart_outlined),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ViajeTelemetriaScreen(
              viaje: v,
              rolWs: TelemetriaWsRol.receptor,
            ),
          ),
        ),
      ),
    );
  }

  static String _idCorto(String id) =>
      id.length > 8 ? '${id.substring(0, 8)}…' : id;
}
