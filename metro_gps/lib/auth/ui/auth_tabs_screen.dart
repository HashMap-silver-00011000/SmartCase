// lib/auth/ui/auth_tabs_screen.dart

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

// ─── Colores compartidos ──────────────────────────────────────────────────────

const _kBlue = Color(0xFF1A73E8);
const _kBlueLight = Color(0xFFF0F7FF);
const _kBlueBorder = Color(0xFFB5D4F4);
const _kBlueDark = Color(0xFF1565C0);
const _kBlueSub = Color(0xFFB5D4F4);

const _kGreen = Color(0xFF0F6E56);
const _kGreenLight = Color(0xFFF0FBF7);
const _kGreenBorder = Color(0xFF9FE1CB);
const _kGreenDark = Color(0xFF085041);
const _kGreenSub = Color(0xFF9FE1CB);

const _kBg = Color(0xFFF4F6FA);
const _kCard = Colors.white;
const _kBorder = Color(0xFFE8ECF2);
const _kTextPrimary = Color(0xFF1A1F36);
const _kTextMuted = Color(0xFF8A94A6);

// ─── Pantalla principal ───────────────────────────────────────────────────────

class AuthTabsScreen extends StatefulWidget {
  const AuthTabsScreen({super.key});

  @override
  State<AuthTabsScreen> createState() => _AuthTabsScreenState();
}

