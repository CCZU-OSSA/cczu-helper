class TeahousePostModel {
  final int id;
  final String title;
  final String author;
  final String content;
  final String createdAt;

  TeahousePostModel({
    required this.id,
    required this.title,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  factory TeahousePostModel.fromMap(Map<String, dynamic> m) => TeahousePostModel(
        id: m['id'] as int,
        title: m['title'] as String,
        author: (m['author'] ?? '') as String,
        content: (m['content'] ?? '') as String,
        createdAt: (m['created_at'] ?? '') as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'author': author,
        'content': content,
        'created_at': createdAt,
      };
}

class CommentModel {
  final int id;
  final int postId;
  final String author;
  final String content;
  final String createdAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> m) => CommentModel(
        id: m['id'] as int,
        postId: m['post_id'] as int,
        author: (m['author'] ?? '') as String,
        content: (m['content'] ?? '') as String,
        createdAt: (m['created_at'] ?? '') as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'post_id': postId,
        'author': author,
        'content': content,
        'created_at': createdAt,
      };
}
