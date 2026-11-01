import 'package:flutter/material.dart';

import '../app_state.dart';
import '../forums_api.dart';
import '../models.dart';
import 'ui.dart';

/// One topic with its comment tree. Replies are indented under their parent.
/// Vote, edit, delete and report buttons call the API and reload the topic.
class TopicScreen extends StatefulWidget {
  const TopicScreen({super.key, required this.state, required this.topicSlug});

  final AppState state;
  final String topicSlug;

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  Future<Topic>? _topic;
  final _newComment = TextEditingController();

  AppState get state => widget.state;
  ForumsApi get api => state.api;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _newComment.dispose();
    super.dispose();
  }

  void _load() {
    // GET /api/topics/{slug}  (the comment tree comes with it)
    _topic = api.getTopic(widget.topicSlug);
  }

  /// Runs a write call: needs a login, reloads the topic, shows API errors.
  Future<void> _act(Future<void> Function() call) async {
    if (!await ensureLoggedIn(context, state)) return;
    try {
      await call();
      if (mounted) setState(_load);
    } catch (e) {
      if (mounted) showError(context, state, e);
    }
  }

  Future<void> _vote(String type, int id, bool up) => _act(() async {
        // POST /api/votes/up|down/{type}/{id}
        final r = await api.vote(type, id, up: up);
        if (mounted) showSnack(context, 'Vote counted. The score is now ${r.points}.');
      });

  Future<void> _unvote(String type, int id) => _act(() async {
        // DELETE /api/votes/{type}/{id}
        await api.removeVote(type, id);
        if (mounted) showSnack(context, 'Vote taken back.');
      });

  Future<void> _report(String type, int id) async {
    if (!await ensureLoggedIn(context, state)) return;
    if (!mounted) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Report as...'),
        children: [for (final r in reportTypes) SimpleDialogOption(onPressed: () => Navigator.pop(context, r), child: Text(r))],
      ),
    );
    if (reason == null) return;
    await _act(() async {
      // POST /api/reports/type/{type}/{id}
      await api.report(type, id, reason: reason);
      if (mounted) showSnack(context, 'Reported. Thank you.');
    });
  }

  Future<void> _editTopic(Topic t) async {
    final text = await askText(context, title: 'Edit topic', initial: t.body, label: 'Text');
    if (text == null) return;
    // PUT /api/topics/{id}
    await _act(() => api.updateTopic(t.id, body: text));
  }

  Future<void> _deleteTopic(Topic t) async {
    if (!await confirm(context, 'Delete this topic?')) return;
    try {
      // DELETE /api/topics/{id}
      await api.deleteTopic(t.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showError(context, state, e);
    }
  }

  Future<void> _comment(Topic t) async {
    final text = _newComment.text.trim();
    if (text.isEmpty) return;
    // POST /api/comments/type/topic/{id}
    await _act(() => api.addComment(t.id, text));
    _newComment.clear();
  }

  Future<void> _reply(Comment c) async {
    if (!await ensureLoggedIn(context, state)) return;
    if (!mounted) return;
    final text = await askText(context, title: 'Reply', label: 'Your reply', action: 'Reply');
    if (text == null || text.isEmpty) return;
    // POST /api/comments/type/comment/{id}
    await _act(() => api.addReply(c.id, text));
  }

  Future<void> _editComment(Comment c) async {
    final text = await askText(context, title: 'Edit comment', initial: c.body, label: 'Text');
    if (text == null) return;
    // PUT /api/comments/{id}
    await _act(() => api.updateComment(c.id, body: text));
  }

  Future<void> _deleteComment(Comment c) async {
    if (!await confirm(context, 'Delete this comment (and its replies)?')) return;
    // DELETE /api/comments/{id}
    await _act(() => api.deleteComment(c.id));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Topic'),
          actions: accountActions(context, state),
        ),
        body: Centered(
          child: FutureBuilder<Topic>(
            future: _topic,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) return ErrorView(error: snap.error!, onRetry: () => setState(_load));
              final t = snap.data!;
              return ListView(padding: const EdgeInsets.all(16), children: [
                Text(t.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text('by user ${t.userId}', style: Theme.of(context).textTheme.bodySmall),
                if (t.body.isNotEmpty) ...[const SizedBox(height: 12), Text(t.body)],
                _Actions(
                  score: t.score,
                  reported: t.status != 'Active',
                  mine: state.isMine(t.userId),
                  onVote: (up) => _vote('topic', t.id, up),
                  onUnvote: () => _unvote('topic', t.id),
                  onEdit: () => _editTopic(t),
                  onDelete: () => _deleteTopic(t),
                  onReport: () => _report('topic', t.id),
                ),
                const Divider(),
                Text('Comments', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (t.comments.isEmpty) const Text('No comments yet.'),
                for (final c in t.comments) _CommentTile(comment: c, depth: 0, view: this),
                const SizedBox(height: 16),
                TextField(
                  controller: _newComment,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Add a comment', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(onPressed: () => _comment(t), child: const Text('Comment')),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

/// Score with up/down buttons, plus edit/delete (own content only) and report.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.score,
    required this.reported,
    required this.mine,
    required this.onVote,
    required this.onUnvote,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
  });

  final int score;

  /// The API hides the text of reported content ("pending moderation").
  final bool reported;
  final bool mine;
  final void Function(bool up) onVote;
  final VoidCallback onUnvote;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
      IconButton(tooltip: 'Upvote', onPressed: () => onVote(true), icon: const Icon(Icons.arrow_upward)),
      Text('$score'),
      IconButton(tooltip: 'Downvote', onPressed: () => onVote(false), icon: const Icon(Icons.arrow_downward)),
      IconButton(tooltip: 'Take back my vote', onPressed: onUnvote, icon: const Icon(Icons.undo)),
      if (mine) ...[
        TextButton(onPressed: onEdit, child: const Text('Edit')),
        TextButton(onPressed: onDelete, child: const Text('Delete')),
      ],
      TextButton(onPressed: onReport, child: const Text('Report')),
      if (reported) const Chip(label: Text('Reported: pending moderation')),
    ]);
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.depth, required this.view});

  final Comment comment;
  final int depth;
  final _TopicScreenState view;

  @override
  Widget build(BuildContext context) {
    final c = comment;
    return Padding(
      // Indent per level but stop growing so deep threads stay readable.
      padding: EdgeInsets.only(left: (depth.clamp(0, 6)) * 16.0, top: 4, bottom: 4),
      child: Container(
        decoration: BoxDecoration(border: Border(left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 2))),
        padding: const EdgeInsets.only(left: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('user ${c.userId}', style: Theme.of(context).textTheme.bodySmall),
          Text(c.body),
          _Actions(
            score: c.score,
            reported: c.status != 'Active',
            mine: view.state.isMine(c.userId),
            onVote: (up) => view._vote('comment', c.id, up),
            onUnvote: () => view._unvote('comment', c.id),
            onEdit: () => view._editComment(c),
            onDelete: () => view._deleteComment(c),
            onReport: () => view._report('comment', c.id),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: () => view._reply(c), child: const Text('Reply')),
          ),
          for (final r in c.replies) _CommentTile(comment: r, depth: depth + 1, view: view),
        ]),
      ),
    );
  }
}
