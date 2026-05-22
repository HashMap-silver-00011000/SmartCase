import 'package:flutter/material.dart';

import '../../conductor/models/viaje.dart';
import '../../core/telemetria_ws_paths.dart';
import '../../shared/ui/viaje_telemetria_screen.dart';
import '../viaje_api.dart';

class AdminViajesScreen extends StatefulWidget {
  const AdminViajesScreen({super.key});

  @override
  State<AdminViajesScreen> createState() => _AdminViajesScreenState();
}

class _AdminViajesScreenState extends State<AdminViajesScreen> {
  final _api = ViajeApi();
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
    final res = await _api.listarPorEstado('transito');
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (res.isSuccess && res.data != null) {
        _viajes = res.data!;
      } else {
        _error = res.errorMessage ?? 'No se pudieron cargar viajes';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viajes en tránsito'),
        actions: [
          IconButton(onPressed: _cargar, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _viajes.isEmpty
                  ? const Center(child: Text('No hay viajes en tránsito'))
                  : ListView.builder(
                      itemCount: _viajes.length,
                      itemBuilder: (context, i) {
                        final v = _viajes[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text('Viaje ${v.idCorto}'),
                            subtitle: Text(
                              'Estado: ${v.estadoViaje ?? '—'}\n'
                              'Receptor: ${_idCorto(v.idUsuarioReceptor)}\n'
                              'Inicio: ${v.fechaInicio}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ViajeTelemetriaScreen(
                                  viaje: v,
                                  rolWs: TelemetriaWsRol.admin,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  static String _idCorto(String? id) {
    if (id == null || id.isEmpty) return '—';
    return id.length > 8 ? '${id.substring(0, 8)}…' : id;
  }
}
