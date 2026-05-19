import 'package:flutter/material.dart';

import '../ambulancia_api.dart';
import '../models/ambulancia.dart';

class AdminAmbulanciaScreen extends StatefulWidget {
  const AdminAmbulanciaScreen({super.key});

  @override
  State<AdminAmbulanciaScreen> createState() => _AdminAmbulanciaScreenState();
}

class _AdminAmbulanciaScreenState extends State<AdminAmbulanciaScreen> {
  final _api = AmbulanciaApi();
  List<Ambulancia> _items = [];
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
        _items = res.data!;
      } else {
        _error = res.errorMessage ?? 'Error al cargar ambulancias';
        _items = [];
      }
    });
  }

  Future<void> _mostrarFormulario({Ambulancia? item}) async {
    final placaCtrl = TextEditingController(text: item?.placa ?? '');
    var tipo = item?.tipo ?? Ambulancia.tiposPermitidos.first;
    final esEdicion = item != null;

    final guardado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(esEdicion ? 'Editar ambulancia' : 'Nueva ambulancia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: placaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Placa',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: Ambulancia.tiposPermitidos
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => tipo = v);
                },
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
                if (placaCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: Text(esEdicion ? 'Guardar' : 'Crear'),
            ),
          ],
        ),
      ),
    );

    if (guardado != true || !mounted) {
      placaCtrl.dispose();
      return;
    }

    final placa = placaCtrl.text.trim();
    placaCtrl.dispose();

    if (esEdicion) {
      final res = await _api.actualizar(
        Ambulancia(
          idAmbulancia: item.idAmbulancia,
          placa: placa,
          tipo: tipo,
        ),
      );
      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ambulancia actualizada')),
        );
        await _cargarLista();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.errorMessage ?? 'Error al actualizar')),
        );
      }
    } else {
      final res = await _api.crear(AmbulanciaInput(placa: placa, tipo: tipo));
      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ambulancia creada')),
        );
        await _cargarLista();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.errorMessage ?? 'Error al crear')),
        );
      }
    }
  }

  Future<void> _confirmarEliminar(Ambulancia item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar ambulancia'),
        content: Text('¿Eliminar placa "${item.placa}"?'),
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

    final res = await _api.eliminar(item.idAmbulancia);
    if (!mounted) return;
    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ambulancia eliminada')),
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
        title: const Text('Panel admin — Ambulancias'),
        actions: [
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
        label: const Text('Nueva ambulancia'),
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
              : _items.isEmpty
                  ? const Center(child: Text('No hay ambulancias registradas'))
                  : RefreshIndicator(
                      onRefresh: _cargarLista,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final a = _items[index];
                          return ListTile(
                            leading: Icon(
                              a.tipo == 'moto'
                                  ? Icons.two_wheeler
                                  : Icons.local_hospital,
                            ),
                            title: Text(a.placa),
                            subtitle: Text('${a.tipo} · ${a.idAmbulancia}'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'editar') {
                                  _mostrarFormulario(item: a);
                                } else if (value == 'eliminar') {
                                  _confirmarEliminar(a);
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
