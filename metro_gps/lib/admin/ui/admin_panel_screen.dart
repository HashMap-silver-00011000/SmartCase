import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../auth/logout_action.dart';
import '../../debug/ui/debug_telemetria_screen.dart';
import 'admin_ambulancia_screen.dart';
import 'admin_clinica_screen.dart';
import 'admin_crear_viaje_screen.dart';
import 'admin_sede_screen.dart';
import 'admin_smartcase_screen.dart';
import 'admin_theme.dart';
import 'admin_viajes_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.surface,
      body: CustomScrollView(
        slivers: [
          _AdminSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionLabel('Gestión'),
                const SizedBox(height: 8),
                _MenuGrid(
                  items: [
                    _MenuItem(
                      icon: Icons.local_hospital_outlined,
                      title: 'Clínicas',
                      subtitle: 'Gestionar clínicas',
                      color: const Color(0xFF0096C7),
                      onTap: () => _push(context, const AdminClinicaScreen()),
                    ),
                    _MenuItem(
                      icon: Icons.location_city_outlined,
                      title: 'Sedes',
                      subtitle: 'Sedes por clínica',
                      color: const Color(0xFF00897B),
                      onTap: () => _push(context, const AdminSedeScreen()),
                    ),
                    _MenuItem(
                      icon: Icons.emergency_outlined,
                      title: 'Ambulancias',
                      subtitle: 'Flota y vehículos',
                      color: const Color(0xFF5C6BC0),
                      onTap: () =>
                          _push(context, const AdminAmbulanciaScreen()),
                    ),
                    _MenuItem(
                      icon: Icons.inventory_2_outlined,
                      title: 'SmartCase',
                      subtitle: 'Cajas de órganos',
                      color: const Color(0xFFE65100),
                      onTap: () =>
                          _push(context, const AdminSmartCaseScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionLabel('Operaciones'),
                const SizedBox(height: 8),
                _LargeMenuTile(
                  icon: Icons.monitor_heart_outlined,
                  title: 'Telemetría en vivo',
                  subtitle: 'Monitorear viajes activos en tiempo real',
                  color: const Color(0xFF0096C7),
                  onTap: () => _push(context, const AdminViajesScreen()),
                ),
                const SizedBox(height: 8),
                _LargeMenuTile(
                  icon: Icons.local_shipping_outlined,
                  title: 'Crear viaje',
                  subtitle: 'Asignar caja, sedes, ambulancia y conductor',
                  color: const Color(0xFF00B686),
                  onTap: () =>
                      _push(context, const AdminCrearViajeScreen()),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  _SectionLabel('Desarrollo'),
                  const SizedBox(height: 8),
                  _LargeMenuTile(
                    icon: Icons.bug_report_outlined,
                    title: 'Debug Telemetría',
                    subtitle: 'Mapa y datos ficticios (solo debug)',
                    color: AdminColors.warning,
                    onTap: () =>
                        _push(context, const DebugTelemetriaScreen()),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }
}

// ─── Sliver AppBar con gradiente ─────────────────────────────────────────────

class _AdminSliverAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AdminColors.navy,
      actions: const [LogoutAppBarButton()],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: const Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel Administrador',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AdminColors.navy, AdminColors.navyLight],
            ),
          ),
          child: Stack(
            children: [
              // Círculos decorativos
              Positioned(
                right: -30,
                top: -20,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AdminColors.cyan.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: -40,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AdminColors.cyan.withOpacity(0.08),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Etiqueta de sección ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: AdminColors.textSecondary,
      ),
    );
  }
}

// ─── Grid 2×N de cards pequeñas ──────────────────────────────────────────────

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: items,
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AdminColors.divider),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AdminColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AdminColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tile grande de operación ─────────────────────────────────────────────────

class _LargeMenuTile extends StatelessWidget {
  const _LargeMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AdminColors.divider),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AdminColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}