import 'package:flutter/material.dart';

import 'admin/clinica_api.dart';
import 'auth/ui/auth_tabs_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ClinicaApi.sharedClient.loadSavedSession();
  runApp(
    const MaterialApp(
      title: 'Metro GPS',
      home: AuthTabsScreen(),
    ),
  );
}
