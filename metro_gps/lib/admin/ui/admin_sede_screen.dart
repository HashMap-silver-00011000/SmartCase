import 'package:flutter/material.dart';

import '../clinica_api.dart';
import '../models/clinica.dart';
import '../models/sede.dart';
import '../sede_api.dart';

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
    if (seleccionada != null) {
      await _cargarSedes();
    }
  }

  Future<void> _cargarSedes({bool silencioso = false}) async {
    final clinica = _clinicaSeleccionada;
    if (clinica == null) {
      if (!mounted) return;
      setState(() {
        _sedes = [];
        _cargandoSedes = false;
      });
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
      if (mounted) {
        setState(() => _cargandoSedes = false);
      }
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

    final nombreCtrl = TextEditingController(text: sede?.nombre ?? '');
    final esEdicion = sede != null;
    final guardado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(esEdicion ? 'Editar sede' : 'Nueva sede'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Clínica: ${clinica.nombre}',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de la sede',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (nombreCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: Text(esEdicion ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
    );
    if (guardado != true || !mounted) {
      nombreCtrl.dispose();
      return;
    }

    final nombre = nombreCtrl.text.trim();
    nombreCtrl.dispose();

    if (esEdicion) {
      final res = await _sedeApi.actualizar(
        Sede(
          idSede: sede.idSede,
          idClinica: clinica.idClinica,
          nombre: nombre,
        ),
      );
      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sede actualizada')),
        );
        await _cargarSedes(silencioso: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.errorMessage ?? 'Error al actualizar')),
        );
      }
    } else {
      final res = await _sedeApi.crear(
        SedeInput(idClinica: clinica.idClinica, nombre: nombre),
      );
      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sede creada')),
        );
        await _cargarSedes(silencioso: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.errorMessage ?? 'Error al crear')),
        );
      }
    }
  }

  Future<void> _confirmarEliminar(Sede sede) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar sede'),
        content: Text('¿Eliminar "${sede.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final res = await _sedeApi.eliminar(sede);
    if (!mounted) return;
    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sede eliminada')),
      );
      await _cargarSedes(silencioso: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.errorMessage ?? 'Error al eliminar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cargando = _cargandoClinicas || _cargandoSedes;
  final sinClinica = !_cargandoClinicas && _clinicas.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel admin — Sedes'),
        actions: [
          IconButton(
            onPressed: cargando ? null : _cargarSedes,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar sedes',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: cargando || _clinicaSeleccionada == null
            ? null
            : () => _mostrarFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva sede'),
      ),
      body: _cargandoClinicas
          ? const Center(child: CircularProgressIndicator())
          : sinClinica
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No hay clínicas. Crea una clínica antes de asignar sedes.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: DropdownButtonFormField<Clinica>(
                        value: _clinicaSeleccionada,
                        decoration: const InputDecoration(
                          labelText: 'Clínica',
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
                        onChanged: cargando ? null : _onClinicaChanged,
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    Expanded(
                      child: _cargandoSedes
                          ? const Center(child: CircularProgressIndicator())
                          : _sedes.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No hay sedes para esta clínica',
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _cargarSedes,
                                  child: ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      88,
                                    ),
                                    itemCount: _sedes.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final s = _sedes[index];
                                      return ListTile(
                                        title: Text(s.nombre),
                                        subtitle: Text(
                                          s.idSede,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'editar') {
                                              _mostrarFormulario(sede: s);
                                            } else if (value == 'eliminar') {
                                              _confirmarEliminar(s);
                                            }
                                          },
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(
                                              value: 'editar',
                                              child: ListTile(
                                                leading: Icon(Icons.edit),
                                                title: Text('Editar'),
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'eliminar',
                                              child: ListTile(
                                                leading:
                                                    Icon(Icons.delete_outline),
                                                title: Text('Eliminar'),
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ),
                                          ],
                                        ),
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
