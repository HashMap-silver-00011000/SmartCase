import 'package:flutter/material.dart';

import 'auth/ui/auth_tabs_screen.dart';

void main() {
  runApp(
    const MaterialApp(
      title: 'Metro GPS',
      home: AuthTabsScreen(),
    ),
  );
}
