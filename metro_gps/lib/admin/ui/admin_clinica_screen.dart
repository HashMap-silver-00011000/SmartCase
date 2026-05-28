import 'package:flutter/material.dart';

import '../clinica_api.dart';
import '../models/clinica.dart';
import 'admin_sede_screen.dart';
import 'admin_theme.dart';

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
  final esEdicion = clinica != null;

  // Returns the trimmed name string, or null if cancelled
  final nombre = await showDialog<String>(
    context: context,
    builder: (_) => _ClinicaFormDialog(clinica: clinica),
  );

  if (nombre == null || !mounted) return;

  final messenger = ScaffoldMessenger.of(context);

  if (esEdicion) {
    final res = await _api.actualizar(
      Clinica(idClinica: clinica.idClinica, nombre: nombre),
    );
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(
          res.isSuccess ? 'Clínica actualizada' : res.errorMessage ?? ''),
      backgroundColor: res.isSuccess ? null : AdminColors.danger,
    ));
    if (res.isSuccess) await _cargarLista();
  } else {
    final res = await _api.crear(ClinicaInput(nombre: nombre));
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(res.isSuccess ? 'Clínica creada' : res.errorMessage ?? ''),
      backgroundColor: res.isSuccess ? null : AdminColors.danger,
    ));
    if (res.isSuccess) await _cargarLista();
  }
}
  Future<void> _confirmarEliminar(Clinica clinica) async {
    final ok = await showDeleteDialog(
      context,
      title: 'Eliminar clínica',
      content:
          '¿Eliminar "${clinica.nombre}"? Se perderán también sus sedes asociadas.',
    );
    if (!ok || !mounted) return;
    final res = await _api.eliminar(clinica.idClinica);
    if (!mounted) return;
    _snack(res.isSuccess ? 'Clínica eliminada' : res.errorMessage,
        esError: !res.isSuccess);
    if (res.isSuccess) await _cargarLista();
  }

  void _snack(String? msg, {bool esError = false}) {
    if (msg == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: esError ? AdminColors.danger : null),
    );
  }

  void _irASedes([Clinica? c]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminSedeScreen(clinicaInicial: c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.surface,
      appBar: AppBar(
        title: const Text('Clínicas'),
        backgroundColor: AdminColors.navy,
        actions: [
          IconButton(
            onPressed:
                _cargando ? null : () => _irASedes(),
            icon: const Icon(Icons.location_city_outlined),
            tooltip: 'Ver todas las sedes',
          ),
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
        label: const Text('Nueva clínica'),
        backgroundColor: AdminColors.navy,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AdminErrorState(
                  message: _error!, onRetry: _cargarLista)
              : _clinicas.isEmpty
                  ? const AdminEmptyState(
                      message: 'No hay clínicas registradas',
                      icon: Icons.local_hospital_outlined,
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarLista,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            16, 16, 16, 100),
                        itemCount: _clinicas.length,
                        itemBuilder: (context, index) {
                          final c = _clinicas[index];
                          return _ClinicaCard(
                            clinica: c,
                            onSedes: () => _irASedes(c),
                            onEditar: () =>
                                _mostrarFormulario(clinica: c),
                            onEliminar: () =>
                                _confirmarEliminar(c),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ClinicaCard extends StatelessWidget {
  const _ClinicaCard({
    required this.clinica,
    required this.onSedes,
    required this.onEditar,
    required this.onEliminar,
  });

  final Clinica clinica;
  final VoidCallback onSedes;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.divider),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.fromLTRB(16, 10, 12, 4),
            leading: const AdminIconAvatar(
              icon: Icons.local_hospital_outlined,
              color: Color(0xFF0096C7),
            ),
            title: Text(
              clinica.nombre,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AdminColors.textPrimary,
              ),
            ),
            subtitle: Text(
              clinica.idClinica,
              style: const TextStyle(
                fontSize: 12,
                color: AdminColors.textMuted,
                fontFamily: 'monospace',
              ),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  color: AdminColors.textSecondary),
              onSelected: (v) {
                if (v == 'sedes') onSedes();
                if (v == 'editar') onEditar();
                if (v == 'eliminar') onEliminar();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'sedes',
                  child: Row(children: [
                    Icon(Icons.location_city_outlined,
                        size: 18,
                        color: AdminColors.textSecondary),
                    SizedBox(width: 10),
                    Text('Ver sedes', style: TextStyle(fontSize: 14)),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'editar',
                  child: Row(children: [
                    Icon(Icons.edit_outlined,
                        size: 18, color: AdminColors.cyanDim),
                    SizedBox(width: 10),
                    Text('Editar', style: TextStyle(fontSize: 14)),
                  ]),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'eliminar',
                  child: Row(children: [
                    Icon(Icons.delete_outline,
                        size: 18, color: AdminColors.danger),
                    const SizedBox(width: 10),
                    Text('Eliminar',
                        style: TextStyle(
                            fontSize: 14,
                            color: AdminColors.danger)),
                  ]),
                ),
              ],
            ),
          ),
          // Botón de sedes
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: OutlinedButton.icon(
              onPressed: onSedes,
              icon: const Icon(Icons.location_city_outlined,
                  size: 16),
              label: const Text('Gestionar sedes'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0096C7),
                side: const BorderSide(
                    color: Color(0xFF0096C7), width: 1),
                minimumSize:
                    const Size(double.infinity, 36),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class _ClinicaFormDialog extends StatefulWidget {
  const _ClinicaFormDialog({this.clinica});
  final Clinica? clinica;

  @override
  State<_ClinicaFormDialog> createState() => _ClinicaFormDialogState();
}

class _ClinicaFormDialogState extends State<_ClinicaFormDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.clinica?.nombre ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();   // Flutter calls this at the right time
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.clinica != null;
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
                      : Icons.local_hospital_outlined,
                  color: const Color(0xFF0096C7),
                ),
                const SizedBox(width: 12),
                Text(
                  esEdicion ? 'Editar clínica' : 'Nueva clínica',
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
              controller: _ctrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de la clínica',
                prefixIcon: Icon(Icons.business_outlined, size: 20),
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
                    Navigator.pop(context, v); // returns the name string
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