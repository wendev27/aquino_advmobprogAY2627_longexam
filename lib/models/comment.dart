class Comment {
  final int id;
  final int postId;
  final String body;
  final int likes;
  final int userId;
  final String username;
  final String fullName;

  const Comment({
    required this.id,
    required this.postId,
    required this.body,
    required this.likes,
    required this.userId,
    required this.username,
    required this.fullName,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final dynamic rawUser = json['user'];
    final Map<String, dynamic> user = rawUser is Map<String, dynamic>
        ? rawUser
        : const <String, dynamic>{};
    return Comment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      postId: (json['postId'] as num?)?.toInt() ?? 0,
      body: json['body']?.toString() ?? '',
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      userId:
          (user['id'] as num?)?.toInt() ??
          (json['userId'] as num?)?.toInt() ??
          0,
      username: user['username']?.toString() ?? '',
      fullName: user['fullName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'postId': postId,
    'body': body,
    'likes': likes,
    'user': <String, dynamic>{
      'id': userId,
      'username': username,
      'fullName': fullName,
    },
  };

  Comment copyWith({int? likes}) => Comment(
    id: id,
    postId: postId,
    body: body,
    likes: likes ?? this.likes,
    userId: userId,
    username: username,
    fullName: fullName,
  );
}
