import 'package:flutter/material.dart';

import 'app.dart';
import 'app_state.dart';
import 'key_store_web.dart';
import 'open_url_web.dart';

void main() {
  runApp(
    ForumsApp(
      state: AppState(store: LocalStorageKeyStore()),
      openUrl: openInNewTab,
    ),
  );
}
