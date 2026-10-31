import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'forums_api.dart';
import 'key_store.dart';

/// The app's only shared state: which key is in use and who is logged in.
/// Screens listen to it with [ListenableBuilder].
///
/// The key comes from the build ([buildKey]) unless the visitor saved their
/// own in this browser's localStorage, which then takes over.
class AppState extends ChangeNotifier {
  AppState({required this.store, this.buildKey = configuredKey, this._client}) {
    final own = store.read();
    _useKey(
      own != null && own.isNotEmpty ? own : buildKey,
      own: own != null && own.isNotEmpty,
    );
  }

  final KeyStore store;
  final String buildKey;
  final http.Client? _client;

  ForumsApi? _api;
  bool _usingOwnKey = false;
  String? userName;

  /// The logged-in user's id. The API reports authors as `author_id`, so this
  /// is how the app knows which content is "yours".
  String? userId;

  /// Bumped whenever the key changes so screens can reload their data.
  int keyVersion = 0;

  bool get hasKey => _api != null;
  bool get hasBuildKey => buildKey.isNotEmpty;
  bool get usingOwnKey => _usingOwnKey;
  bool get loggedIn => _api?.token != null;

  /// True when [authorId] (from the API) is the logged-in user.
  bool isMine(String authorId) => loggedIn && userId != null && userId == authorId;

  /// The client for the current key. Only call when [hasKey] is true.
  ForumsApi get api => _api!;

  void _useKey(String key, {required bool own}) {
    _api = key.isEmpty ? null : ForumsApi(apiKey: key, client: _client);
    _usingOwnKey = own;
    userName = null;
    userId = null;
    keyVersion++;
  }

  /// Checks [key] with one real call (GET /api/forums), then remembers it in
  /// localStorage and uses it instead of the build key.
  /// Throws [ApiException] if the API rejects it.
  Future<void> useOwnKey(String key) async {
    await ForumsApi(apiKey: key, client: _client).listForums();
    store.write(key);
    _useKey(key, own: true);
    notifyListeners();
  }

  /// Forgets the saved key and goes back to the build key (if there is one).
  void useBuildKey() {
    store.clear();
    _useKey(buildKey, own: false);
    notifyListeners();
  }

  void loggedInAs({required String name, required String id}) {
    userName = name;
    userId = id;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } on ApiException {
      api.token = null; // token already invalid: just drop it
    }
    userName = null;
    userId = null;
    notifyListeners();
  }
}
