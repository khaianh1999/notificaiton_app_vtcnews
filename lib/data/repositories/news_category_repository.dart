import '../services/news_service.dart';

class NewsRepository {
  final _svc = NewsService();

  Future<List<Map<String, dynamic>>> getNewsHot(int cateId) =>
      _svc.fetchNewsHot(cateId);

  Future<List<Map<String, dynamic>>> getSuggestion(int cateId, int page) =>
      _svc.fetchSuggestion(cateId, page);
}
