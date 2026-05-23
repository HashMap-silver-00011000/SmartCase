import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metro_gps/receptor/models/viaje.dart';

import '../../auth/logout_action.dart';
import '../../core/telemetria_ws_paths.dart';
import '../../shared/ui/viaje_telemetria_screen.dart';
import '../receptor_viaje_api.dart';

class ReceptorHomeScreen extends StatefulWidget {
  const ReceptorHomeScreen({super.key});

  @override
  State<ReceptorHomeScreen> createState() => _ReceptorHomeScreenState();
}

class _ReceptorHomeScreenState extends State<ReceptorHomeScreen>
    with SingleTickerProviderStateMixin {
  final _api = ReceptorViajeApi();
  bool _cargando = true;
  String? _error;
  List<Viaje> _viajes = [];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _cargar();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    _fadeController.reset();
    final res = await _api.listarMisViajes();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (res.isSuccess && res.data != null) {
        _viajes = res.data!;
        _error = _viajes.isEmpty ? null : null;
      } else {
        _error = res.errorMessage;
      }
    });
    if (!_cargando) _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: _buildAppBar(colorScheme),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              color: Color(0xFF1A73E8),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mis Viajes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F36),
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Receptor',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8A94A6),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _buildRefreshButton(),
        const SizedBox(width: 4),
        const LogoutAppBarButton(),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: const Color(0xFFE8ECF2),
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Tooltip(
      message: 'Actualizar viajes',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _cargar,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE8ECF2)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF1A73E8)),
              SizedBox(width: 4),
              Text(
                'Actualizar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A73E8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) return _buildLoading();
    if (_error != null) return _buildError();
    if (_viajes.isEmpty) return _buildEmpty();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _cargar,
        color: const Color(0xFF1A73E8),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: _viajes.length,
          itemBuilder: (context, i) => _ViajeCard(
            viaje: _viajes[i],
            onTap: () => _abrirTelemetria(_viajes[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando viajes…',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: Color(0xFFE53935),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1A1F36),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                size: 48,
                color: Color(0xFF1A73E8),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin viajes asignados',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1F36),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuando tengas viajes asignados\naparecerán aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8A94A6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Verificar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A73E8),
                side: const BorderSide(color: Color(0xFF1A73E8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// ✅ correcto
void _abrirTelemetria(Viaje v) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ViajeTelemetriaScreen(
        viaje: v.toConductorViaje(),
        rolWs: TelemetriaWsRol.receptor,
        pinEntrega: v.pinEntrega, // ← esta línea faltaba
      ),
    ),
  );
}
}

// ─── Tarjeta de viaje ────────────────────────────────────────────────────────

class _ViajeCard extends StatelessWidget {
  const _ViajeCard({required this.viaje, required this.onTap});

  final Viaje viaje;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE8ECF2)),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 14),
                _buildDivider(),
                const SizedBox(height: 14),
                _buildDetails(),
                if (viaje.pinEntrega != null && viaje.pinEntrega!.isNotEmpty)
                  _buildPinChip(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.local_shipping_outlined,
            color: Color(0xFF1A73E8),
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Viaje ${viaje.idCorto}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F36),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              _EstadoBadge(estado: viaje.estadoViaje),
            ],
          ),
        ),
        const Icon(
          Icons.monitor_heart_outlined,
          color: Color(0xFF1A73E8),
          size: 22,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: const Color(0xFFF0F2F7));
  }

  Widget _buildDetails() {
    return Row(
      children: [
        _InfoChip(
          icon: Icons.person_outline_rounded,
          label: 'Conductor',
          value: _idCorto(viaje.idUsuarioConductor),
        ),
      ],
    );
  }

  Widget _buildPinChip(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: _PinEntregaWidget(pin: viaje.pinEntrega!),
    );
  }

  static String _idCorto(String id) =>
      id.length > 8 ? '${id.substring(0, 8)}…' : id;
}

// ─── Badge de estado ─────────────────────────────────────────────────────────

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.estado});
  final String? estado;

  @override
  Widget build(BuildContext context) {
    final (color, bg, label) = _mapEstado(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  static (Color, Color, String) _mapEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'en_curso':
      case 'en curso':
        return (
          const Color(0xFF1B873F),
          const Color(0xFFE6F4EA),
          'En curso'
        );
      case 'pendiente':
        return (
          const Color(0xFFB45309),
          const Color(0xFFFFF8E1),
          'Pendiente'
        );
      case 'finalizado':
      case 'completado':
        return (
          const Color(0xFF5B6273),
          const Color(0xFFF0F2F7),
          'Finalizado'
        );
      case 'cancelado':
        return (
          const Color(0xFFB71C1C),
          const Color(0xFFFFEBEE),
          'Cancelado'
        );
      default:
        return (
          const Color(0xFF5B6273),
          const Color(0xFFF0F2F7),
          estado ?? '—'
        );
    }
  }
}

// ─── Chip de info ─────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF8A94A6)),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8A94A6),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF1A1F36),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── PIN de entrega ───────────────────────────────────────────────────────────

class _PinEntregaWidget extends StatefulWidget {
  const _PinEntregaWidget({required this.pin});
  final String pin;

  @override
  State<_PinEntregaWidget> createState() => _PinEntregaWidgetState();
}

class _PinEntregaWidgetState extends State<_PinEntregaWidget> {
  bool _visible = false;

  void _copiarPin() {
    Clipboard.setData(ClipboardData(text: widget.pin));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              'PIN copiado al portapapeles',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF1B873F),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        children: [
          const Icon(Icons.key_rounded, size: 16, color: Color(0xFFB45309)),
          const SizedBox(width: 8),
          const Text(
            'PIN de entrega',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB45309),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _visible ? widget.pin : '••••••',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _visible
                    ? const Color(0xFF1A1F36)
                    : const Color(0xFFB45309),
                letterSpacing: _visible ? 2 : 4,
                fontFamily: 'monospace',
              ),
            ),
          ),
          // Mostrar / ocultar
          GestureDetector(
            onTap: () => setState(() => _visible = !_visible),
            child: Icon(
              _visible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: const Color(0xFFB45309),
            ),
          ),
          const SizedBox(width: 10),
          // Copiar
          GestureDetector(
            onTap: _copiarPin,
            child: const Icon(
              Icons.copy_rounded,
              size: 16,
              color: Color(0xFFB45309),
            ),
          ),
        ],
      ),
    );
  }
}