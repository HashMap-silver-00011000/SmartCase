// lib/conductor/ui/conductor_home_screen.dart

import 'package:flutter/material.dart';

import '../../admin/clinica_api.dart';
import '../../auth/ui/auth_tabs_screen.dart';
import '../../core/session_store.dart';
import '../conductor_viaje_api.dart';
import '../models/viaje.dart';
import 'conductor_viaje_detalle_screen.dart';

class ConductorHomeScreen extends StatefulWidget {
  ConductorHomeScreen({super.key});

  @override
  State<ConductorHomeScreen> createState() => _ConductorHomeScreenState();
}

class _ConductorHomeScreenState extends State<ConductorHomeScreen> {
  final _api = ConductorViajeApi();
  List<Viaje> _viajes = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarViajes();
  }

  Future<void> _cargarViajes() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final res = await _api.listarMisViajes();
    if (!mounted) return;
    if (res.isSuccess) {
      setState(() {
        _viajes = res.data ?? [];
        _cargando = false;
      });
    } else {
      setState(() {
        _error = res.errorMessage ?? 'Error al cargar viajes';
        _cargando = false;
      });
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    SessionStore.instance.clear();
    await ClinicaApi.sharedClient.clearSession();

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AuthTabsScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis viajes'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargarViajes,
            icon: const Icon(Icons.refresh_outlined),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout_outlined),
          ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 48, color: Color(0xFF888780)),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF888780)),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _cargarViajes,
                icon: const Icon(Icons.refresh_outlined, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_viajes.isEmpty) {
      return const Center(
        child: Text(
          'No tienes viajes asignados.',
          style: TextStyle(color: Color(0xFF888780)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarViajes,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _viajes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final viaje = _viajes[index];
          return _ViajeCard(
            viaje: viaje,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ConductorViajeDetalleScreen(viaje: viaje),
                ),
              );
              _cargarViajes();
            },
          );
        },
      ),
    );
  }
}

class _ViajeCard extends StatelessWidget {
  const _ViajeCard({required this.viaje, required this.onTap});

  final Viaje viaje;
  final VoidCallback onTap;

  Color _estadoColor(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'transito':
        return const Color(0xFF185FA5);
      case 'entregado':
        return const Color(0xFF1D9E75);
      case 'muestra comprometida':
        return const Color(0xFFE24B4A);
      default:
        return const Color(0xFF888780);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoColor = _estadoColor(viaje.estadoViaje);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '# ${viaje.idCorto}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      viaje.estadoViaje ?? 'Sin estado',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: estadoColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.trip_origin,
                      size: 14, color: Color(0xFF1D9E75)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      viaje.idSedeOrigen,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_forward,
                      size: 14, color: Color(0xFF888780)),
                  const SizedBox(width: 6),
                  const Icon(Icons.place_outlined,
                      size: 14, color: Color(0xFFE24B4A)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      viaje.idSedeDestino,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule_outlined,
                      size: 13, color: Color(0xFF888780)),
                  const SizedBox(width: 4),
                  Text(
                    viaje.fechaInicio,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF888780)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}