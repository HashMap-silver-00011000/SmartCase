import 'package:flutter/material.dart';

import '../clinica_api.dart';
import '../models/clinica.dart';
import 'admin_sede_screen.dart';

class AdminClinicaScreen extends StatefulWidget {
  const AdminClinicaScreen({super.key});

  @override
  State<AdminClinicaScreen> createState() => _AdminClinicaScreenState();
}

class _AdminClinicaScreenState extends State<AdminClinicaScreen> {
  final _api = ClinicaApi();
  List<Clinica> _clinicas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarLista();
  }

  Future<void> _cargarLista() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final res = await _api.listar();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (res.isSuccess && res.data != null) {
        _clinicas = res.data!;
      } else {
        _error = res.errorMessage ?? 'Error al cargar clínicas';
        _clinicas = [];
      }
    });
  }

  Future<void> _mostrarFormulario({Clinica? clinica}) async {
    final nombreCtrl = TextEditingController(text: clinica?.nombre ?? '');
    final esEdicion = clinica != null;
    final guardado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(esEdicion ? 'Editar clínica' : 'Nueva clínica'),
        content: TextField(
          controller: nombreCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
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
      final res = await _api.actualizar(
        Clinica(idClinica: clinica.idClinica, nombre: nombre),
      );
      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clínica actualizada')),
        );
        await _cargarLista();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.errorMessage ?? 'Error al actualizar')),
        );
      }
    } else {
      final res = await _api.crear(ClinicaInput(nombre: nombre));
      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clínica creada')),
        );
        await _cargarLista();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.errorMessage ?? 'Error al crear')),
        );
      }
    }
  }

  Future<void> _confirmarEliminar(Clinica clinica) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar clínica'),
        content: Text('¿Eliminar "${clinica.nombre}"?'),
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

    final res = await _api.eliminar(clinica.idClinica);
    if (!mounted) return;
    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clínica eliminada')),
      );
      await _cargarLista();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.errorMessage ?? 'Error al eliminar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel admin — Clínicas'),
        actions: [
          IconButton(
            onPressed: _cargando
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AdminSedeScreen(),
                      ),
                    );
                  },
            icon: const Icon(Icons.location_city_outlined),
            tooltip: 'Gestionar sedes',
          ),
          IconButton(
            onPressed: _cargando ? null : _cargarLista,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _cargando ? null : () => _mostrarFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva clínica'),
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
                          onPressed: _cargarLista,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _clinicas.isEmpty
                  ? const Center(child: Text('No hay clínicas registradas'))
                  : RefreshIndicator(
                      onRefresh: _cargarLista,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        itemCount: _clinicas.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final c = _clinicas[index];
                          return ListTile(
                            title: Text(c.nombre),
                            subtitle: Text(
                              c.idClinica,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'sedes') {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          AdminSedeScreen(clinicaInicial: c),
                                    ),
                                  );
                                } else if (value == 'editar') {
                                  _mostrarFormulario(clinica: c);
                                } else if (value == 'eliminar') {
                                  _confirmarEliminar(c);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'sedes',
                                  child: ListTile(
                                    leading: Icon(Icons.location_city_outlined),
                                    title: Text('Sedes'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
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
                                    leading: Icon(Icons.delete_outline),
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
    );
  }
}