class _AuthTabsScreenState extends State<AuthTabsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _abrirSiHaySesion());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _enLogin => _tabController.index == 0;

  bool _esAdmin(String? rol) =>
      rol != null && rol.trim().toLowerCase() == UsuarioRolBd.admin;
  bool _esConductor(String? rol) =>
      rol != null && rol.trim().toLowerCase() == UsuarioRolBd.coductor;
  bool _esReceptor(String? rol) =>
      rol != null && rol.trim().toLowerCase() == UsuarioRolBd.receptor;

  void _abrirSiHaySesion() {
    if (!ClinicaApi.sharedClient.hasSession) return;
    final rol = SessionStore.instance.rol;
    _navegar(rol);
  }

  void _navegar(String? rol) {
    if (!mounted) return;
    if (_esAdmin(rol)) {
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const AdminPanelScreen()),
      );
    } else if (_esConductor(rol)) {
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => ConductorHomeScreen()),
      );
    } else if (_esReceptor(rol)) {
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ReceptorHomeScreen()),
      );
    }
  }

  Color get _headerColor => _enLogin ? _kBlue : _kGreen;
  Color get _headerDark => _enLogin ? _kBlueDark : _kGreenDark;
  Color get _headerSub => _enLogin ? _kBlueSub : _kGreenSub;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Cabecera coloreada ─────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            color: _headerColor,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              left: 24,
              right: 24,
              bottom: 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Container(
                    key: ValueKey(_enLogin),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _enLogin
                          ? const Color(0xFFE6F1FB)
                          : const Color(0xFFE6F4EA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _enLogin
                          ? Icons.medical_services_outlined
                          : Icons.person_add_outlined,
                      size: 26,
                      color: _headerColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    key: ValueKey(_enLogin),
                    _enLogin ? 'Bienvenido' : 'Crear cuenta',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _enLogin
                      ? 'Accede a tu cuenta para continuar'
                      : 'Completa los datos para registrarte',
                  style: TextStyle(
                    fontSize: 13,
                    color: _headerSub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Tabs ────────────────────────────────────────────
                TabBar(
                  controller: _tabController,
                  indicator: UnderlineTabIndicator(
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                    insets: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: _headerSub,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Iniciar sesión'),
                    Tab(text: 'Registro'),
                  ],
                ),
              ],
            ),
          ),

          // ── Contenido ───────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _LoginForm(onRegistrarse: () => _tabController.animateTo(1)),
                _RegisterForm(onIniciarSesion: () => _tabController.animateTo(0)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Formulario de login ──────────────────────────────────────────────────────

class _LoginForm extends StatefulWidget {
  const _LoginForm({required this.onRegistrarse});
  final VoidCallback onRegistrarse;

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

  bool _esAdmin(String? r) =>
      r != null && r.trim().toLowerCase() == UsuarioRolBd.admin;
  bool _esConductor(String? r) =>
      r != null && r.trim().toLowerCase() == UsuarioRolBd.coductor;
  bool _esReceptor(String? r) =>
      r != null && r.trim().toLowerCase() == UsuarioRolBd.receptor;

  Future<void> _navegar(String? rol) async {
    if (_esAdmin(rol)) {
      await Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AdminPanelScreen()),
        (_) => false,
      );
    } else if (_esConductor(rol)) {
      await Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => ConductorHomeScreen()),
        (_) => false,
      );
    } else if (_esReceptor(rol)) {
      await Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const ReceptorHomeScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      final res = await _api.login(
        LoginInput(email: _email.text.trim(), password: _password.text),
      );
      if (!mounted) return;
      if (res.isSuccess) {
        final rol = SessionStore.instance.rol ?? res.rol;
        await _navegar(rol);
        if (!mounted) return;
        if (!_esAdmin(rol) && !_esConductor(rol) && !_esReceptor(rol)) {
          _showSnack(
            rol == null || rol.isEmpty
                ? 'Sesión iniciada, pero no se detectó el rol'
                : 'Sesión iniciada (${UsuarioRolBd.etiqueta(rol)})',
            isError: false,
          );
        }
      } else {
        _showSnack(res.errorMessage ?? 'Error (${res.statusCode})',
            isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        'No se pudo conectar al servidor (${ApiConstants.baseUrl})',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFB71C1C) : _kBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AuthCard(
              children: [
                _AuthField(
                  controller: _email,
                  label: 'Correo electrónico',
                  hint: 'usuario@clinica.com',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  accentColor: _kBlue,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa el correo'
                      : null,
                ),
                const SizedBox(height: 16),
                _AuthField(
                  controller: _password,
                  label: 'Contraseña',
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _ocultarPassword,
                  accentColor: _kBlue,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!_cargando) _enviar();
                  },
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _ocultarPassword = !_ocultarPassword),
                    icon: Icon(
                      _ocultarPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: _kTextMuted,
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Ingresa la contraseña' : null,
                ),
                const SizedBox(height: 24),
                _AuthButton(
                  label: 'Entrar',
                  color: _kBlue,
                  cargando: _cargando,
                  onPressed: _enviar,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FooterLink(
              texto: '¿No tienes cuenta?',
              accion: 'Regístrate',
              color: _kBlue,
              onTap: widget.onRegistrarse,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Formulario de registro ───────────────────────────────────────────────────

class _RegisterForm extends StatefulWidget {
  const _RegisterForm({required this.onIniciarSesion});
  final VoidCallback onIniciarSesion;

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.isSuccess
              ? 'Registro exitoso'
              : (res.errorMessage ?? 'Error (${res.statusCode})'),
        ),
        backgroundColor:
            res.isSuccess ? _kGreen : const Color(0xFFB71C1C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
    if (res.isSuccess) widget.onIniciarSesion();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AuthCard(
              children: [
                // Nombre
                _AuthField(
                  controller: _nombreCompleto,
                  label: 'Nombre completo',
                  hint: 'Ej. María González',
                  icon: Icons.person_outline_rounded,
                  accentColor: _kGreen,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa el nombre completo'
                      : null,
                ),
                const SizedBox(height: 16),

                // Rol
                _FieldLabel(label: 'Rol', icon: Icons.badge_outlined),
                const SizedBox(height: 8),
                Row(
                  children: UsuarioRolBd.todos.map((r) {
                    final seleccionado = _rol == r;
                    return Expanded(
                      child: GestureDetector(
                        onTap: _cargando
                            ? null
                            : () => setState(() => _rol = r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: EdgeInsets.only(
                            right: r == UsuarioRolBd.todos.last ? 0 : 8,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: seleccionado
                                ? _kGreenLight
                                : Colors.transparent,
                            border: Border.all(
                              color:
                                  seleccionado ? _kGreen : _kBorder,
                              width: seleccionado ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            UsuarioRolBd.etiqueta(r),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: seleccionado ? _kGreen : _kTextMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Email
                _AuthField(
                  controller: _email,
                  label: 'Correo electrónico',
                  hint: 'correo@ejemplo.com',
                  icon: Icons.alternate_email_rounded,
                  accentColor: _kGreen,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa el correo'
                      : null,
                ),
                const SizedBox(height: 16),

                // Contraseña
                _AuthField(
                  controller: _password,
                  label: 'Contraseña',
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  accentColor: _kGreen,
                  obscureText: _ocultarPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!_cargando) _enviar();
                  },
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _ocultarPassword = !_ocultarPassword),
                    icon: Icon(
                      _ocultarPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: _kTextMuted,
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Ingresa la contraseña' : null,
                ),
                const SizedBox(height: 24),
                _AuthButton(
                  label: 'Crear cuenta',
                  color: _kGreen,
                  cargando: _cargando,
                  onPressed: _enviar,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FooterLink(
              texto: '¿Ya tienes cuenta?',
              accion: 'Inicia sesión',
              color: _kGreen,
              onTap: widget.onIniciarSesion,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Componentes compartidos ──────────────────────────────────────────────────

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: _kTextMuted),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _kTextMuted,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.accentColor,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.suffixIcon,
    this.onFieldSubmitted,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color accentColor;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final Widget? suffixIcon;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label, icon: icon),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          style: const TextStyle(
            fontSize: 14,
            color: _kTextPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: _kTextMuted,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(icon, size: 18, color: _kTextMuted),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: _kBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE53935), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE53935), width: 1.5),
            ),
            errorStyle: const TextStyle(
              fontSize: 11,
              color: Color(0xFFE53935),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.color,
    required this.cargando,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final bool cargando;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: cargando ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        child: cargando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.texto,
    required this.accion,
    required this.color,
    required this.onTap,
  });

  final String texto;
  final String accion;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: _kTextMuted),
          children: [
            TextSpan(text: '$texto '),
            TextSpan(
              text: accion,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}