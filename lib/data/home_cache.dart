import 'package:notification_vtcnews/data/models/home_zone.dart';
import 'package:notification_vtcnews/data/models/news.dart';
import 'package:notification_vtcnews/data/models/tab_model.dart';

class HomeCache {
  static List<HomeZone> zones = [];
  static List<News> topNews = [];
  static List<TabModel> tabs = [];

  // Reset cache
  static void reset() {
    zones = [];
    topNews = [];
    tabs = [];
  }
}
