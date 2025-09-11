// lib/repositories/hot_article_repository.dart
import '../models/hot_article.dart';
import '../services/hot_article_api_service.dart';

class HotArticleRepository {
  final HotArticleApiService _api;
  HotArticleRepository({HotArticleApiService? apiService})
    : _api = apiService ?? HotArticleApiService();

  Future<List<HotArticle>> getHotArticles(int categoryId) async {
    final dtos = await _api.fetchHotArticles(categoryId);
    return dtos.map((d) => d.toEntity()).toList();
  }

  void dispose() => _api.dispose();
}
