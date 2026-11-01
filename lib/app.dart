import 'package:flutter/material.dart';

import 'app_state.dart';
import 'open_url.dart';
import 'screens/forums_screen.dart';

class ForumsApp extends StatelessWidget {
  const ForumsApp({super.key, required this.state, required this.openHome});

  final AppState state;

  /// Opens the SimpleAPI home page in this tab (the back arrow on the Forums screen).
  final UrlOpener openHome;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forums API sample | SimpleAPI',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF0066CC), useMaterial3: true),
      // The app opens straight on content.
      home: ForumsScreen(state: state, openHome: openHome),
    );
  }
}
