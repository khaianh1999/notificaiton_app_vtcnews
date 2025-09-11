// repositories/article_repository.dart
import '../models/article_detail_dto.dart';
import '../models/article_detail.dart';
import '../models/article_detail_dto.dart';
import '../services/article_api_service.dart';

class ArticleRepository {
  final ArticleApiService _api;
  ArticleRepository({ArticleApiService? apiService})
    : _api = apiService ?? ArticleApiService();

  Future<ArticleDetail> getArticle(int id) async {
    final dto = await _api.fetchArticleDetail(id); // trả về DTO
    return dto.toEntity(); // map -> Entity
  }

  void dispose() => _api.dispose();
}
