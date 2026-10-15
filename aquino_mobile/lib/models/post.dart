class Post {
  final int id;
  final int postId;
  final int userId;
  final String body;
  final int likes;
  final int dislikes;
  final String createdAt;
  final String updatedAt;
  final String title;
  final List<String> tags;
  final int views;

  Post({
    required this.id,
    required this.postId,
    required this.userId,
    required this.body,
    required this.likes,
    required this.dislikes,
    required this.createdAt,
    required this.updatedAt,
    this.title = '',
    this.tags = const <String>[],
    this.views = 0,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? 0,
      postId: json['postId'] ?? json['post_id'] ?? 0,
      userId: json['userId'] ?? json['user_id'] ?? 0,
      body: json['body'] ?? '',
      likes: (json['reactions'] != null && json['reactions']['likes'] != null)
          ? (json['reactions']['likes'] as num).toInt()
          : (json['likes'] as num?)?.toInt() ?? 0,
      dislikes:
          (json['reactions'] != null && json['reactions']['dislikes'] != null)
          ? (json['reactions']['dislikes'] as num).toInt()
          : (json['dislikes'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] ?? json['created_at'] ?? '',
      updatedAt: json['updatedAt'] ?? json['updated_at'] ?? '',
      title: json['title']?.toString() ?? '',
      tags: json['tags'] is List
          ? (json['tags'] as List).map((dynamic e) => e.toString()).toList()
          : const <String>[],
      views: (json['views'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'body': body,
      'reactions': {'likes': likes, 'dislikes': dislikes},
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'title': title,
      'tags': tags,
      'views': views,
    };
  }

  Post copyWith({int? likes, int? dislikes}) => Post(
    id: id,
    postId: postId,
    userId: userId,
    body: body,
    likes: likes ?? this.likes,
    dislikes: dislikes ?? this.dislikes,
    createdAt: createdAt,
    updatedAt: updatedAt,
    title: title,
    tags: tags,
    views: views,
  );
}
