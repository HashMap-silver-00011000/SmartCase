import 'package:flutter/material.dart';

import '../clinica_api.dart';
import '../models/clinica.dart';
import '../models/sede.dart';
import '../sede_api.dart';
import 'admin_theme.dart';

class AdminSedeScreen extends StatefulWidget {
  const AdminSedeScreen({super.key, this.clinicaInicial});
  final Clinica? clinicaInicial;

  @override
  State<AdminSedeScreen> createState() => _AdminSedeScreenState();
}

class _AdminSedeScreenState extends State<AdminSedeScreen> {
  final _clinicaApi = ClinicaApi();
  final _sedeApi = SedeApi();

  List<Clinica> _clinicas = [];
  Clinica? _clinicaSeleccionada;
  List<Sede> _sedes = [];
  bool _cargandoClinicas = true;
  bool _cargandoSedes = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _clinicaSeleccionada = widget.clinicaInicial;
    _cargarClinicas();
  }

  Future<void> _cargarClinicas() async {
    setState(() {
      _cargandoClinicas = true;
      _error = null;
    });
    final res = await _clinicaApi.listar();
    if (!mounted) return;
    if (!res.isSuccess || res.data == null) {
      setState(() {
        _cargandoClinicas = false;
        _error = res.errorMessage ?? 'Error al cargar clínicas';
        _clinicas = [];
      });
      return;
    }
    final idInicial = _clinicaSeleccionada?.idClinica;
    Clinica? seleccionada;
    if (idInicial != null) {
      for (final c in res.data!) {
        if (c.idClinica == idInicial) {
          seleccionada = c;
          break;
        }
      }
    }
    seleccionada ??= res.data!.isNotEmpty ? res.data!.first : null;
    setState(() {
      _cargandoClinicas = false;
      _clinicas = res.data!;
      _clinicaSeleccionada = seleccionada;
    });
    if (seleccionada != null) await _cargarSedes();
  }

  Future<void> _cargarSedes({bool silencioso = false}) async {
    final clinica = _clinicaSeleccionada;
    if (clinica == null) {
      if (mounted) setState(() => _sedes = []);
      return;
    }
    if (!silencioso && mounted) {
      setState(() {
        _cargandoSedes = true;
        _error = null;
      });
    }
    try {
      final res = await _sedeApi.listarPorClinica(clinica.idClinica);
      if (!mounted) return;
      setState(() {
        if (res.isSuccess && res.data != null) {
          _sedes = res.data!;
          _error = null;
        } else {
          _error = res.errorMessage ?? 'Error al cargar sedes';
          if (!silencioso) _sedes = [];
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar sedes: $e';
        if (!silencioso) _sedes = [];
      });
    } finally {
      if (mounted) setState(() => _cargandoSedes = false);
    }
  }

  Future<void> _onClinicaChanged(Clinica? clinica) async {
    if (clinica == null) return;
    setState(() => _clinicaSeleccionada = clinica);
    await _cargarSedes();
  }

  Future<void> _mostrarFormulario({Sede? sede}) async {
    final clinica = _clinicaSeleccionada;
    if (clinica == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una clínica primero')),
      );
      return;
    }

    final nombre = await showDialog<String>(
      context: context,
      builder: (_) => _SedeFormDialog(sede: sede, clinica: clinica),
    );

    if (nombre == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    if (sede != null) {
      final res = await _sedeApi.actualizar(
        Sede(idSede: sede.idSede, idClinica: clinica.idClinica, nombre: nombre),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            res.isSuccess ? 'Sede actualizada' : res.errorMessage ?? '',
          ),
          backgroundColor: res.isSuccess ? null : AdminColors.danger,
        ),
      );
      if (res.isSuccess) await _cargarSedes(silencioso: true);
    } else {
      final res = await _sedeApi.crear(
        SedeInput(idClinica: clinica.idClinica, nombre: nombre),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(res.isSuccess ? 'Sede creada' : res.errorMessage ?? ''),
          backgroundColor: res.isSuccess ? null : AdminColors.danger,
        ),
      );
      if (res.isSuccess) await _cargarSedes(silencioso: true);
    }
  }

  Future<void> _confirmarEliminar(Sede sede) async {
    final ok = await showDeleteDialog(
      context,
      title: 'Eliminar sede',
      content:
          '¿Eliminar la sede "${sede.nombre}"? Esta acción no se puede deshacer.',
    );
    if (!ok || !mounted) return;
    final res = await _sedeApi.eliminar(sede);
    if (!mounted) return;
    _snack(
      res.isSuccess ? 'Sede eliminada' : res.errorMessage,
      esError: !res.isSuccess,
    );
    if (res.isSuccess) await _cargarSedes(silencioso: true);
  }

  void _snack(String? msg, {bool esError = false}) {
    if (msg == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: esError ? AdminColors.danger : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cargando = _cargandoClinicas || _cargandoSedes;
    final sinClinica = !_cargandoClinicas && _clinicas.isEmpty;

    return Scaffold(
      backgroundColor: AdminColors.surface,
      appBar: AppBar(
        title: const Text('Sedes'),
        backgroundColor: AdminColors.navy,
        actions: [
          IconButton(
            onPressed: cargando ? null : _cargarSedes,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: cargando || _clinicaSeleccionada == null
            ? null
            : () => _mostrarFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva sede'),
        backgroundColor: AdminColors.navy,
      ),
      body: _cargandoClinicas
          ? const Center(child: CircularProgressIndicator())
          : sinClinica
          ? const AdminEmptyState(
              message:
                  'No hay clínicas registradas.\nCrea una clínica antes de añadir sedes.',
              icon: Icons.location_city_outlined,
            )
          : Column(
              children: [
                // Selector de clínica
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CLÍNICA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Clinica>(
                        value: _clinicaSeleccionada,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(
                            Icons.local_hospital_outlined,
                            size: 20,
                          ),
                        ),
                        items: _clinicas
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: cargando ? null : _onClinicaChanged,
                      ),
                    ],
                  ),
                ),
                if (_error != null)
                  Container(
                    width: double.infinity,
                    color: AdminColors.danger.withOpacity(0.08),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: AdminColors.danger,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AdminColors.danger,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _cargandoSedes
                      ? const Center(child: CircularProgressIndicator())
                      : _sedes.isEmpty
                      ? AdminEmptyState(
                          message:
                              'No hay sedes para ${_clinicaSeleccionada?.nombre ?? 'esta clínica'}',
                          icon: Icons.place_outlined,
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarSedes,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            itemCount: _sedes.length,
                            itemBuilder: (context, index) {
                              final s = _sedes[index];
                              return AdminItemCard(
                                title: s.nombre,
                                subtitle: s.idSede,
                                leading: const AdminIconAvatar(
                                  icon: Icons.place_outlined,
                                  color: Color(0xFF00897B),
                                ),
                                onEdit: () => _mostrarFormulario(sede: s),
                                onDelete: () => _confirmarEliminar(s),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _SedeFormDialog extends StatefulWidget {
  const _SedeFormDialog({this.sede, required this.clinica});
  final Sede? sede;
  final Clinica clinica;

  @override
  State<_SedeFormDialog> createState() => _SedeFormDialogState();
}

class _SedeFormDialogState extends State<_SedeFormDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.sede?.nombre ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.sede != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const AdminIconAvatar(
                  icon: Icons.location_city_outlined,
                  color: Color(0xFF00897B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        esEdicion ? 'Editar sede' : 'Nueva sede',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.clinica.nombre,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de la sede',
                prefixIcon: Icon(Icons.place_outlined, size: 20),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final v = _ctrl.text.trim();
                    if (v.isEmpty) return;
                    Navigator.pop(context, v);
                  },
                  child: Text(esEdicion ? 'Guardar cambios' : 'Crear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
