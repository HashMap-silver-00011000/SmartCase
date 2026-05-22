import 'package:flutter/material.dart';

import '../admin/clinica_api.dart';
import 'ui/auth_tabs_screen.dart';

/// Cierra sesión (token, cookie, memoria) y vuelve al login.
Future<void> cerrarSesion(BuildContext context) async {
  await ClinicaApi.sharedClient.clearSession();
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const AuthTabsScreen()),
    (_) => false,
  );
}

Future<void> confirmarCerrarSesion(BuildContext context) async {
  final salir = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cerrar sesión'),
      content: const Text('¿Salir de tu cuenta en este dispositivo?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Cerrar sesión'),
        ),
      ],
    ),
  );
  if (salir == true && context.mounted) {
    await cerrarSesion(context);
  }
}

/// Botón de AppBar para cerrar sesión.
class LogoutAppBarButton extends StatelessWidget {
  const LogoutAppBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => confirmarCerrarSesion(context),
      icon: const Icon(Icons.logout),
      tooltip: 'Cerrar sesión',
    );
  }
}
