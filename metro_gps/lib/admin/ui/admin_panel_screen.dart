import 'package:flutter/material.dart';

import '../../auth/logout_action.dart';
import 'admin_ambulancia_screen.dart';
import 'admin_clinica_screen.dart';
import 'admin_crear_viaje_screen.dart';
import 'admin_viajes_screen.dart';
import 'admin_smartcase_screen.dart';
import 'admin_sede_screen.dart';

import 'package:flutter/foundation.dart';

import '../../debug/ui/debug_telemetria_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel administrador'),
        actions: const [LogoutAppBarButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _AdminMenuTile(
            icon: Icons.local_hospital_outlined,
            title: 'Clínicas',
            subtitle: 'Gestionar clínicas del sistema',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AdminClinicaScreen(),
              ),
            ),
          ),
          _AdminMenuTile(
            icon: Icons.location_city_outlined,
            title: 'Sedes',
            subtitle: 'Sedes por clínica',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AdminSedeScreen()),
            ),
          ),
          _AdminMenuTile(
            icon: Icons.emergency_outlined,
            title: 'Ambulancias',
            subtitle: 'Flota y tipos de vehículo',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AdminAmbulanciaScreen(),
              ),
            ),
          ),
          _AdminMenuTile(
            icon: Icons.inventory_2_outlined,
            title: 'SmartCase',
            subtitle: 'Cajas de transporte de órganos',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AdminSmartCaseScreen(),
              ),
            ),
          ),
          _AdminMenuTile(
            icon: Icons.monitor_heart_outlined,
            title: 'Ver telemetría',
            subtitle: 'Viajes en tránsito y datos en vivo',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AdminViajesScreen(),
              ),
            ),
          ),
          _AdminMenuTile(
            icon: Icons.local_shipping_outlined,
            title: 'Crear viaje',
            subtitle: 'Asignar caja, sedes, ambulancia y conductor',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AdminCrearViajeScreen(),
              ),
            ),
          ),
          if (kDebugMode)
            _AdminMenuTile(
              icon: Icons.bug_report_outlined,
              title: 'Debug Telemetría',
              subtitle: 'Mapa + tabla con datos ficticios (solo debug)',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DebugTelemetriaScreen(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminMenuTile extends StatelessWidget {
  const _AdminMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
