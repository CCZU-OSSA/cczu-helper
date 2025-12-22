// Generated Dart models matching provided Supabase `public` schema subset

class BannerModel {
  final String id;
  final String title;
  final String? content;
  final String? color;
  final bool isActive;
  final String? startDate;
  final String? endDate;
  final String? createdAt;

  BannerModel({
    required this.id,
    required this.title,
    this.content,
    this.color,
    required this.isActive,
    this.startDate,
    this.endDate,
    this.createdAt,
  });

  factory BannerModel.fromMap(Map<String, dynamic> m) => BannerModel(
        id: m['id'] as String,
        title: m['title'] as String,
        content: m['content'] as String?,
        color: m['color'] as String?,
        isActive: m['is_active'] as bool? ?? false,
        startDate: m['start_date'] as String?,
        endDate: m['end_date'] as String?,
        createdAt: m['created_at'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'color': color,
        'is_active': isActive,
        'start_date': startDate,
        'end_date': endDate,
        'created_at': createdAt,
      };
}

class CategoryModel {
  final int id;
  final String name;

  CategoryModel({required this.id, required this.name});

  factory CategoryModel.fromMap(Map<String, dynamic> m) =>
      CategoryModel(id: m['id'] as int, name: m['name'] as String);

  Map<String, dynamic> toMap() => {'id': id, 'name': name};
}

class ProfileModel {
  final String id;
  final String username;
  final String createdAt;
  final String? avatarUrl;
  final String? realName;
  final String? studentId;
  final String? className;
  final String? collegeName;
  final int? grade;
  final bool? isPrivilege;

  ProfileModel({
    required this.id,
    required this.username,
    required this.createdAt,
    this.avatarUrl,
    this.realName,
    this.studentId,
    this.className,
    this.collegeName,
    this.grade,
    this.isPrivilege,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> m) => ProfileModel(
        id: m['id'] as String,
        username: m['username'] as String,
        createdAt: m['created_at'] as String,
        avatarUrl: m['avatar_url'] as String?,
        realName: m['real_name'] as String?,
        studentId: m['student_id'] as String?,
        className: m['class_name'] as String?,
        collegeName: m['college_name'] as String?,
        grade: (m['grade'] as num?)?.toInt(),
        isPrivilege: m['is_privilege'] as bool?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'created_at': createdAt,
        'avatar_url': avatarUrl,
        'real_name': realName,
        'student_id': studentId,
        'class_name': className,
        'college_name': collegeName,
        'grade': grade,
        'is_privilege': isPrivilege,
      };
}

enum PostStatus { available, sold, pending, archived }

String postStatusToString(PostStatus s) => s.name;

PostStatus? postStatusFromString(String? s) {
  if (s == null) return null;
  return PostStatus.values.firstWhere((e) => e.name == s, orElse: () => PostStatus.available);
}

class PostModel {
  final String id;
  final int categoryId;
  final String title;
  final String content;
  final String createdAt;
  final String? imageUrls;
  final bool? isAnonymous;
  final double? price;
  final PostStatus status;
  final String userId;
  // like summary
  final int likeCount;
  final bool isLiked;

  PostModel({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.imageUrls,
    this.isAnonymous,
    this.price,
    required this.status,
    required this.userId,
    this.likeCount = 0,
    this.isLiked = false,
  });

  factory PostModel.fromMap(Map<String, dynamic> m) => PostModel(
        id: m['id'] as String,
        categoryId: (m['category_id'] as num).toInt(),
        title: m['title'] as String,
        content: m['content'] as String,
        createdAt: m['created_at'] as String,
        imageUrls: m['image_urls'] as String?,
        isAnonymous: m['is_anonymous'] as bool?,
        price: (m['price'] as num?)?.toDouble(),
        status: postStatusFromString(m['status'] as String?) ?? PostStatus.available,
      userId: (m['user_id'] ?? '') as String,
      likeCount: (m['like_count'] as num?)?.toInt() ?? 0,
      isLiked: (m['is_liked'] as bool?) ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'category_id': categoryId,
        'title': title,
        'content': content,
        'created_at': createdAt,
        'image_urls': imageUrls,
        'is_anonymous': isAnonymous,
        'price': price,
        'status': postStatusToString(status),
        'user_id': userId,
      };
}

class CommentModel {
  final String id;
  final String? postId;
  final String content;
  final String? createdAt;
  final bool? isAnonymous;
  final String? parentCommentId;
  final String? userId;

  CommentModel({
    required this.id,
    required this.content,
    this.postId,
    this.createdAt,
    this.isAnonymous,
    this.parentCommentId,
    this.userId,
  });

  factory CommentModel.fromMap(Map<String, dynamic> m) => CommentModel(
        id: m['id'] as String,
        content: m['content'] as String,
        postId: m['post_id'] as String?,
        createdAt: m['created_at'] as String?,
        isAnonymous: m['is_anonymous'] as bool?,
        parentCommentId: m['parent_comment_id'] as String?,
        userId: m['user_id'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'post_id': postId,
        'content': content,
        'created_at': createdAt,
        'is_anonymous': isAnonymous,
        'parent_comment_id': parentCommentId,
        'user_id': userId,
      };
}

class LikeModel {
  final String id;
  final String userId;
  final String? postId;
  final String? commentId;
  final String? createdAt;

  LikeModel({
    required this.id,
    required this.userId,
    this.postId,
    this.commentId,
    this.createdAt,
  });

  factory LikeModel.fromMap(Map<String, dynamic> m) => LikeModel(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        postId: m['post_id'] as String?,
        commentId: m['comment_id'] as String?,
        createdAt: m['created_at'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'post_id': postId,
        'comment_id': commentId,
        'created_at': createdAt,
      };
}
