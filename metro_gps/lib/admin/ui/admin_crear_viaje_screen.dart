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

class AdminCrearViajeScreen extends StatefulWidget {
  const AdminCrearViajeScreen({super.key});

  @override
  State<AdminCrearViajeScreen> createState() => _AdminCrearViajeScreenState();
}

class _AdminCrearViajeScreenState extends State<AdminCrearViajeScreen> {
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

  Clinica? _clinicaOrigen;
  Clinica? _clinicaDestino;
  Sede? _sedeOrigen;
  Sede? _sedeDestino;
  Ambulancia? _ambulancia;
  SmartCase? _caja;
  UsuarioConductor? _conductor;
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

    final clinicasRes = await _clinicaApi.listar();
    final ambRes = await _ambulanciaApi.listar();
    final smartRes = await _smartApi.listar();
    final conductoresRes = await _usuarioApi.listarConductores();

    if (!mounted) return;

    final errores = <String>[];
    if (!clinicasRes.isSuccess) {
      errores.add(clinicasRes.errorMessage ?? 'Clínicas');
    }
    if (!ambRes.isSuccess) {
      errores.add(ambRes.errorMessage ?? 'Ambulancias');
    }
    if (!smartRes.isSuccess) {
      errores.add(smartRes.errorMessage ?? 'SmartCase');
    }
    if (!conductoresRes.isSuccess) {
      errores.add(conductoresRes.errorMessage ?? 'Conductores');
    }

    if (!clinicasRes.isSuccess) {
      setState(() {
        _cargando = false;
        _error = errores.join('\n');
      });
      return;
    }

    final clinicas = clinicasRes.data ?? [];
    final ambulancias = ambRes.data ?? [];
    final cajas = smartRes.data ?? [];
    final conductores = conductoresRes.data ?? [];

    setState(() {
      _cargando = false;
      _error = errores.isEmpty ? null : errores.join('\n');
      _errorAmbulancias =
          ambRes.isSuccess ? null : ambRes.errorMessage;
      _clinicas = clinicas;
      _ambulancias = ambulancias;
      _cajas = cajas;
      _conductores = conductores;
      _clinicaOrigen = clinicas.isNotEmpty ? clinicas.first : null;
      _clinicaDestino = clinicas.isNotEmpty ? clinicas.first : null;
      _ambulancia = ambulancias.isNotEmpty ? ambulancias.first : null;
      _caja = cajas.isNotEmpty ? cajas.first : null;
      _conductor = conductores.isNotEmpty ? conductores.first : null;
    });

