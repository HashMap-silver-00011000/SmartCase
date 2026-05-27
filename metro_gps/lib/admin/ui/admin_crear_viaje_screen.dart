import 'package:flutter/material.dart';

import '../ambulancia_api.dart';
import '../clinica_api.dart';
import '../models/ambulancia.dart';
import '../models/clinica.dart';
import '../models/sede.dart';
import '../models/smartcase.dart';
import '../models/usuario.dart';
import '../models/viaje.dart';
import '../sede_api.dart';
import '../smartcase_api.dart';
import '../usuario_api.dart';
import '../viaje_api.dart';
import 'admin_theme.dart';

class AdminCrearViajeScreen extends StatefulWidget {
  const AdminCrearViajeScreen({super.key});

  @override
  State<AdminCrearViajeScreen> createState() =>
      _AdminCrearViajeScreenState();
}

class _AdminCrearViajeScreenState
    extends State<AdminCrearViajeScreen> {
  final _viajeApi = ViajeApi();
  final _clinicaApi = ClinicaApi();
  final _sedeApi = SedeApi();
  final _ambulanciaApi = AmbulanciaApi();
  final _smartApi = SmartCaseApi();
  final _usuarioApi = UsuarioApi();
  final _formKey = GlobalKey<FormState>();

  List<Clinica> _clinicas = [];
  List<Sede> _sedesOrigen = [];
  List<Sede> _sedesDestino = [];
  List<Ambulancia> _ambulancias = [];
  List<SmartCase> _cajas = [];
  List<UsuarioConductor> _conductores = [];
  List<UsuarioConductor> _receptores = [];

  Clinica? _clinicaOrigen;
  Clinica? _clinicaDestino;
  Sede? _sedeOrigen;
  Sede? _sedeDestino;
  Ambulancia? _ambulancia;
  SmartCase? _caja;
  UsuarioConductor? _conductor;
  UsuarioConductor? _receptor;
  String _estado = ViajeInput.estadosPermitidos.first;

  bool _cargando = true;
  bool _enviando = false;
  String? _error;
  String? _errorAmbulancias;

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  Future<void> _cargarCatalogos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final results = await Future.wait([
      _clinicaApi.listar(),
      _ambulanciaApi.listar(),
      _smartApi.listar(),
      _usuarioApi.listarConductores(),
      _usuarioApi.listarReceptores(),
    ]);

    if (!mounted) return;

    final clinicasRes = results[0] as dynamic;
    final ambRes = results[1] as dynamic;
    final smartRes = results[2] as dynamic;
    final conductoresRes = results[3] as dynamic;
    final receptoresRes = results[4] as dynamic;

    if (!clinicasRes.isSuccess) {
      setState(() {
        _cargando = false;
        _error = clinicasRes.errorMessage ??
            'Error al cargar clínicas';
      });
      return;
    }

    final clinicas =
        (clinicasRes.data as List<Clinica>? ?? []);
    final ambulancias =
        (ambRes.data as List<Ambulancia>? ?? []);
    final cajas = (smartRes.data as List<SmartCase>? ?? []);
    final conductores =
        (conductoresRes.data as List<UsuarioConductor>? ?? []);
    final receptores =
        (receptoresRes.data as List<UsuarioConductor>? ?? []);

    setState(() {
      _cargando = false;
      _errorAmbulancias = ambRes.isSuccess
          ? null
          : ambRes.errorMessage as String?;
      _clinicas = clinicas;
      _ambulancias = ambulancias;
      _cajas = cajas;
      _conductores = conductores;
      _receptores = receptores;
      _clinicaOrigen =
          clinicas.isNotEmpty ? clinicas.first : null;
      _clinicaDestino =
          clinicas.isNotEmpty ? clinicas.first : null;
      _ambulancia =
          ambulancias.isNotEmpty ? ambulancias.first : null;
      _caja = cajas.isNotEmpty ? cajas.first : null;
      _conductor =
          conductores.isNotEmpty ? conductores.first : null;
      _receptor =
          receptores.isNotEmpty ? receptores.first : null;
    });

    await Future.wait([
      _cargarSedesOrigen(),
      _cargarSedesDestino(),
    ]);
  }

  Future<void> _cargarSedesOrigen() async {
    final clinica = _clinicaOrigen;
    if (clinica == null) {
      if (mounted) setState(() => _sedesOrigen = []);
      return;
    }
    final res =
        await _sedeApi.listarPorClinica(clinica.idClinica);
    if (!mounted) return;
    setState(() {
      _sedesOrigen = res.data ?? [];
      _sedeOrigen =
          _sedesOrigen.isNotEmpty ? _sedesOrigen.first : null;
    });
  }

  Future<void> _cargarSedesDestino() async {
    final clinica = _clinicaDestino;
    if (clinica == null) {
      if (mounted) setState(() => _sedesDestino = []);
      return;
    }
    final res =
        await _sedeApi.listarPorClinica(clinica.idClinica);
    if (!mounted) return;
    setState(() {
      _sedesDestino = res.data ?? [];
      _sedeDestino =
          _sedesDestino.isNotEmpty ? _sedesDestino.first : null;
    });
  }

  Future<void> _enviar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_sedeOrigen == null ||
        _sedeDestino == null ||
        _caja == null ||
        _ambulancia == null ||
        _conductor == null ||
        _receptor == null) {
      _snack(
          'Completa todos los campos obligatorios',
          esError: true);
      return;
    }

    if (_sedeOrigen!.idSede == _sedeDestino!.idSede) {
      _snack('Origen y destino deben ser sedes distintas',
          esError: true);
      return;
    }

    setState(() => _enviando = true);

    final res = await _viajeApi.crear(
      ViajeInput(
        idCaja: _caja!.idCaja,
        idUsuarioConductor: _conductor!.idUsuario,
        idUsuarioReceptor: _receptor!.idUsuario,
        idSedeOrigen: _sedeOrigen!.idSede,
        idSedeDestino: _sedeDestino!.idSede,
        idAmbulancia: _ambulancia!.idAmbulancia,
        estadoViaje: _estado,
      ),
    );

    if (!mounted) return;
    setState(() => _enviando = false);

    if (res.isSuccess) {
      _snack('¡Viaje creado correctamente!');
      // Limpiar selecciones para un nuevo viaje
      setState(() {
        _sedeOrigen = _sedesOrigen.isNotEmpty
            ? _sedesOrigen.first
            : null;
        _sedeDestino = _sedesDestino.isNotEmpty
            ? _sedesDestino.first
            : null;
      });
    } else {
      _snack(
          res.errorMessage ?? 'No se pudo crear el viaje',
          esError: true);
    }
  }

  void _snack(String msg, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: esError ? AdminColors.danger : null,
      ),
    );
  }

  // ─── Helpers de UI ────────────────────────────────────────────────────────

  Widget _fieldGroup(Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: child,
      );

  Widget _warningBox(String msg) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AdminColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AdminColors.warning.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AdminColors.warning, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  fontSize: 13,
                  color: AdminColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.surface,
      appBar: AppBar(
        title: const Text('Crear viaje'),
        backgroundColor: AdminColors.navy,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AdminErrorState(
                  message: _error!,
                  onRetry: _cargarCatalogos)
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                        16, 16, 16, 100),
                    children: [
                      // ── Ruta ───────────────────────────────────
                      const AdminSectionHeader(
                        'Ruta de transporte',
                        icon: Icons.route_outlined,
                      ),
                      _RouteCard(
                        clinicas: _clinicas,
                        clinicaOrigen: _clinicaOrigen,
                        clinicaDestino: _clinicaDestino,
                        sedesOrigen: _sedesOrigen,
                        sedesDestino: _sedesDestino,
                        sedeOrigen: _sedeOrigen,
                        sedeDestino: _sedeDestino,
                        enabled: !_enviando,
                        onClinicaOrigenChanged: (c) async {
                          setState(() => _clinicaOrigen = c);
                          await _cargarSedesOrigen();
                        },
                        onClinicaDestinoChanged: (c) async {
                          setState(() => _clinicaDestino = c);
                          await _cargarSedesDestino();
                        },
                        onSedeOrigenChanged: (s) =>
                            setState(() => _sedeOrigen = s),
                        onSedeDestinoChanged: (s) =>
                            setState(() => _sedeDestino = s),
                      ),
                      // ── Recursos ───────────────────────────────
                      const AdminSectionHeader(
                        'Recursos asignados',
                        icon: Icons.inventory_outlined,
                      ),
                      _fieldGroup(
                        DropdownButtonFormField<SmartCase>(
                          value: _caja,
                          decoration: const InputDecoration(
                            labelText: 'Caja SmartCase',
                            prefixIcon: Icon(
                                Icons.inventory_2_outlined,
                                size: 20),
                          ),
                          items: _cajas
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                        '${c.organo} · ${c.estadoSolenoide}'),
                                  ))
                              .toList(),
                          onChanged: _enviando
                              ? null
                              : (c) =>
                                  setState(() => _caja = c),
                          validator: (v) => v == null
                              ? 'Selecciona una caja'
                              : null,
                        ),
                      ),
                      _fieldGroup(
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<Ambulancia>(
                              value: _ambulancia,
                              decoration: const InputDecoration(
                                labelText: 'Ambulancia',
                                prefixIcon: Icon(
                                    Icons.emergency_outlined,
                                    size: 20),
                              ),
                              items: _ambulancias
                                  .map((a) => DropdownMenuItem(
                                        value: a,
                                        child: Text(
                                            '${a.placa} · ${a.tipo}'),
                                      ))
                                  .toList(),
                              onChanged: _enviando ||
                                      _ambulancias.isEmpty
                                  ? null
                                  : (a) => setState(
                                      () => _ambulancia = a),
                              validator: (v) => v == null
                                  ? 'Selecciona una ambulancia'
                                  : null,
                            ),
                            if (_ambulancias.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 8),
                                child: _warningBox(
                                  _errorAmbulancias ??
                                      'No hay ambulancias. Regístralas en Panel → Ambulancias.',
                                ),
                              ),
                          ],
                        ),
                      ),
                      // ── Personal ───────────────────────────────
                      const AdminSectionHeader(
                        'Personal',
                        icon: Icons.people_outline,
                      ),
                      _fieldGroup(
                        Column(
                          children: [
                            DropdownButtonFormField<
                                UsuarioConductor>(
                              value: _conductor,
                              decoration: const InputDecoration(
                                labelText: 'Conductor',
                                prefixIcon: Icon(
                                    Icons.drive_eta_outlined,
                                    size: 20),
                              ),
                              items: _conductores
                                  .map((u) => DropdownMenuItem(
                                        value: u,
                                        child: Text(
                                          u.nombreCompleto
                                                  .isNotEmpty
                                              ? u.nombreCompleto
                                              : u.email,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: _enviando
                                  ? null
                                  : (u) => setState(
                                      () => _conductor = u),
                              validator: (v) => v == null
                                  ? 'Selecciona un conductor'
                                  : null,
                            ),
                            if (_conductores.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 8),
                                child: _warningBox(
                                  'No hay conductores registrados.',
                                ),
                              ),
                          ],
                        ),
                      ),
                      _fieldGroup(
                        Column(
                          children: [
                            DropdownButtonFormField<
                                UsuarioConductor>(
                              value: _receptor,
                              decoration: const InputDecoration(
                                labelText: 'Receptor (destino)',
                                prefixIcon: Icon(
                                    Icons.person_pin_outlined,
                                    size: 20),
                              ),
                              items: _receptores
                                  .map((u) => DropdownMenuItem(
                                        value: u,
                                        child: Text(
                                          u.nombreCompleto
                                                  .isNotEmpty
                                              ? u.nombreCompleto
                                              : u.email,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: _enviando
                                  ? null
                                  : (u) => setState(
                                      () => _receptor = u),
                              validator: (v) => v == null
                                  ? 'Selecciona un receptor'
                                  : null,
                            ),
                            if (_receptores.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 8),
                                child: _warningBox(
                                  'No hay receptores registrados.',
                                ),
                              ),
                          ],
                        ),
                      ),
                      // ── Estado ─────────────────────────────────
                      const AdminSectionHeader(
                        'Estado inicial',
                        icon: Icons.flag_outlined,
                      ),
                      _fieldGroup(
                        DropdownButtonFormField<String>(
                          value: _estado,
                          decoration: const InputDecoration(
                            labelText: 'Estado del viaje',
                            prefixIcon: Icon(
                                Icons.traffic_outlined,
                                size: 20),
                          ),
                          items: ViajeInput.estadosPermitidos
                              .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Row(
                                      children: [
                                        Icon(
                                          _iconEstado(e),
                                          size: 18,
                                          color:
                                              _colorEstado(e),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(e),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: _enviando
                              ? null
                              : (e) {
                                  if (e != null) {
                                    setState(() => _estado = e);
                                  }
                                },
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ── Botón enviar ───────────────────────────
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed:
                              _enviando ? null : _enviar,
                          icon: _enviando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.local_shipping_outlined),
                          label: Text(
                            _enviando
                                ? 'Creando viaje...'
                                : 'Crear viaje',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  IconData _iconEstado(String estado) {
    switch (estado) {
      case 'transito':
        return Icons.directions_car;
      case 'entregado':
        return Icons.check_circle_outline;
      default:
        return Icons.warning_amber_outlined;
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'transito':
        return AdminColors.cyanDim;
      case 'entregado':
        return AdminColors.success;
      default:
        return AdminColors.danger;
    }
  }
}

// ─── Tarjeta visual de ruta origen → destino ─────────────────────────────────

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.clinicas,
    required this.clinicaOrigen,
    required this.clinicaDestino,
    required this.sedesOrigen,
    required this.sedesDestino,
    required this.sedeOrigen,
    required this.sedeDestino,
    required this.enabled,
    required this.onClinicaOrigenChanged,
    required this.onClinicaDestinoChanged,
    required this.onSedeOrigenChanged,
    required this.onSedeDestinoChanged,
  });

  final List<Clinica> clinicas;
  final Clinica? clinicaOrigen;
  final Clinica? clinicaDestino;
  final List<Sede> sedesOrigen;
  final List<Sede> sedesDestino;
  final Sede? sedeOrigen;
  final Sede? sedeDestino;
  final bool enabled;
  final ValueChanged<Clinica?> onClinicaOrigenChanged;
  final ValueChanged<Clinica?> onClinicaDestinoChanged;
  final ValueChanged<Sede?> onSedeOrigenChanged;
  final ValueChanged<Sede?> onSedeDestinoChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.divider),
      ),
      child: Column(
        children: [
          // Origen
          _RouteSection(
            label: 'ORIGEN',
            color: AdminColors.cyanDim,
            icon: Icons.trip_origin,
            clinicas: clinicas,
            selectedClinica: clinicaOrigen,
            sedes: sedesOrigen,
            selectedSede: sedeOrigen,
            enabled: enabled,
            onClinicaChanged: onClinicaOrigenChanged,
            onSedeChanged: onSedeOrigenChanged,
          ),
          // Divisor con flecha
          Container(
            height: 36,
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal:
                    BorderSide(color: AdminColors.divider),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: AdminColors.divider,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AdminColors.divider),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_downward,
                          size: 14,
                          color: AdminColors.textSecondary),
                      SizedBox(width: 4),
                      Text(
                        'hacia',
                        style: TextStyle(
                          fontSize: 12,
                          color: AdminColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: AdminColors.divider,
                  ),
                ),
              ],
            ),
          ),
          // Destino
          _RouteSection(
            label: 'DESTINO',
            color: AdminColors.success,
            icon: Icons.location_on_outlined,
            clinicas: clinicas,
            selectedClinica: clinicaDestino,
            sedes: sedesDestino,
            selectedSede: sedeDestino,
            enabled: enabled,
            onClinicaChanged: onClinicaDestinoChanged,
            onSedeChanged: onSedeDestinoChanged,
          ),
        ],
      ),
    );
  }
}

