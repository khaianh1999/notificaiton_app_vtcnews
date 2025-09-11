import 'package:notification_vtcnews/data/models/news.dart';
import 'package:notification_vtcnews/data/services/news_api_service.dart';

class NewsRepository {
  final _api = NewsApiService();
  List<News>? _cacheTop; // cache đơn giản

  Future<List<News>> getTopNews({bool forceRefresh = false}) async {
    if (_cacheTop == null || forceRefresh) {
      _cacheTop = await _api.fetchTopNews();
    }
    return _cacheTop!;
  }
}
