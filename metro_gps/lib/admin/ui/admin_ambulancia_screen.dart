import 'package:flutter/material.dart';

import '../ambulancia_api.dart';
import '../models/ambulancia.dart';
import 'admin_theme.dart';

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
    final resultado = await showDialog<({String placa, String tipo})>(
      context: context,
      builder: (_) => _AmbulanciaFormDialog(item: item),
    );

    if (resultado == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    if (item != null) {
      final res = await _api.actualizar(
        Ambulancia(
          idAmbulancia: item.idAmbulancia,
          placa: resultado.placa,
          tipo: resultado.tipo,
        ),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            res.isSuccess ? 'Ambulancia actualizada' : res.errorMessage ?? '',
          ),
          backgroundColor: res.isSuccess ? null : AdminColors.danger,
        ),
      );
      if (res.isSuccess) await _cargarLista();
    } else {
      final res = await _api.crear(
        AmbulanciaInput(placa: resultado.placa, tipo: resultado.tipo),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            res.isSuccess ? 'Ambulancia creada' : res.errorMessage ?? '',
          ),
          backgroundColor: res.isSuccess ? null : AdminColors.danger,
        ),
      );
      if (res.isSuccess) await _cargarLista();
    }
  }

  Future<void> _confirmarEliminar(Ambulancia item) async {
    final ok = await showDeleteDialog(
      context,
      title: 'Eliminar ambulancia',
      content:
          '¿Confirmas que deseas eliminar la ambulancia con placa "${item.placa}"? Esta acción no se puede deshacer.',
    );
    if (!ok || !mounted) return;

    final res = await _api.eliminar(item.idAmbulancia);
    if (!mounted) return;
    _mostrarSnack(
      res.isSuccess ? 'Ambulancia eliminada' : res.errorMessage,
      esError: !res.isSuccess,
    );
    if (res.isSuccess) await _cargarLista();
  }

  void _mostrarSnack(String? msg, {bool esError = false}) {
    if (msg == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: esError ? AdminColors.danger : null,
      ),
    );
  }

  // ─── Contadores resumen ────────────────────────────────────────────────────

  Widget _buildSummary() {
    if (_items.isEmpty) return const SizedBox.shrink();
    final motos = _items.where((a) => a.tipo == 'moto').length;
    final ambulancias = _items.where((a) => a.tipo == 'ambulancia').length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.navy,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.local_hospital,
            label: 'Ambulancias',
            value: ambulancias,
            color: AdminColors.cyan,
          ),
          const SizedBox(width: 12),
          _StatChip(
            icon: Icons.two_wheeler,
            label: 'Motos',
            value: motos,
            color: Colors.amberAccent,
          ),
          const Spacer(),
          Text(
            '${_items.length} total',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.surface,
      appBar: AppBar(
        title: const Text('Ambulancias'),
        backgroundColor: AdminColors.navy,
        actions: [
          IconButton(
            onPressed: _cargando ? null : _cargarLista,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _cargando ? null : () => _mostrarFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva ambulancia'),
        backgroundColor: AdminColors.navy,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? AdminErrorState(message: _error!, onRetry: _cargarLista)
          : _items.isEmpty
          ? const AdminEmptyState(
              message: 'No hay ambulancias registradas',
              icon: Icons.emergency_outlined,
            )
          : Column(
              children: [
                _buildSummary(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _cargarLista,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 0),
                      itemBuilder: (context, index) {
                        final a = _items[index];
                        return AdminItemCard(
                          title: a.placa,
                          subtitle: a.idAmbulancia,
                          leading: AdminIconAvatar(
                            icon: a.tipo == 'moto'
                                ? Icons.two_wheeler
                                : Icons.local_hospital_outlined,
                            color: a.tipo == 'moto'
                                ? Colors.amber
                                : AdminColors.cyanDim,
                          ),
                          badge: AdminStatusBadge(
                            label: a.tipo,
                            color: a.tipo == 'moto'
                                ? Colors.amber
                                : AdminColors.cyanDim,
                          ),
                          onEdit: () => _mostrarFormulario(item: a),
                          onDelete: () => _confirmarEliminar(a),
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

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AmbulanciaFormDialog extends StatefulWidget {
  const _AmbulanciaFormDialog({this.item});
  final Ambulancia? item;

  @override
  State<_AmbulanciaFormDialog> createState() => _AmbulanciaFormDialogState();
}

class _AmbulanciaFormDialogState extends State<_AmbulanciaFormDialog> {
  late final TextEditingController _placaCtrl;
  late String _tipo;

  @override
  void initState() {
    super.initState();
    _placaCtrl = TextEditingController(text: widget.item?.placa ?? '');
    _tipo = widget.item?.tipo ?? Ambulancia.tiposPermitidos.first;
  }

  @override
  void dispose() {
    _placaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.item != null;
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
                AdminIconAvatar(
                  icon: esEdicion
                      ? Icons.edit_outlined
                      : Icons.add_circle_outline,
                  color: AdminColors.cyanDim,
                ),
                const SizedBox(width: 12),
                Text(
                  esEdicion ? 'Editar ambulancia' : 'Nueva ambulancia',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _placaCtrl,
              decoration: const InputDecoration(
                labelText: 'Placa',
                prefixIcon: Icon(Icons.directions_car_outlined, size: 20),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _tipo,
              decoration: const InputDecoration(
                labelText: 'Tipo de vehículo',
                prefixIcon: Icon(Icons.local_hospital_outlined, size: 20),
              ),
              items: Ambulancia.tiposPermitidos
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Icon(
                            t == 'moto'
                                ? Icons.two_wheeler
                                : Icons.local_hospital,
                            size: 18,
                            color: AdminColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(t),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _tipo = v);
              },
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
                    final placa = _placaCtrl.text.trim();
                    if (placa.isEmpty) return;
                    Navigator.pop(context, (placa: placa, tipo: _tipo));
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
