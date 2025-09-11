import '../models/short_video.dart';
import '../services/short_video_api_service.dart';

class ShortVideoRepository {
  final _api = ShortVideoApiService();
  int _currentPage = 1;
  bool _hasMore = true;
  bool _busy = false;

  final List<ShortVideo> _cache = [];

  /// Trả về list mới để UI .addAll()
  Future<List<ShortVideo>> loadMore() async {
    if (!_hasMore || _busy) return [];

    _busy = true;
    try {
      final data = await _api.fetchPage(_currentPage);
      if (data.isEmpty) {
        _hasMore = false;
      } else {
        _currentPage++;
        _cache.addAll(data);
      }
      return data;
    } finally {
      _busy = false;
    }
  }

  /// Option: reset repository (khi pull‑to‑refresh)
  void reset() {
    _currentPage = 1;
    _hasMore = true;
    _cache.clear();
  }
}
