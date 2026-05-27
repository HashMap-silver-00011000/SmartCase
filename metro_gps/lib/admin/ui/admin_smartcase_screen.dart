import 'package:flutter/material.dart';

import '../models/smartcase.dart';
import '../smartcase_api.dart';
import 'admin_theme.dart';

class AdminSmartCaseScreen extends StatefulWidget {
  const AdminSmartCaseScreen({super.key});

  @override
  State<AdminSmartCaseScreen> createState() =>
      _AdminSmartCaseScreenState();
}

class _AdminSmartCaseScreenState
    extends State<AdminSmartCaseScreen> {
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
    final organoCtrl =
        TextEditingController(text: item?.organo ?? '');
    var estado =
        item?.estadoSolenoide ?? SmartCase.estadosSolenoide.first;
    final esEdicion = item != null;

    final guardado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
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
                          : Icons.inventory_2_outlined,
                      color: const Color(0xFFE65100),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      esEdicion ? 'Editar SmartCase' : 'Nueva caja',
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
                  controller: organoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Órgano a transportar',
                    prefixIcon:
                        Icon(Icons.medical_services_outlined, size: 20),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: estado,
                  decoration: const InputDecoration(
                    labelText: 'Estado del solenoide',
                    prefixIcon:
                        Icon(Icons.lock_outline, size: 20),
                  ),
                  items: SmartCase.estadosSolenoide
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Row(children: [
                              Icon(
                                e == 'bloqueado'
                                    ? Icons.lock
                                    : Icons.lock_open,
                                size: 18,
                                color: e == 'bloqueado'
                                    ? AdminColors.danger
                                    : AdminColors.success,
                              ),
                              const SizedBox(width: 8),
                              Text(e),
                            ]),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDs(() => estado = v);
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (organoCtrl.text.trim().isEmpty)
                          return;
                        Navigator.pop(ctx, true);
                      },
                      child: Text(
                          esEdicion ? 'Guardar cambios' : 'Crear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
            organo: organo),
      );
      if (!mounted) return;
      _snack(
          res.isSuccess ? 'Caja actualizada' : res.errorMessage,
          esError: !res.isSuccess);
      if (res.isSuccess) await _cargarLista();
    } else {
      final res = await _api.crear(
        SmartCaseInput(estadoSolenoide: estado, organo: organo),
      );
      if (!mounted) return;
      _snack(res.isSuccess ? 'Caja creada' : res.errorMessage,
          esError: !res.isSuccess);
      if (res.isSuccess) await _cargarLista();
    }
  }

  Future<void> _confirmarEliminar(SmartCase item) async {
    final ok = await showDeleteDialog(
      context,
      title: 'Eliminar SmartCase',
      content:
          '¿Eliminar la caja para "${item.organo}"? Esta acción no se puede deshacer.',
    );
    if (!ok || !mounted) return;
    final res = await _api.eliminar(item.idCaja);
    if (!mounted) return;
    _snack(
        res.isSuccess ? 'Caja eliminada' : res.errorMessage,
        esError: !res.isSuccess);
    if (res.isSuccess) await _cargarLista();
  }

  void _snack(String? msg, {bool esError = false}) {
    if (msg == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor:
              esError ? AdminColors.danger : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloqueadas =
        _items.where((c) => c.estadoSolenoide == 'bloqueado').length;
    final libres = _items.length - bloqueadas;

    return Scaffold(
      backgroundColor: AdminColors.surface,
      appBar: AppBar(
        title: const Text('SmartCase'),
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
        label: const Text('Nueva caja'),
        backgroundColor: AdminColors.navy,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AdminErrorState(
                  message: _error!, onRetry: _cargarLista)
              : _items.isEmpty
                  ? const AdminEmptyState(
                      message:
                          'No hay cajas SmartCase registradas',
                      icon: Icons.inventory_2_outlined,
                    )
                  : Column(
                      children: [
                        // Barra de resumen
                        if (_items.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.fromLTRB(
                                16, 16, 16, 0),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AdminColors.navy,
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                _CajaStatChip(
                                  icon: Icons.lock,
                                  label: 'Bloqueadas',
                                  value: bloqueadas,
                                  color: const Color(0xFFFF7043),
                                ),
                                const SizedBox(width: 16),
                                _CajaStatChip(
                                  icon: Icons.lock_open,
                                  label: 'Disponibles',
                                  value: libres,
                                  color: AdminColors.success,
                                ),
                                const Spacer(),
                                Text(
                                  '${_items.length} total',
                                  style: TextStyle(
                                    color: Colors.white
                                        .withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _cargarLista,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(
                                      16, 16, 16, 100),
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final c = _items[index];
                                final bloqueado =
                                    c.estadoSolenoide ==
                                        'bloqueado';
                                return AdminItemCard(
                                  title: c.organo,
                                  subtitle: c.idCaja,
                                  leading: AdminIconAvatar(
                                    icon: bloqueado
                                        ? Icons.lock
                                        : Icons.lock_open,
                                    color: bloqueado
                                        ? const Color(0xFFFF7043)
                                        : AdminColors.success,
                                  ),
                                  badge: AdminStatusBadge(
                                    label: c.estadoSolenoide,
                                    color: bloqueado
                                        ? const Color(0xFFFF7043)
                                        : AdminColors.success,
                                  ),
                                  onEdit: () =>
                                      _mostrarFormulario(item: c),
                                  onDelete: () =>
                                      _confirmarEliminar(c),
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

class _CajaStatChip extends StatelessWidget {
  const _CajaStatChip({
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
        Icon(icon, color: color, size: 16),
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