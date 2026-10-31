import 'package:flutter/material.dart';

import '../app_state.dart';
import '../forums_api.dart';
import 'auth_screen.dart';

/// Turns any error into a sentence the user can read. The API's own message
/// (when it sent one) is appended because it names the exact problem.
String describeError(Object e) {
  if (e is! ApiException) return 'Something went wrong: $e';
  final detail = e.message;
  switch (e.statusCode) {
    case 0:
      return detail;
    case 401:
      return 'The API did not accept the key or your login (401). '
          'Check the key in Settings, or log in again. $detail';
    case 403:
      return 'You are not allowed to do that (403). $detail';
    case 404:
      return 'Not found (404). $detail';
    case 409:
      return 'That conflicts with something that already exists, or this key uses an external auth service (409). $detail';
    case 422:
      return 'The API rejected the input (422). $detail';
    case 429:
      return 'Too many requests (429). Wait a few seconds and try again. $detail';
    default:
      return detail;
  }
}

void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
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
      Center(child: Text(state.userName ?? 'you')),
      TextButton(
        onPressed: () async {
          await state.logout();
          if (context.mounted) showSnack(context, 'Logged out.');
        },
        child: const Text('Log out'),
      ),
    ] else
      TextButton(onPressed: () => ensureLoggedIn(context, state), child: const Text('Log in')),
    TextButton(onPressed: onSettings, child: const Text('Settings')),
    const SizedBox(width: 8),
  ];
}
