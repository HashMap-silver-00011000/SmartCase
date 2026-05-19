import 'package:flutter/material.dart';

import '../models/smartcase.dart';
import '../smartcase_api.dart';

class AdminSmartCaseScreen extends StatefulWidget {
  const AdminSmartCaseScreen({super.key});

  @override
  State<AdminSmartCaseScreen> createState() => _AdminSmartCaseScreenState();
}

class _AdminSmartCaseScreenState extends State<AdminSmartCaseScreen> {
  final _api = SmartCaseApi();
  List<SmartCase> _items = [];
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
        _error = res.errorMessage ?? 'Error al cargar cajas';
        _items = [];
      }
    });
  }

  Future<void> _mostrarFormulario({SmartCase? item}) async {
    final organoCtrl = TextEditingController(text: item?.organo ?? '');
    var estado =
        item?.estadoSolenoide ?? SmartCase.estadosSolenoide.first;
    final esEdicion = item != null;

    final guardado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(esEdicion ? 'Editar SmartCase' : 'Nueva caja'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: estado,
                decoration: const InputDecoration(
                  labelText: 'Estado solenoide',
                  border: OutlineInputBorder(),
                ),
                items: SmartCase.estadosSolenoide
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => estado = v);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: organoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Órgano',
                  border: OutlineInputBorder(),
                ),
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
                if (organoCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: Text(esEdicion ? 'Guardar' : 'Crear'),
            ),
          ],
        ),
      ),
    );

    if (guardado != true || !mounted) {
      organoCtrl.dispose();
      return;
    }

    final organo = organoCtrl.text.trim();
    organoCtrl.dispose();

    if (esEdicion) {
      final res = await _api.actualizar(
        SmartCase(
          idCaja: item.idCaja,
          estadoSolenoide: estado,
          organo: organo,
        ),
      );
      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caja actualizada')),
        );
        await _cargarLista();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.errorMessage ?? 'Error al actualizar')),
        );
      }
    } else {
      final res = await _api.crear(
        SmartCaseInput(estadoSolenoide: estado, organo: organo),
      );
      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caja creada')),
        );
        await _cargarLista();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.errorMessage ?? 'Error al crear')),
        );
      }
    }
  }

  Future<void> _confirmarEliminar(SmartCase item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar caja'),
        content: Text('¿Eliminar caja de "${item.organo}"?'),
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

    final res = await _api.eliminar(item.idCaja);
    if (!mounted) return;
    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caja eliminada')),
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
        title: const Text('Panel admin — SmartCase'),
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
        label: const Text('Nueva caja'),
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
                  ? const Center(child: Text('No hay cajas registradas'))
                  : RefreshIndicator(
                      onRefresh: _cargarLista,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final c = _items[index];
                          return ListTile(
                            leading: Icon(
                              c.estadoSolenoide == 'bloqueado'
                                  ? Icons.lock
                                  : Icons.lock_open,
                            ),
                            title: Text(c.organo),
                            subtitle: Text(
                              '${c.estadoSolenoide} · ${c.idCaja}',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'editar') {
                                  _mostrarFormulario(item: c);
                                } else if (value == 'eliminar') {
                                  _confirmarEliminar(c);
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