    await _cargarSedesOrigen();
    await _cargarSedesDestino();
  }

  Future<void> _cargarSedesOrigen() async {
    final clinica = _clinicaOrigen;
    if (clinica == null) {
      setState(() {
        _sedesOrigen = [];
        _sedeOrigen = null;
      });
      return;
    }
    final res = await _sedeApi.listarPorClinica(clinica.idClinica);
    if (!mounted) return;
    setState(() {
      _sedesOrigen = res.data ?? [];
      _sedeOrigen = _sedesOrigen.isNotEmpty ? _sedesOrigen.first : null;
    });
  }

  Future<void> _cargarSedesDestino() async {
    final clinica = _clinicaDestino;
    if (clinica == null) {
      setState(() {
        _sedesDestino = [];
        _sedeDestino = null;
      });
      return;
    }
    final res = await _sedeApi.listarPorClinica(clinica.idClinica);
    if (!mounted) return;
    setState(() {
      _sedesDestino = res.data ?? [];
      _sedeDestino = _sedesDestino.isNotEmpty ? _sedesDestino.first : null;
    });
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_sedeOrigen == null ||
        _sedeDestino == null ||
        _caja == null ||
        _ambulancia == null ||
        _conductor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa sedes, caja, ambulancia y conductor'),
        ),
      );
      return;
    }

    if (_sedeOrigen!.idSede == _sedeDestino!.idSede) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Origen y destino deben ser sedes distintas'),
        ),
      );
      return;
    }

    setState(() => _enviando = true);
    final res = await _viajeApi.crear(
      ViajeInput(
        idCaja: _caja!.idCaja,
        idUsuarioConductor: _conductor!.idUsuario,
        idSedeOrigen: _sedeOrigen!.idSede,
        idSedeDestino: _sedeDestino!.idSede,
        idAmbulancia: _ambulancia!.idAmbulancia,
        estadoViaje: _estado,
      ),
    );
    if (!mounted) return;
    setState(() => _enviando = false);

    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Viaje creado correctamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.errorMessage ?? 'Error al crear el viaje'),
        ),
      );
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear viaje'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _cargarCatalogos,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _sectionTitle('Ruta'),
                      DropdownButtonFormField<Clinica>(
                        value: _clinicaOrigen,
                        decoration: const InputDecoration(
                          labelText: 'Clínica origen',
                          border: OutlineInputBorder(),
                        ),
                        items: _clinicas
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: _enviando
                            ? null
                            : (c) async {
                                setState(() => _clinicaOrigen = c);
                                await _cargarSedesOrigen();
                              },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Sede>(
                        value: _sedeOrigen,
                        decoration: const InputDecoration(
                          labelText: 'Sede origen',
                          border: OutlineInputBorder(),
                        ),
                        items: _sedesOrigen
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: _enviando
                            ? null
                            : (s) => setState(() => _sedeOrigen = s),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Clinica>(
                        value: _clinicaDestino,
                        decoration: const InputDecoration(
                          labelText: 'Clínica destino',
                          border: OutlineInputBorder(),
                        ),
                        items: _clinicas
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: _enviando
                            ? null
                            : (c) async {
                                setState(() => _clinicaDestino = c);
                                await _cargarSedesDestino();
                              },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Sede>(
                        value: _sedeDestino,
                        decoration: const InputDecoration(
                          labelText: 'Sede destino',
                          border: OutlineInputBorder(),
                        ),
                        items: _sedesDestino
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: _enviando
                            ? null
                            : (s) => setState(() => _sedeDestino = s),
                      ),
                      _sectionTitle('Recursos'),
                      DropdownButtonFormField<SmartCase>(
                        value: _caja,
                        decoration: const InputDecoration(
                          labelText: 'Caja SmartCase',
                          border: OutlineInputBorder(),
                        ),
                        items: _cajas
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text('${c.organo} (${c.estadoSolenoide})'),
                              ),
                            )
                            .toList(),
                        onChanged:
                            _enviando ? null : (c) => setState(() => _caja = c),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Ambulancia>(
                        value: _ambulancia,
                        decoration: const InputDecoration(
                          labelText: 'Ambulancia',
                          border: OutlineInputBorder(),
                        ),
                        items: _ambulancias
                            .map(
                              (a) => DropdownMenuItem(
                                value: a,
                                child: Text('${a.placa} · ${a.tipo}'),
                              ),
                            )
                            .toList(),
                        onChanged: _enviando || _ambulancias.isEmpty
                            ? null
                            : (a) => setState(() => _ambulancia = a),
                        validator: (v) =>
                            v == null ? 'Selecciona una ambulancia' : null,
                      ),
                      if (_ambulancias.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _errorAmbulancias ??
                                'No hay ambulancias. Regístralas en Panel → Ambulancias.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<UsuarioConductor>(
                        value: _conductor,
                        decoration: const InputDecoration(
                          labelText: 'Conductor',
                          border: OutlineInputBorder(),
                        ),
                        items: _conductores
                            .map(
                              (u) => DropdownMenuItem(
                                value: u,
                                child: Text(
                                  u.nombreCompleto.isNotEmpty
                                      ? u.nombreCompleto
                                      : u.email,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _enviando
                            ? null
                            : (u) => setState(() => _conductor = u),
                        validator: (v) =>
                            v == null ? 'Selecciona un conductor' : null,
                      ),
                      if (_conductores.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'No hay conductores. Registra un usuario con rol coductor.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _estado,
                        decoration: const InputDecoration(
                          labelText: 'Estado del viaje',
                          border: OutlineInputBorder(),
                        ),
                        items: ViajeInput.estadosPermitidos
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ),
                            )
                            .toList(),
                        onChanged: _enviando
                            ? null
                            : (e) {
                                if (e != null) setState(() => _estado = e);
                              },
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _enviando ? null : _enviar,
                        icon: _enviando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.local_shipping_outlined),
                        label: Text(_enviando ? 'Creando...' : 'Crear viaje'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
