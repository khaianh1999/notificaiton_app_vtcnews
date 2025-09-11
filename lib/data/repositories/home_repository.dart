// data/repositories/home_repository.dart
import '../models/home_zone.dart';
import '../services/home_api_service.dart';

class HomeRepository {
  final _api = HomeApiService();
  List<HomeZone>? _cache;

  Future<List<HomeZone>> getHomeZones({bool forceRefresh = false}) async {
    if (_cache == null || forceRefresh) {
      _cache = await _api.fetchHomeZones();
    }
    // Giữ 5 zone đầu có listNews != rỗng
    return _cache!.where((z) => z.news.isNotEmpty).take(25).toList();
  }
}
