import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'forums_api.dart';

/// The app's only shared state: the API client (it uses the key built into the app) and who is logged in.
/// Screens listen to it with [ListenableBuilder].
class AppState extends ChangeNotifier {
  AppState({this.buildKey = configuredKey, http.Client? client}) {
    api = ForumsApi(apiKey: buildKey, client: client, onSessionExpired: _sessionExpired);
  }

  /// The key compiled in with `--dart-define=SIMPLEAPI_KEY=...` (see config.dart).
  final String buildKey;

  late final ForumsApi api;
  String? userName;

  /// The logged-in user's id. The API reports owners as `user_id`, so this
  /// is how the app knows which content is "yours".
  int? userId;

  bool get loggedIn => api.token != null;

  /// True when [ownerId] (a `user_id` from the API) is the logged-in user.
  bool isMine(int ownerId) => loggedIn && userId != null && userId == ownerId;

  /// The API said the login token no longer works: forget the user so the
  /// app bar offers Log in again.
  void _sessionExpired() {
    userName = null;
    userId = null;
    notifyListeners();
  }

  void loggedInAs({required String name, required int id}) {
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
