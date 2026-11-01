import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config.dart';
import '../models.dart';
import '../open_url.dart';
import 'forum_screen.dart';
import 'ui.dart';

/// Home: the forums of this key. A new key has none, so the empty state
/// invites you to create the first one (this needs a logged-in user).
class ForumsScreen extends StatefulWidget {
  const ForumsScreen({super.key, required this.state, required this.openHome});

  final AppState state;
  /// Opens the SimpleAPI home page in this tab.
  final UrlOpener openHome;

  @override
  State<ForumsScreen> createState() => _ForumsScreenState();
}

class _ForumsScreenState extends State<ForumsScreen> {
  Future<List<Forum>>? _forums;

  AppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    // GET /api/forums
    _forums = state.api.listForums();
  }

  Future<void> _createForum() async {
    if (!await ensureLoggedIn(context, state)) return;
    if (!mounted) return;
    final result = await showDialog<({String title, String body})>(
      context: context,
      builder: (_) => const _NewForumDialog(),
    );
    if (result == null) return;
    try {
      // POST /api/forums
      await state.api.createForum(title: result.title, body: result.body);
      if (!mounted) return;
      setState(_load);
    } catch (e) {
      if (mounted) showError(context, state, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back to SimpleAPI',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => widget.openHome(homeUrl),
          ),
          title: const Text('SimpleAPI Forums'),
          actions: accountActions(context, state),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createForum,
          icon: const Icon(Icons.add),
          label: const Text('New forum'),
        ),
        body: Centered(child: _body()),
      ),
    );
  }

  Widget _body() {
    return FutureBuilder<List<Forum>>(
      future: _forums,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return ErrorView(error: snap.error!, onRetry: () => setState(_load));
        }
        final forums = snap.data!;
        if (forums.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('No forums yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text(
                  'This key has no forums. Log in (or register) and create the first one.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: _createForum, child: const Text('Create the first forum')),
              ]),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => setState(_load),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              for (final f in forums)
                ListTile(
                  title: Text(f.title),
                  subtitle: f.body.isEmpty ? null : Text(f.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push<void>(MaterialPageRoute(
                      builder: (_) => ForumScreen(state: state, forum: f),
                    ));
                    if (mounted) setState(_load); // the forum may have been deleted
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NewForumDialog extends StatefulWidget {
  const _NewForumDialog();

  @override
  State<_NewForumDialog> createState() => _NewForumDialogState();
}

class _NewForumDialogState extends State<_NewForumDialog> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New forum'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _title, autofocus: true, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _body, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder())),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final title = _title.text.trim();
            if (title.isEmpty) return;
            Navigator.pop(context, (title: title, body: _body.text.trim()));
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
