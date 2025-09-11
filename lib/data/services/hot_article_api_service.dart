// lib/services/hot_article_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/hot_article_dto.dart';

class HotArticleApiService {
  static const _base =
      'https://api.vtcnews.vn/api/News/ArticleHotPartialHome?categoryId=';

  final http.Client _client;
  HotArticleApiService({http.Client? client})
    : _client = client ?? http.Client();

  Future<List<HotArticleDto>> fetchHotArticles(int categoryId) async {
    final uri = Uri.parse('$_base$categoryId');
    // print('GET $uri');
    final res = await _client.get(
      uri,
      headers: {'Accept': 'application/json', 'User-Agent': 'VTCNewsApp/1.0'},
    );

    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) => HotArticleDto.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw http.ClientException('HotArticle api error ${res.statusCode}', uri);
  }

  void dispose() => _client.close();
}
