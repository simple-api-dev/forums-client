import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../open_url.dart';
import 'settings_screen.dart';
import 'topic_screen.dart';
import 'ui.dart';

/// The topics of one forum, with a form to start a new one.
class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key, required this.state, required this.forum, required this.openUrl});

  final AppState state;
  final Forum forum;
  final UrlOpener openUrl;

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  Future<List<Topic>>? _topics;

  AppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    // GET /api/forums/{slug}/topics
    _topics = state.api.listTopics(widget.forum.slug);
  }

  Future<void> _newTopic() async {
    if (!await ensureLoggedIn(context, state)) return;
    if (!mounted) return;
    final result = await showDialog<({String title, String body})>(
      context: context,
      builder: (_) => const _NewTopicDialog(),
    );
    if (result == null) return;
    try {
      // POST /api/forums/{id}/topics
      await state.api.createTopic(widget.forum.id, title: result.title, body: result.body);
      if (mounted) setState(_load);
    } catch (e) {
      if (mounted) showSnack(context, describeError(e));
    }
  }

  Future<void> _deleteForum() async {
    if (!await confirm(context, 'Delete this forum?')) return;
    try {
      // DELETE /api/forums/{id}
      await state.api.deleteForum(widget.forum.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showSnack(context, describeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(widget.forum.title),
          actions: [
            if (state.isMine(widget.forum.authorId))
              IconButton(tooltip: 'Delete forum', onPressed: _deleteForum, icon: const Icon(Icons.delete_outline)),
            ...accountActions(
              context,
              state,
              onSettings: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => SettingsScreen(state: state, openUrl: widget.openUrl),
              )),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _newTopic,
          icon: const Icon(Icons.add),
          label: const Text('New topic'),
        ),
        body: Centered(
          child: FutureBuilder<List<Topic>>(
            future: _topics,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) return ErrorView(error: snap.error!, onRetry: () => setState(_load));
              final topics = snap.data!;
              if (topics.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('No topics yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _newTopic, child: const Text('Start the first topic')),
                    ]),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => setState(_load),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 88),
                  children: [
                    if (widget.forum.body.isNotEmpty)
                      Padding(padding: const EdgeInsets.all(16), child: Text(widget.forum.body)),
                    for (final t in topics)
                      ListTile(
                        title: Text(t.title),
                        subtitle: t.body.isEmpty ? null : Text(t.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Text('${t.score} points'),
                        onTap: () async {
                          await Navigator.of(context).push<void>(MaterialPageRoute(
                            builder: (_) => TopicScreen(state: state, topicSlug: t.slug, openUrl: widget.openUrl),
                          ));
                          if (mounted) setState(_load); // score or text may have changed
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NewTopicDialog extends StatefulWidget {
  const _NewTopicDialog();

  @override
  State<_NewTopicDialog> createState() => _NewTopicDialogState();
}

class _NewTopicDialogState extends State<_NewTopicDialog> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String? _titleError;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New topic'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _title, autofocus: true, decoration: InputDecoration(labelText: 'Title', border: const OutlineInputBorder(), errorText: _titleError)),
        const SizedBox(height: 12),
        TextField(controller: _body, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'Text (optional)', border: OutlineInputBorder())),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final title = _title.text.trim();
            final text = _body.text.trim();
            setState(() => _titleError = title.isEmpty ? 'Required' : null);
            if (_titleError != null) return;
            Navigator.pop(context, (title: title, body: text));
          },
          child: const Text('Post'),
        ),
      ],
    );
  }
}