class _RouteSection extends StatelessWidget {
  const _RouteSection({
    required this.label,
    required this.color,
    required this.icon,
    required this.clinicas,
    required this.selectedClinica,
    required this.sedes,
    required this.selectedSede,
    required this.enabled,
    required this.onClinicaChanged,
    required this.onSedeChanged,
  });

  final String label;
  final Color color;
  final IconData icon;
  final List<Clinica> clinicas;
  final Clinica? selectedClinica;
  final List<Sede> sedes;
  final Sede? selectedSede;
  final bool enabled;
  final ValueChanged<Clinica?> onClinicaChanged;
  final ValueChanged<Sede?> onSedeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Clinica>(
            value: selectedClinica,
            decoration: const InputDecoration(
              labelText: 'Clínica',
              prefixIcon: Icon(
                  Icons.local_hospital_outlined,
                  size: 18),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
            items: clinicas
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.nombre),
                    ))
                .toList(),
            onChanged: enabled ? onClinicaChanged : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<Sede>(
            value: selectedSede,
            decoration: const InputDecoration(
              labelText: 'Sede',
              prefixIcon:
                  Icon(Icons.place_outlined, size: 18),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
            items: sedes
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.nombre),
                    ))
                .toList(),
            onChanged: enabled ? onSedeChanged : null,
          ),
        ],
      ),
    );
  }
}