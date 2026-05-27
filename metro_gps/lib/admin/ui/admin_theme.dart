import 'package:flutter/material.dart';

/// Paleta y estilos compartidos del panel administrador.
/// Importa este archivo desde cualquier pantalla admin para acceder
/// a [AdminTheme], [AdminColors] y los widgets reutilizables.
abstract class AdminColors {
  static const navy = Color(0xFF0A1628);
  static const navyMid = Color(0xFF112240);
  static const navyLight = Color(0xFF1E3A5F);
  static const cyan = Color(0xFF00C8FF);
  static const cyanDim = Color(0xFF0096C7);
  static const surface = Color(0xFFF0F4F8);
  static const surfaceCard = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF0A1628);
  static const textSecondary = Color(0xFF5A7184);
  static const textMuted = Color(0xFF8FA3B1);
  static const success = Color(0xFF00B686);
  static const warning = Color(0xFFF5A623);
  static const danger = Color(0xFFE53935);
  static const divider = Color(0xFFE1E8ED);
}

abstract class AdminTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AdminColors.cyanDim,
          brightness: Brightness.light,
          primary: AdminColors.cyanDim,
          onPrimary: Colors.white,
          secondary: AdminColors.navyLight,
          onSecondary: Colors.white,
          surface: AdminColors.surface,
          onSurface: AdminColors.textPrimary,
          error: AdminColors.danger,
        ),
        scaffoldBackgroundColor: AdminColors.surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: AdminColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: Colors.white),
          actionsIconTheme: IconThemeData(color: Colors.white),
        ),
        // Cambia 'CardTheme' por 'CardThemeData'
        cardTheme: const CardThemeData(
          color: AdminColors.surfaceCard,
          elevation: 0.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
            side: BorderSide(color: AdminColors.divider, width: 1.0),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AdminColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AdminColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AdminColors.cyanDim, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AdminColors.danger, width: 1.5),
          ),
          labelStyle: const TextStyle(
            color: AdminColors.textSecondary,
            fontSize: 14,
          ),
          floatingLabelStyle: const TextStyle(
            color: AdminColors.cyanDim,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AdminColors.cyanDim,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AdminColors.cyanDim,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AdminColors.navy,
          foregroundColor: Colors.white,
          elevation: 4,
          extendedTextStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AdminColors.divider,
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AdminColors.navy,
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          elevation: 8,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}

// ─── Widgets reutilizables ───────────────────────────────────────────────────

/// Encabezado de sección dentro de una pantalla (p.ej. "Ruta", "Recursos").
class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader(this.title, {super.key, this.icon});
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AdminColors.cyanDim),
            const SizedBox(width: 8),
          ],
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AdminColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider(height: 1)),
        ],
      ),
    );
  }
}

/// Estado vacío estándar.
class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({super.key, required this.message, this.icon});
  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 56,
              color: AdminColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AdminColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado de error estándar con botón de reintento.
class AdminErrorState extends StatelessWidget {
  const AdminErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AdminColors.danger.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AdminColors.danger,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AdminColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge de estado de color.
class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Tarjeta de ítem de lista estándar con menú de acciones.
class AdminItemCard extends StatelessWidget {
  const AdminItemCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.badge,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? badge;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.divider),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: leading,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AdminColors.textPrimary,
          ),
        ),
        subtitle: subtitle != null
            ? Padding(
                padding: const EdgeInsets.only(top: 2),
                child: badge ??
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AdminColors.textSecondary,
                      ),
                    ),
              )
            : badge,
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AdminColors.textSecondary),
          onSelected: (v) {
            if (v == 'editar') onEdit();
            if (v == 'eliminar') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18, color: AdminColors.cyanDim),
                  SizedBox(width: 10),
                  Text('Editar', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete_outline,
                      size: 18, color: AdminColors.danger),
                  const SizedBox(width: 10),
                  Text(
                    'Eliminar',
                    style: TextStyle(
                        fontSize: 14, color: AdminColors.danger),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ícono de categoría con fondo circular.
class AdminIconAvatar extends StatelessWidget {
  const AdminIconAvatar({
    super.key,
    required this.icon,
    this.color = AdminColors.cyanDim,
    this.size = 40,
  });
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Diálogo de confirmación de eliminación.
Future<bool> showDeleteDialog(
  BuildContext context, {
  required String title,
  required String content,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AdminColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.delete_outline,
                color: AdminColors.danger, size: 20),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 17)),
        ],
      ),
      content: Text(
        content,
        style: const TextStyle(
            fontSize: 14, color: AdminColors.textSecondary, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AdminColors.danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  return result ?? false;
}