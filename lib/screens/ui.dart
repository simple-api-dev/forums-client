import 'package:flutter/material.dart';

import '../app_state.dart';
import '../forums_api.dart';
import 'auth_screen.dart';

/// Shown under the register form while the app uses the shared demo key.
const demoNotice = 'Demo accounts are shared and public. Do not use a real password or any private details.';

/// Shown instead of the API's message when the shared demo key has no room for another user.
const demoFullMessage = 'The demo is full: its key cannot take more accounts. Use your own free key under Settings to keep going.';

/// Turns any error into a sentence the user can read. For a 401 on login, 403,
/// 409 and 422 the API's own message is the best explanation, so it is shown as is.
String describeError(Object e) {
  if (e is! ApiException) return 'Something went wrong. Please try again.';
  switch (e.statusCode) {
    case 401:
      if (e.keyRejected) return 'The API key was not accepted. Check it under Settings.';
      if (e.sessionEnded) return 'Your session has ended. Please log in again.';
      return e.message;
    case 404:
      return 'Not found. It may already have been deleted.';
    case 429:
      return 'Too many requests. Wait a few seconds and try again.';
    default:
      return e.message;
  }
}

void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Shows [e] in a snackbar. When the login has just ended, the login screen opens too.
Future<void> showError(BuildContext context, AppState state, Object e) async {
  showSnack(context, describeError(e));
  if (e is ApiException && e.sessionEnded && context.mounted) await ensureLoggedIn(context, state);
}

/// Makes sure someone is logged in, opening the log in screen if not.
/// Returns true when the action may go ahead.
Future<bool> ensureLoggedIn(BuildContext context, AppState state) async {
  if (state.loggedIn) return true;
  final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => AuthScreen(state: state)));
  return ok == true;
}

/// Asks for one piece of text. Returns null when cancelled.
Future<String?> askText(
  BuildContext context, {
  required String title,
  String initial = '',
  String label = 'Text',
  String action = 'Save',
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 2,
        maxLines: 6,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(action)),
      ],
    ),
  );
}

Future<bool> confirm(BuildContext context, String question) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(question),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ),
  );
  return ok == true;
}

/// Shown when a request fails, with a retry button.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(describeError(error), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ]),
      ),
    );
  }
}

/// Centers page content in a readable column on wide screens.
class Centered extends StatelessWidget {
  const Centered({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: child));
}

/// Log in / log out / settings buttons shared by every screen's app bar.
List<Widget> accountActions(BuildContext context, AppState state, {required VoidCallback onSettings}) {
  return [
    if (state.loggedIn) ...[
      Center(child: Text('Hi, ${state.userName ?? 'you'}')),
      TextButton(onPressed: state.logout, child: const Text('Log out')),
    ] else
      TextButton(onPressed: () => ensureLoggedIn(context, state), child: const Text('Log in / Register')),
    TextButton(onPressed: onSettings, child: const Text('Settings')),
    const SizedBox(width: 8),
  ];
}
