import 'package:metro_gps/app/providers.dart';
import 'package:metro_gps/core/constants/app_colors.dart';
import 'package:metro_gps/features/auth/domain/models/user_model.dart';
import 'package:metro_gps/features/telemetry/presentation/screens/driver_telemetry_screen.dart';
import 'package:metro_gps/features/telemetry/presentation/screens/routes_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerNombreController = TextEditingController();
  final _registerApellidosController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  String _selectedRoleRegister = 'pasajero';
  bool _loading = false;
  String? _error;

  Future<void> _navigateByRole(UserModel user) async {
    if (!mounted) return;
    final role = user.rol.toLowerCase();
    if (role == 'conductor') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DriverTelemetryScreen(user: user)),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoutesMapScreen(user: user)),
    );
  }

  Future<void> _login() async {
    await HapticFeedback.selectionClick();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      final user = await auth.login(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );
      await _navigateByRole(user);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    await HapticFeedback.selectionClick();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      final user = await auth.register(
        nombre: _registerNombreController.text.trim(),
        apellidos: _registerApellidosController.text.trim(),
        rol: _selectedRoleRegister,
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text,
      );
      await _navigateByRole(user);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Autenticacion'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Login'),
              Tab(text: 'Register'),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: TabBarView(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _loginEmailController,
                            decoration: const InputDecoration(labelText: 'Email'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _loginPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Password'),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _loading ? null : _login,
                              child: _loading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Entrar'),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _registerNombreController,
                            decoration: const InputDecoration(labelText: 'Nombre'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _registerApellidosController,
                            decoration: const InputDecoration(labelText: 'Apellidos'),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedRoleRegister,
                            decoration: const InputDecoration(labelText: 'Rol'),
                            items: const [
                              DropdownMenuItem(
                                value: 'conductor',
                                child: Text('Conductor'),
                              ),
                              DropdownMenuItem(
                                value: 'pasajero',
                                child: Text('Pasajero'),
                              ),
                              DropdownMenuItem(value: 'admin', child: Text('Admin')),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _selectedRoleRegister = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _registerEmailController,
                            decoration: const InputDecoration(labelText: 'Email'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _registerPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Password'),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _loading ? null : _register,
                              child: _loading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Crear cuenta'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: _error == null
            ? null
            : Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNombreController.dispose();
    _registerApellidosController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }
}
