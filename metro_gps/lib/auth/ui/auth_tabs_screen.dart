import 'package:flutter/material.dart';

import '../../admin/clinica_api.dart';
import '../../admin/ui/admin_panel_screen.dart';
import '../../conductor/ui/conductor_home_screen.dart';
import '../../receptor/ui/receptor_home_screen.dart';
import '../../core/api_constants.dart';
import '../../core/session_store.dart';
import '../auth_api.dart';
import '../models/auth_models.dart';
import '../models/usuario_rol_opciones.dart';

/// Pestañas Login / Registro con formularios enlazados al backend.
class AuthTabsScreen extends StatefulWidget {
  const AuthTabsScreen({super.key});

  @override
  State<AuthTabsScreen> createState() => _AuthTabsScreenState();
}

class _AuthTabsScreenState extends State<AuthTabsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _abrirSiHaySesion());
  }

  bool _esAdmin(String? rol) =>
      rol != null && rol.trim().toLowerCase() == UsuarioRolBd.admin;

  bool _esConductor(String? rol) =>
      rol != null && rol.trim().toLowerCase() == UsuarioRolBd.coductor;

  bool _esReceptor(String? rol) =>
      rol != null && rol.trim().toLowerCase() == UsuarioRolBd.receptor;

  void _abrirSiHaySesion() {
    if (!ClinicaApi.sharedClient.hasSession) return;
    final rol = SessionStore.instance.rol;
    if (_esAdmin(rol)) {
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const AdminPanelScreen()),
      );
    } else if (_esConductor(rol)) {
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => ConductorHomeScreen()), // ← sin const
      );
    } else if (_esReceptor(rol)) {
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ReceptorHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cuenta'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Iniciar sesión'),
              Tab(text: 'Registro'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LoginForm(),
            _RegisterForm(),
          ],
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _api = AuthApi();
  bool _cargando = false;
  bool _ocultarPassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _api.close();
    super.dispose();
  }

  bool _esAdmin(String? rol) =>
      rol != null && rol.trim().toLowerCase() == UsuarioRolBd.admin;

  bool _esConductor(String? rol) =>
      rol != null && rol.trim().toLowerCase() == UsuarioRolBd.coductor;

  bool _esReceptor(String? rol) =>
      rol != null && rol.trim().toLowerCase() == UsuarioRolBd.receptor;

  Future<void> _irAlPanelAdmin() {
    return Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AdminPanelScreen()),
      (_) => false,
    );
  }

  Future<void> _irAlPanelConductor() {
    return Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => ConductorHomeScreen()), // ← sin const
      (_) => false,
    );
  }

  Future<void> _irAlPanelReceptor() {
    return Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const ReceptorHomeScreen()),
      (_) => false,
    );
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      final res = await _api.login(
        LoginInput(email: _email.text.trim(), password: _password.text),
      );
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      if (res.isSuccess) {
        final rol = SessionStore.instance.rol ?? res.rol;
        if (_esAdmin(rol)) {
          await _irAlPanelAdmin();
          return;
        }
        if (_esConductor(rol)) {
          await _irAlPanelConductor();
          return;
        }
        if (_esReceptor(rol)) {
          await _irAlPanelReceptor();
          return;
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              rol == null || rol.isEmpty
                  ? 'Sesión iniciada, pero no se detectó el rol admin'
                  : 'Sesión iniciada (${UsuarioRolBd.etiqueta(rol)})',
            ),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(res.errorMessage ?? 'Error (${res.statusCode})'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo conectar al servidor (${ApiConstants.baseUrl}).\n$e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa el email' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _ocultarPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_cargando) _enviar();
              },
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _ocultarPassword = !_ocultarPassword);
                  },
                  icon: Icon(
                    _ocultarPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Ingresa la contraseña' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _cargando ? null : _enviar,
              child: _cargando
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm();

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCompleto = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _api = AuthApi();
  bool _cargando = false;
  bool _ocultarPassword = true;
  String _rol = UsuarioRolBd.coductor;

  @override
  void dispose() {
    _nombreCompleto.dispose();
    _email.dispose();
    _password.dispose();
    _api.close();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    final res = await _api.registro(
      RegistroInput(
        nombreCompleto: _nombreCompleto.text.trim(),
        rol: _rol,
        email: _email.text.trim(),
        password: _password.text,
      ),
    );
    if (!mounted) return;
    setState(() => _cargando = false);
    final messenger = ScaffoldMessenger.of(context);
    if (res.isSuccess) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Registro exitoso')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(res.errorMessage ?? 'Error (${res.statusCode})'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nombreCompleto,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingresa el nombre completo'
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              'Rol',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in UsuarioRolBd.todos)
                  ChoiceChip(
                    label: Text(UsuarioRolBd.etiqueta(r)),
                    selected: _rol == r,
                    onSelected: _cargando
                        ? null
                        : (selected) {
                            if (selected) setState(() => _rol = r);
                          },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa el email' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _ocultarPassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _ocultarPassword = !_ocultarPassword);
                  },
                  icon: Icon(
                    _ocultarPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Ingresa la contraseña' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _cargando ? null : _enviar,
              child: _cargando
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}