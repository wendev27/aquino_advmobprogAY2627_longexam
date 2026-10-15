import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/comment.dart';

class CommentService {
  Future<List<Comment>> getCommentsByPost(
    int postId, {
    int limit = kCommentsPageLimit,
    int skip = 0,
  }) async {
    final Uri uri = Uri.parse(
      '$kDummyJsonBaseUrl/comments/post/$postId?limit=$limit&skip=$skip',
    );
    final http.Response response = await http
        .get(
          uri,
          headers: const <String, String>{'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to load comments: ${response.statusCode}');
    }
    final Map<String, dynamic> data = jsonDecode(response.body);
    final List commentsJson = data['comments'] ?? <dynamic>[];
    return commentsJson.map((dynamic c) => Comment.fromJson(c)).toList();
  }

  Future<Comment> addComment({
    required int postId,
    required int userId,
    required String body,
  }) async {
    final Uri uri = Uri.parse('$kDummyJsonBaseUrl/comments/add');
    final http.Response response = await http
        .post(
          uri,
          headers: const <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(<String, dynamic>{
            'body': body,
            'postId': postId,
            'userId': userId,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add comment: ${response.statusCode}');
    }
    final Map<String, dynamic> data = jsonDecode(response.body);
    return Comment.fromJson(data);
  }
}
