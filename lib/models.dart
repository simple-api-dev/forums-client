/// Plain data classes for the Forums API responses.
///
/// Parsing is deliberately forgiving (missing fields fall back to defaults) so
/// a small change in the API does not crash the sample. Note that the API only
/// sends `author_id`, never an author name.
library;

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
String _str(Object? v) => v == null ? '' : '$v';

class Forum {
  const Forum({
    required this.id,
    required this.title,
    required this.slug,
    required this.body,
    required this.status,
    required this.authorId,
  });

  factory Forum.fromJson(Map<String, dynamic> j) => Forum(
        id: _int(j['id']),
        title: _str(j['title']),
        slug: _str(j['slug']),
        body: _str(j['body']),
        status: _str(j['status']),
        authorId: _str(j['author_id']),
      );

  final int id;
  final String title;

  /// Used in the URLs that read a forum or its topics.
  final String slug;
  final String body;
  final String status;
  final String authorId;
}

class Topic {
  const Topic({
    required this.id,
    required this.forumId,
    required this.title,
    required this.slug,
    required this.body,
    required this.type,
    required this.status,
    required this.authorId,
    required this.score,
    required this.updatedAt,
    this.comments = const [],
  });

  factory Topic.fromJson(Map<String, dynamic> j) => Topic(
        id: _int(j['id']),
        forumId: _int(j['forum_id']),
        title: _str(j['title']),
        slug: _str(j['slug']),
        body: _str(j['body']),
        type: _str(j['type']),
        status: _str(j['status']),
        authorId: _str(j['author_id']),
        score: _int(j['score']),
        updatedAt: _str(j['updated_at']),
        comments: Comment.listFrom(j['comments']),
      );

  final int id;
  final int forumId;
  final String title;

  /// Used in the URL that reads one topic (GET /api/topics/{slug}).
  final String slug;
  final String body;
  final String type;
  final String status;
  final String authorId;
  final int score;
  final String updatedAt;

  /// Top-level comments, each with its replies nested inside. Only filled in
  /// by GET /api/topics/{slug}.
  final List<Comment> comments;
}

class Comment {
  const Comment({
    required this.id,
    required this.body,
    required this.status,
    required this.authorId,
    required this.score,
    required this.updatedAt,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
        id: _int(j['id']),
        body: _str(j['body']),
        status: _str(j['status']),
        authorId: _str(j['author_id']),
        score: _int(j['score']),
        updatedAt: _str(j['updated_at']),
        // A comment's replies come back under the key `comments`.
        replies: listFrom(j['comments']),
      );

  static List<Comment> listFrom(Object? raw) =>
      raw is List ? [for (final c in raw) Comment.fromJson(c as Map<String, dynamic>)] : const [];

  final int id;
  final String body;
  final String status;
  final String authorId;
  final int score;
  final String updatedAt;
  final List<Comment> replies;
}

/// Result of register / login. [token] is null when the API answered 202
/// (confirmation code emailed) and [message] says so.
class AuthResult {
  const AuthResult({this.token, this.id = '', this.name = '', this.message = ''});

  final String? token;
  final String id;
  final String name;
  final String message;
}

/// Answer of a vote call: the content's new total score. The API sends it as
/// a string (`{"points":"1"}`) or sometimes a number (`{"points":0}`).
class VoteResult {
  const VoteResult(this.points);

  factory VoteResult.fromJson(Map<String, dynamic> j) => VoteResult(_int(j['points']));

  final int points;
}
