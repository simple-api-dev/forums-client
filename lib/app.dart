import 'package:flutter/material.dart';

import 'app_state.dart';
import 'open_url.dart';
import 'screens/forums_screen.dart';

class ForumsApp extends StatelessWidget {
  const ForumsApp({super.key, required this.state, required this.openUrl});

  final AppState state;
  final UrlOpener openUrl;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SimpleAPI Forums sample',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF0066CC), useMaterial3: true),
      // The app opens straight on content. A new keyVersion rebuilds the list
      // so it reloads when the key changes.
      home: ListenableBuilder(
        listenable: state,
        builder: (context, _) => ForumsScreen(
          key: ValueKey(state.keyVersion),
          state: state,
          openUrl: openUrl,
        ),
      ),
    );
  }
}
