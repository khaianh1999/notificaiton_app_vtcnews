import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart'; // kDebugMode
import 'package:http/http.dart' as http;
import '../models/comment.dart';

class CommentApiService {
  static const _baseUrl = 'https://beta.vtcnews.vn';
  static const bool useMock = kDebugMode; // bật mock ở debug, tắt ở release

  final http.Client _client = http.Client();

  Future<List<Comment>> fetchComments(int articleId, int pageIndex) async {
    final res = await _client.get(
      Uri.parse(
        '$_baseUrl/Comment/GetNewsJsonComment?idArticle=259334&pageindex=$pageIndex',
      ),
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List items = json['Items'];
      return items.map((e) => Comment.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load comments');
    }
  }

  Future<void> postComment({
    required int articleId,
    required String content,
    int parentId = 0,
  }) async {
    await _client.post(
      Uri.parse('$_baseUrl/Comment/Post'),
      body: jsonEncode({
        "ArticleId": articleId,
        "Content": content,
        "ParentId": parentId,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<void> sendReaction({
    required int commentId,
    required int reactionValue,
    required String username,
  }) async {
    final res = await _client.post(
      Uri.parse("$_baseUrl/ChangeReaction"),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        "username": username,
        "idComment": commentId.toString(),
        "type": reactionValue.toString(),
      },
    );
    // log res success or failure
    // print("Reaction response: ${res.statusCode} - ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("Gửi cảm xúc thất bại");
    }
  }

  Map<int, List<Comment>> _groupCommentsByParent(List<Comment> comments) {
    final Map<int, List<Comment>> map = {};
    for (final comment in comments) {
      map.putIfAbsent(comment.parentId, () => []).add(comment);
    }
    return map;
  }

  void dispose() => _client.close();
}
